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
                  width: 120,
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: unit['qr_code'],
                        width: 100,
                        height: 100,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        unit['qr_code'],
                        style: const pw.TextStyle(fontSize: 8),
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
      appBar: AppBar(title: const Text('Print QR Labels')),
      body: PdfPreview(
        build: (format) async {
          final doc = await _generatePdf(format);
          return doc.save();
        },
      ),
    );
  }
}
