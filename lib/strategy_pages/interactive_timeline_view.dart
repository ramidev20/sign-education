import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';

class TimeLineMapView extends StatefulWidget {
  final Map<String, dynamic> mindMapJson;
  final UserModel user;
  const TimeLineMapView({
    super.key,
    required this.mindMapJson,
    required this.user,
  });

  @override
  State<TimeLineMapView> createState() => _TimeLineMapViewState();
}

class _TimeLineMapViewState extends State<TimeLineMapView> {
  bool _isGenerating = true;
  File? _pdfFile;
  String? _error;
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _generatePdfFromCanvas();
  }

  void _generatePdfFromCanvas() {
    final jsonStr = jsonEncode(widget.mindMapJson);
    final html = _htmlTemplate.replaceFirst('{{MINDMAP_JSON}}', jsonStr);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (msg) async {
          _handleImageExport(msg.message);
        },
      )
      ..addJavaScriptChannel(
        'ErrorChannel',
        onMessageReceived: (msg) {
          setState(() {
            _error = 'Export error: ${msg.message}';
            _isGenerating = false;
          });
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _triggerPdfGeneration();
          },
        ),
      )
      ..loadHtmlString(html);
  }

  void _triggerPdfGeneration() {
    _controller.runJavaScript('''
      setTimeout(() => {
        try {
          createTimeline();
          setTimeout(() => exportAsImage(), 500);
        } catch (error) {
          ErrorChannel.postMessage(error.toString());
        }
      }, 500);
    ''');
  }

  Future<void> _handleImageExport(String imgBase64) async {
    try {
      final imageBytes = base64Decode(imgBase64.split(',').last);
      final pdfFile = await _generatePdf(imageBytes);

      setState(() {
        _pdfFile = pdfFile;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to export PDF: $e';
        _isGenerating = false;
      });
    }
  }

  Future<File> _generatePdf(Uint8List imageBytes) async {
    final pdf = pw.Document();

    // Use A4 landscape format for horizontal view
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            width: double.infinity,
            height: double.infinity,
            child: pw.Center(
              child: pw.Image(
                pw.MemoryImage(imageBytes),
                fit: pw.BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName = _getPdfFileName();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  String _getPdfFileName() {
    final subjectName = widget.mindMapJson['content'] ?? 'Timeline';
    final sanitizedName = subjectName.toString().replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );
    return '$sanitizedName.pdf';
  }

  void _navigateToNextScreen() {}

  void _retryGeneration() {
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    _triggerPdfGeneration();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generating Timeline PDF'),
        actions: [
          if (_isGenerating)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isGenerating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Generating PDF from Timeline...',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'This may take a few seconds',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _retryGeneration,
              child: const Text('Retry PDF Generation'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _pdfFile != null
                ? SfPdfViewer.file(
                    _pdfFile!,
                    canShowScrollHead: true,
                    canShowScrollStatus: true,
                    pageLayoutMode: PdfPageLayoutMode.single,
                    scrollDirection: PdfScrollDirection.horizontal,
                  )
                : const Center(child: Text('PDF not available')),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _navigateToNextScreen,
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const String _htmlTemplate = r'''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
    <meta charset="UTF-8">
    <title>Timeline Export</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            background: white;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            direction: rtl;
            overflow: hidden;
            width: 100vw;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        #main-container {
            position: absolute;
            width: 2000px;
            height: 800px;
            left: -1000px;
            top: -400px;
            background: white;
        }

        .timeline-title {
            position: absolute;
            top: 30px;
            right: 50%;
            transform: translateX(50%);
            background: linear-gradient(135deg, #2563eb, #1d4ed8);
            color: white;
            padding: 15px 30px;
            border-radius: 10px;
            font-size: 22px;
            font-weight: bold;
            text-align: center;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
            z-index: 100;
            min-width: 250px;
            white-space: nowrap;
        }

        .timeline-line {
            position: absolute;
            top: 50%;
            left: 100px;
            right: 100px;
            height: 4px;
            background: linear-gradient(90deg, #3b82f6, #8b5cf6, #ec4899);
            transform: translateY(-50%);
            border-radius: 3px;
            z-index: 1;
        }

        .event-node {
            position: absolute;
            transform: translate(-50%, -50%);
            padding: 10px 14px;
            border-radius: 8px;
            text-align: center;
            min-width: 130px;
            max-width: 160px;
            border: 2px solid;
            z-index: 10;
            word-wrap: break-word;
            line-height: 1.3;
            font-size: 13px;
            box-shadow: 0 3px 10px rgba(0, 0, 0, 0.15);
        }

        .event-node.phase {
            background: linear-gradient(135deg, #7c3aed, #6d28d9);
            color: white;
            border-color: #5b21b6;
            font-weight: 600;
        }

        .event-node.detail {
            background: linear-gradient(135deg, #059669, #047857);
            color: white;
            border-color: #065f46;
        }

        .event-node.event {
            background: linear-gradient(135deg, #d97706, #b45309);
            color: white;
            border-color: #92400e;
        }

        .node-date {
            display: block;
            font-size: 11px;
            opacity: 0.95;
            border-top: 1px solid rgba(255, 255, 255, 0.3);
            padding-top: 4px;
            margin-top: 4px;
            font-weight: 500;
        }

        .timeline-connector {
            position: absolute;
            background: #64748b;
            height: 2px;
            transform-origin: left center;
            z-index: 5;
            opacity: 0.6;
        }

        .timeline-marker {
            position: absolute;
            top: 50%;
            transform: translate(-50%, -50%);
            width: 10px;
            height: 10px;
            background: #3b82f6;
            border: 2px solid white;
            border-radius: 50%;
            z-index: 2;
            box-shadow: 0 0 4px rgba(0, 0, 0, 0.3);
        }
    </style>
</head>
<body>
    <div id="main-container">
        <div class="timeline-title" id="main-title">التاريخ الإسلامي</div>
        <div class="timeline-line"></div>
        <div id="events-container"></div>
        <div id="markers-container"></div>
        <div id="connectors-container"></div>
    </div>

    <script>
        const timelineData = {{MINDMAP_JSON}};

        function createTimeline() {
            const container = document.getElementById('main-container');
            const title = document.getElementById('main-title');
            const eventsContainer = document.getElementById('events-container');
            const markersContainer = document.getElementById('markers-container');
            const connectorsContainer = document.getElementById('connectors-container');

            // Clear containers
            eventsContainer.innerHTML = '';
            markersContainer.innerHTML = '';
            connectorsContainer.innerHTML = '';

            if (!timelineData) return;

            // Set title
            title.textContent = timelineData.content || 'الخط الزمني';

            // Extract all events with dates
            const allEvents = extractAllEvents(timelineData);
            
            if (allEvents.length === 0) return;

            // Sort events by date
            allEvents.sort((a, b) => parseDate(a.date) - parseDate(b.date));

            // Calculate dynamic bounds based on content
            const bounds = calculateTimelineBounds(allEvents);
            
            // Position timeline line
            const timelineLine = document.querySelector('.timeline-line');
            timelineLine.style.left = bounds.startX + 'px';
            timelineLine.style.right = (2000 - bounds.endX) + 'px';

            // Position title
            title.style.top = (bounds.centerY - bounds.height/2 + 40) + 'px';

            // Position events along timeline
            allEvents.forEach((event, index) => {
                const x = bounds.startX + (index * bounds.spacing);
                
                // Alternate between top and bottom
                const isTop = index % 2 === 0;
                const yOffset = isTop ? -70 : 70;
                const y = bounds.centerY + yOffset;

                // Create event node
                createEventNode(event, x, y, eventsContainer);

                // Create timeline marker
                createTimelineMarker(x, bounds.centerY, markersContainer);

                // Create connector
                createConnector(x, bounds.centerY, x, y, connectorsContainer);
            });
        }

        function calculateTimelineBounds(events) {
            const MIN_SPACING = 150;
            const PADDING = 150;
            
            const totalWidthNeeded = events.length * MIN_SPACING;
            const availableWidth = 1800; // 2000 - 200 padding
            
            const spacing = Math.max(MIN_SPACING, availableWidth / Math.max(events.length - 1, 1));
            const totalWidth = events.length > 1 ? (events.length - 1) * spacing : 400;
            
            const startX = (2000 - totalWidth) / 2;
            const endX = startX + totalWidth;
            const centerY = 400; // Middle of 800px height
            
            return {
                startX: startX,
                endX: endX,
                centerY: centerY,
                spacing: spacing,
                width: totalWidth,
                height: 300
            };
        }

        function extractAllEvents(node, events = []) {
            // Skip the main root node, only include events with dates
            if (node.date && node.id !== 'root') {
                events.push(node);
            }
            
            // Recursively process child nodes
            if (node.nodes && node.nodes.length > 0) {
                node.nodes.forEach(child => extractAllEvents(child, events));
            }
            
            return events;
        }

        function parseDate(dateString) {
            if (!dateString) return 0;
            
            // Try to parse as Date object
            const date = new Date(dateString);
            if (!isNaN(date.getTime())) {
                return date.getTime();
            }
            
            // Fallback: extract numbers and create timestamp
            const numbers = dateString.match(/\d+/g);
            if (numbers && numbers.length >= 3) {
                const year = parseInt(numbers[0]);
                const month = parseInt(numbers[1]) - 1;
                const day = parseInt(numbers[2]);
                return new Date(year, month, day).getTime();
            }
            
            // Handle year-only dates
            if (numbers && numbers.length === 1) {
                const year = parseInt(numbers[0]);
                return new Date(year, 0, 1).getTime();
            }
            
            return 0;
        }

        function formatDate(dateString) {
            try {
                const date = new Date(dateString);
                if (isNaN(date.getTime())) {
                    const numbers = dateString.match(/\d+/g);
                    if (numbers && numbers.length >= 3) {
                        return `${numbers[0]}/${numbers[1]}/${numbers[2]}`;
                    }
                    if (numbers && numbers.length === 1) {
                        return `${numbers[0]}`;
                    }
                    return dateString;
                }
                const year = date.getFullYear();
                const month = date.getMonth() + 1;
                const day = date.getDate();
                
                if (month === 1 && day === 1) {
                    return `${year}`;
                }
                
                return `${year}/${month}/${day}`;
            } catch {
                return dateString;
            }
        }

        function createEventNode(eventData, x, y, container) {
            const node = document.createElement('div');
            node.className = `event-node ${eventData.type || 'event'}`;
            node.style.left = x + 'px';
            node.style.top = y + 'px';
            
            node.innerHTML = `
                <div>${eventData.content || 'حدث'}</div>
                <span class="node-date">${formatDate(eventData.date)}</span>
            `;
            
            container.appendChild(node);
        }

        function createTimelineMarker(x, y, container) {
            const marker = document.createElement('div');
            marker.className = 'timeline-marker';
            marker.style.left = x + 'px';
            marker.style.top = y + 'px';
            container.appendChild(marker);
        }

        function createConnector(x1, y1, x2, y2, container) {
            const connector = document.createElement('div');
            connector.className = 'timeline-connector';
            
            const length = Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
            const angle = (Math.atan2(y2 - y1, x2 - x1) * 180) / Math.PI;
            
            connector.style.width = length + 'px';
            connector.style.left = x1 + 'px';
            connector.style.top = y1 + 'px';
            connector.style.transform = `rotate(${angle}deg)`;
            
            container.appendChild(connector);
        }

        // Export function with dynamic bounds like mind map
        async function exportAsImage() {
            try {
                // Wait for layout to complete
                await new Promise(resolve => setTimeout(resolve, 300));
                
                // Get all visible elements
                const events = document.querySelectorAll('.event-node');
                const markers = document.querySelectorAll('.timeline-marker');
                const connectors = document.querySelectorAll('.timeline-connector');
                const title = document.getElementById('main-title');
                const timelineLine = document.querySelector('.timeline-line');
                
                // Calculate bounds of all content
                let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
                
                // Include title
                const titleRect = title.getBoundingClientRect();
                minX = Math.min(minX, titleRect.left);
                maxX = Math.max(maxX, titleRect.right);
                minY = Math.min(minY, titleRect.top);
                maxY = Math.max(maxY, titleRect.bottom);
                
                // Include timeline line
                const lineRect = timelineLine.getBoundingClientRect();
                minX = Math.min(minX, lineRect.left);
                maxX = Math.max(maxX, lineRect.right);
                minY = Math.min(minY, lineRect.top);
                maxY = Math.max(maxY, lineRect.bottom);
                
                // Include all events and markers
                events.forEach(event => {
                    const rect = event.getBoundingClientRect();
                    minX = Math.min(minX, rect.left);
                    maxX = Math.max(maxX, rect.right);
                    minY = Math.min(minY, rect.top);
                    maxY = Math.max(maxY, rect.bottom);
                });
                
                markers.forEach(marker => {
                    const rect = marker.getBoundingClientRect();
                    minX = Math.min(minX, rect.left);
                    maxX = Math.max(maxX, rect.right);
                    minY = Math.min(minY, rect.top);
                    maxY = Math.max(maxY, rect.bottom);
                });
                
                // Add padding
                const padding = 40;
                const width = Math.max(600, (maxX - minX) + padding * 2);
                const height = Math.max(400, (maxY - minY) + padding * 2);
                
                // Create temporary export container
                const exportContainer = document.createElement('div');
                exportContainer.style.position = 'fixed';
                exportContainer.style.top = '0';
                exportContainer.style.left = '0';
                exportContainer.style.width = width + 'px';
                exportContainer.style.height = height + 'px';
                exportContainer.style.background = 'white';
                exportContainer.style.zIndex = '10000';
                exportContainer.style.overflow = 'hidden';
                
                // Clone and position all elements
                const cloneTitle = title.cloneNode(true);
                cloneTitle.style.position = 'absolute';
                cloneTitle.style.top = (titleRect.top - minY + padding) + 'px';
                cloneTitle.style.left = (titleRect.left - minX + padding) + 'px';
                exportContainer.appendChild(cloneTitle);
                
                const cloneLine = timelineLine.cloneNode(true);
                cloneLine.style.position = 'absolute';
                cloneLine.style.top = (lineRect.top - minY + padding) + 'px';
                cloneLine.style.left = (lineRect.left - minX + padding) + 'px';
                cloneLine.style.right = 'auto';
                cloneLine.style.width = (lineRect.width) + 'px';
                exportContainer.appendChild(cloneLine);
                
                events.forEach((event, index) => {
                    const clone = event.cloneNode(true);
                    const rect = event.getBoundingClientRect();
                    clone.style.position = 'absolute';
                    clone.style.top = (rect.top - minY + padding) + 'px';
                    clone.style.left = (rect.left - minX + padding) + 'px';
                    exportContainer.appendChild(clone);
                });
                
                markers.forEach(marker => {
                    const clone = marker.cloneNode(true);
                    const rect = marker.getBoundingClientRect();
                    clone.style.position = 'absolute';
                    clone.style.top = (rect.top - minY + padding) + 'px';
                    clone.style.left = (rect.left - minX + padding) + 'px';
                    exportContainer.appendChild(clone);
                });
                
                connectors.forEach(connector => {
                    const clone = connector.cloneNode(true);
                    const rect = connector.getBoundingClientRect();
                    clone.style.position = 'absolute';
                    clone.style.top = (rect.top - minY + padding) + 'px';
                    clone.style.left = (rect.left - minX + padding) + 'px';
                    exportContainer.appendChild(clone);
                });
                
                document.body.appendChild(exportContainer);
                
                await new Promise(r => setTimeout(r, 100));

                const canvas = await html2canvas(exportContainer, {
                    backgroundColor: '#ffffff',
                    scale: 2,
                    useCORS: true,
                    logging: false,
                    width: width,
                    height: height
                });

                const imgData = canvas.toDataURL('image/png');
                
                document.body.removeChild(exportContainer);
                
                FlutterChannel.postMessage(imgData);
                
            } catch (error) {
                ErrorChannel.postMessage('Export error: ' + error.toString());
            }
        }

        // Initialize timeline when page loads
        window.addEventListener('load', createTimeline);
    </script>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"></script>
</body>
</html>
''';
