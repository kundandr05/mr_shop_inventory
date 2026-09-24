import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintLabelsScreen extends StatelessWidget {
  final List<dynamic> units;

  const PrintLabelsScreen({super.key, required this.units});

  Future<pw.Document> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);

    // Creating a grid of QR codes for the units
    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (context) {
          return [
            pw.Wrap(
              spacing: 20,
              runSpacing: 20,
              children: units.map((unit) {
                return pw.Container(
                  width: 160,
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.code128(),
                        data: unit['qr_code'],
                        width: 160,
                        height: 60,
                        drawText: false,
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        unit['qr_code'],
                        style: const pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Print Barcode Labels')),
      body: PdfPreview(
        build: (format) async {
          final doc = await _generatePdf(format);
          return doc.save();
        },
      ),
    );
  }
}
