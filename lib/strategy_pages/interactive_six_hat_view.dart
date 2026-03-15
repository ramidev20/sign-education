import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sign_education/data/models/user_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class SixHatPage extends StatelessWidget {
  final UserModel user;
  final Map<String, dynamic> jsonInput;

  SixHatPage({super.key, required this.user, required this.jsonInput});

  final Map<String, Color> hatColors = {
    "white_hat": Colors.white,
    "red_hat": Colors.red,
    "black_hat": Colors.black,
    "yellow_hat": Colors.yellow,
    "green_hat": Colors.green,
    "blue_hat": Colors.blue,
  };

  Future<void> _savePdf(BuildContext context) async {
    try {
      final PdfDocument document = PdfDocument();
      final page = document.pages.add();

      double yPosition = 0;

      for (final hatKey in hatColors.keys) {
        final hatText = jsonInput[hatKey] ?? "";
        final color = hatColors[hatKey]!;

        // Convert Flutter Color to PdfColor
        final pdfColor = PdfColor(color.red, color.green, color.blue);

        // Draw hat color box
        page.graphics.drawRectangle(
          bounds: Rect.fromLTWH(0, yPosition, 20, 20),
          brush: PdfSolidBrush(pdfColor),
        );

        // Draw text
        page.graphics.drawString(
          hatText,
          PdfStandardFont(PdfFontFamily.helvetica, 12),
          bounds: Rect.fromLTWH(30, yPosition, 500, 100),
        );

        yPosition += 60;
      }

      final bytes = document.save();
      document.dispose();

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/six_hat.pdf');
      await file.writeAsBytes(bytes as List<int>, flush: true);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تم حفظ PDF في: ${file.path}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء حفظ PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("القبعات الست"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _savePdf(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: hatColors.keys.map((hatKey) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/hats/$hatKey.png',
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      jsonInput[hatKey] ?? "",
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
