import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InteractiveColoredCardsView extends StatefulWidget {
  final Map<String, dynamic> cardsJson;
  final UserModel user;
  const InteractiveColoredCardsView({
    super.key,
    required this.cardsJson,
    required this.user,
  });

  @override
  State<InteractiveColoredCardsView> createState() =>
      _InteractiveColoredCardsViewState();
}

class _InteractiveColoredCardsViewState
    extends State<InteractiveColoredCardsView> {
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
    final jsonStr = jsonEncode(widget.cardsJson);
    final html = _htmlTemplate.replaceFirst('{{CARDS_JSON}}', jsonStr);

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
        NavigationDelegate(onPageFinished: (_) => _triggerPdfGeneration()),
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
      }, 600);
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
    final title = widget.cardsJson['title'] ?? 'ConceptCards';
    final sanitized = title.toString().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return '$sanitized.pdf';
  }

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
        title: const Text('Generating Colored Concept Cards PDF'),
        actions: [
          if (_isGenerating)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2),
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
            SizedBox(height: 16),
            Text('Generating Colored Cards...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _retryGeneration,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _pdfFile != null
        ? SfPdfViewer.file(_pdfFile!)
        : const Center(child: Text('PDF not ready'));
  }
}

const String _htmlTemplate = r'''
<!DOCTYPE html>
<html dir="rtl">
<head>
<meta charset="utf-8"/>
<title>Colored Concept Cards</title>
<style>
  body {
    margin: 0;
    font-family: "Segoe UI", Tahoma, sans-serif;
    background: white;
  }
  #grid {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    padding: 40px;
    gap: 20px;
  }
  .card {
    width: 240px;
    border-radius: 16px;
    padding: 16px;
    color: white;
    box-shadow: 0 4px 10px rgba(0,0,0,0.15);
    text-align: center;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
  }
  .title {
    font-size: 20px;
    font-weight: 700;
    margin-bottom: 8px;
  }
  .type {
    font-size: 14px;
    opacity: 0.85;
    margin-bottom: 12px;
  }
  .content {
    font-size: 16px;
    line-height: 1.4;
  }
</style>
</head>
<body>
<div id="grid"></div>

<script>
  const data = {{CARDS_JSON}}.conceptCards || [];
  const grid = document.getElementById('grid');

  data.forEach(item => {
    const card = document.createElement('div');
    card.className = 'card';
    card.style.backgroundColor = item.color || '#60A5FA';
    card.innerHTML = `
      <div class="title">${item.title}</div>
      <div class="type">${item.type}</div>
      <div class="content">${item.content}</div>
    `;
    grid.appendChild(card);
  });

  async function exportAsImage() {
    const canvas = await html2canvas(document.body, { scale: 2 });
    FlutterChannel.postMessage(canvas.toDataURL('image/png'));
  }

  window.onload = () => exportAsImage();
</script>
<script src="https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js"></script>
</body>
</html>
''';
