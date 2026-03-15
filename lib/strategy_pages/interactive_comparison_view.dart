import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:html_to_pdf_plus/html_to_pdf_plus.dart';

class InteractiveComparisonView extends StatefulWidget {
  final Map<String, dynamic> comparisonJson;
  final String username;

  const InteractiveComparisonView({
    super.key,
    required this.comparisonJson,
    required this.username,
  });

  @override
  State<InteractiveComparisonView> createState() =>
      _InteractiveComparisonViewState();
}

class _InteractiveComparisonViewState extends State<InteractiveComparisonView> {
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
      final htmlContent = _generateHtmlContent(widget.comparisonJson);

      final dir = await getApplicationDocumentsDirectory();
      final fileName = _getPdfFileName();

      // ✅ Use html_to_pdf_plus for conversion
      final pdfFile = await HtmlToPdf.convertFromHtmlContent(
        htmlContent: htmlContent,

        configuration: PdfConfiguration(
          targetDirectory: dir.path,
          targetName: fileName,
          printSize: PrintSize.A4,
          printOrientation: PrintOrientation.Portrait,
          // optionally set margins
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
    final tableData = data["comparisonTable"] as List<dynamic>? ?? [];
    if (tableData.isEmpty) {
      return '''
      <html dir="rtl">
      <head><meta charset="utf-8"/></head>
      <body><h2>لا توجد بيانات للمقارنة</h2></body></html>
    ''';
    }

    final Set<String> options = {};
    for (var item in tableData) {
      final key = item.keys.first;
      final values = item[key] as Map<String, dynamic>;
      options.addAll(values.keys);
    }

    final headerRow = StringBuffer('<tr><th>المعيار</th>');
    for (final opt in options) {
      headerRow.write('<th>$opt</th>');
    }
    headerRow.write('</tr>');

    final rows = StringBuffer();
    for (final item in tableData) {
      final criterion = item.keys.first;
      final values = item[criterion] as Map<String, dynamic>;
      rows.write('<tr><td>$criterion</td>');
      for (final opt in options) {
        rows.write('<td>${values[opt] ?? '-'}</td>');
      }
      rows.write('</tr>');
    }

    return '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="utf-8"/>
  <title>${data["title"] ?? "جدول المقارنة"}</title>
  <style>
    body {
      font-family: 'Cairo', sans-serif;
      direction: rtl;
      padding: 40px;
      background: #fff;
      color: #1e293b;
    }
    h1 {
      text-align: center;
      color: #1e3a8a;
      margin-bottom: 32px;
      font-size: 28px;
      border-bottom: 3px solid #3b82f6;
      padding-bottom: 8px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 20px;
      background: #ffffff;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }
    th, td {
      border: 1px solid #cbd5e1;
      padding: 12px;
      text-align: center;
    }
    th {
      background-color: #3b82f6;
      color: white;
    }
    tr:nth-child(even) { background-color: #f8fafc; }
    .footer {
      margin-top: 30px;
      text-align: center;
      color: #64748b;
      font-size: 14px;
    }
  </style>
</head>
<body>
  <h1>${data["title"] ?? "جدول المقارنة"}</h1>
  <table>
    ${headerRow.toString()}
    ${rows.toString()}
  </table>
  <div class="footer">تم إنشاؤه بواسطة Sign Education</div>
</body>
</html>
''';
  }

  String _getPdfFileName() {
    final title = widget.comparisonJson['title'] ?? 'Comparison';
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
        title: const Text('Generating Comparison PDF'),
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
              'Generating PDF from Comparison Table...',
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
