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

class InteractiveHierarchyView extends StatefulWidget {
  final Map<String, dynamic> hierarchyJson;
  final UserModel user;
  const InteractiveHierarchyView({
    super.key,
    required this.hierarchyJson,
    required this.user,
  });

  @override
  State<InteractiveHierarchyView> createState() =>
      _InteractiveHierarchyViewState();
}

class _InteractiveHierarchyViewState extends State<InteractiveHierarchyView> {
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
    final jsonStr = jsonEncode(widget.hierarchyJson);
    final html = _htmlTemplate.replaceFirst('{{HIERARCHY_JSON}}', jsonStr);

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
          exportAsImage();
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final image = pw.MemoryImage(imageBytes);
          return pw.Container(
            margin: const pw.EdgeInsets.all(20),
            child: pw.Center(
              child: pw.FittedBox(
                fit: pw.BoxFit.contain,
                child: pw.Image(image),
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
    final subjectName = widget.hierarchyJson['title'] ?? 'Hierarchy';
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
        title: const Text('Generating Hierarchical Progression PDF'),
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
              'Generating PDF from Hierarchy...',
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
                    scrollDirection: PdfScrollDirection.vertical,
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
<html dir="rtl">
<head>
<meta charset="utf-8"/>
<title>Hierarchy Progression PDF</title>
<style>
  html, body {
    margin: 0;
    height: 100%;
    overflow: hidden;
    background: white;
    font-family: "Segoe UI", Roboto, Arial, sans-serif;
    direction: rtl;
  }
  #container {
    position: relative;
    width: 1600px;
    height: 2000px;
    margin: 50px auto;
  }
  .level-box {
    background: #f1f5f9;
    border-left: 6px solid #3b82f6;
    padding: 16px 24px;
    margin: 16px 0;
    border-radius: 12px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  }
  .level-title {
    font-size: 20px;
    font-weight: 600;
    color: #1e3a8a;
  }
  .level-desc {
    font-size: 16px;
    color: #475569;
    margin-top: 6px;
  }
  .level-num {
    font-weight: bold;
    color: #2563eb;
  }
</style>
</head>
<body>
<div id="container"></div>

<script>
  const data = {{HIERARCHY_JSON}}.hierarchyMap || [];
  const container = document.getElementById('container');

  data.sort((a, b) => (a.level || 0) - (b.level || 0));

  data.forEach(item => {
    const box = document.createElement('div');
    box.className = 'level-box';
    box.innerHTML = `
      <div class="level-title">
        <span class="level-num">Level ${item.level}:</span> ${item.title}
      </div>
      <div class="level-desc">${item.description || ''}</div>
    `;
    container.appendChild(box);
  });

  async function exportAsImage() {
    const canvas = await html2canvas(document.body, {
      backgroundColor: '#ffffff',
      scale: 1.5,
      useCORS: true,
    });
    FlutterChannel.postMessage(canvas.toDataURL('image/png'));
  }

  window.onload = () => exportAsImage();
</script>
<script src="https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js"></script>
</body>
</html>
''';
