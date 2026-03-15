import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:html_to_pdf_plus/html_to_pdf_plus.dart';
import 'package:sign_education/data/models/user_model.dart';

class InteractiveTriangleView extends StatefulWidget {
  final Map<String, dynamic> triangleJson;
  final UserModel user;

  const InteractiveTriangleView({
    super.key,
    required this.triangleJson,
    required this.user,
  });

  @override
  State<InteractiveTriangleView> createState() =>
      _InteractiveTriangleViewState();
}

class _InteractiveTriangleViewState extends State<InteractiveTriangleView> {
  bool _isGenerating = true;
  bool _hasGenerated = false;
  File? _pdfFile;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!_hasGenerated) {
      _hasGenerated = true;
      _generatePdfFromHtml();
    }
  }

  Future<void> _generatePdfFromHtml() async {
    try {
      final htmlContent = _generateHtmlContent(widget.triangleJson);

      final dir = await getApplicationDocumentsDirectory();
      final fileName = _getPdfFileName();

      // ✅ Convert HTML to PDF
      final pdfFile = await HtmlToPdf.convertFromHtmlContent(
        htmlContent: htmlContent,
        configuration: PdfConfiguration(
          targetDirectory: dir.path,
          targetName: fileName,
          printSize: PrintSize.A4,
          printOrientation: PrintOrientation.Portrait,
        ),
      );

      if (mounted) {
        setState(() {
          _pdfFile = pdfFile;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to generate PDF: $e';
          _isGenerating = false;
        });
      }
    }
  }

  String _generateHtmlContent(Map<String, dynamic> data) {
    final triangleMap = data['triangleMap'] as List<dynamic>? ?? [];
    final title = data['title'] ?? 'التريـنـغل التعليمي';
    final desc = data['description'] ?? '';

    // Ensure we have 3 corners minimum
    while (triangleMap.length < 3) {
      triangleMap.add({
        "corner": "زاوية",
        "title": "",
        "description": "",
        "examples": [],
        "color": "#3b82f6",
      });
    }

    final top = triangleMap[0];
    final left = triangleMap[1];
    final right = triangleMap[2];

    String buildCorner(Map item) {
      final examples =
          (item['examples'] as List?)
              ?.take(4)
              .map((e) => '<li>$e</li>')
              .join('') ??
          '';
      return '''
      <div class="corner" style="background:${item['color'] ?? '#3b82f6'}">
        <div class="title">${item['title'] ?? item['corner'] ?? ''}</div>
        <div class="desc">${item['description'] ?? ''}</div>
        <ul>$examples</ul>
      </div>
      ''';
    }

    return '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
<meta charset="utf-8"/>
<title>$title</title>
<style>
  body {
    font-family: 'Cairo', sans-serif;
    background: #fff;
    color: #1e293b;
    direction: rtl;
    padding: 40px;
    text-align: center;
  }
  h1 {
    color: #1e3a8a;
    margin-bottom: 16px;
    border-bottom: 3px solid #3b82f6;
    padding-bottom: 8px;
  }
  p.desc {
    font-size: 16px;
    color: #475569;
    margin-bottom: 30px;
  }
  .triangle-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    position: relative;
    width: 600px;
    height: 520px;
    margin: auto;
  }
  .corner {
    position: absolute;
    width: 260px;
    padding: 16px;
    border-radius: 12px;
    color: white;
    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    text-align: right;
  }
  .corner .title {
    font-weight: bold;
    font-size: 18px;
    margin-bottom: 6px;
  }
  .corner ul {
    padding-right: 16px;
  }
  .top { top: 0; left: 50%; transform: translateX(-50%); }
  .left { bottom: 0; left: 0; }
  .right { bottom: 0; right: 0; }
  .footer {
    margin-top: 40px;
    font-size: 14px;
    color: #64748b;
  }
</style>
</head>
<body>
  <h1>$title</h1>
  <p class="desc">$desc</p>

  <div class="triangle-container">
    <div class="corner top">${buildCorner(top)}</div>
    <div class="corner left">${buildCorner(left)}</div>
    <div class="corner right">${buildCorner(right)}</div>
  </div>

  <div class="footer">تم إنشاؤه بواسطة Sign Education</div>
</body>
</html>
''';
  }

  String _getPdfFileName() {
    final title = widget.triangleJson['title'] ?? 'EducationalTriangle';
    final sanitized = title.toString().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return '$sanitized.pdf';
  }

  void _retryGeneration() {
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    _generatePdfFromHtml();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generating Educational Triangle PDF'),
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
              'Generating Educational Triangle PDF...',
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
                ? SfPdfViewer.file(_pdfFile!)
                : const Center(child: Text('PDF not available')),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
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
