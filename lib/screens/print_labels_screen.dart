import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintLabelsScreen extends StatelessWidget {
  final List<dynamic> units;

  const PrintLabelsScreen({super.key, required this.units});

  Future<pw.Document> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);

    // Thermal Label Printer Size: 50x30mm
    final stickerFormat = const PdfPageFormat(50 * PdfPageFormat.mm, 30 * PdfPageFormat.mm, marginAll: 2 * PdfPageFormat.mm);

    for (var unit in units) {
      pdf.addPage(
        pw.Page(
          pageFormat: stickerFormat,
          build: (context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: unit['qr_code'],
                    width: 45 * PdfPageFormat.mm,
                    height: 15 * PdfPageFormat.mm,
                    drawText: false,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    unit['qr_code'],
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('Print Barcode Labels')),
      body: PdfPreview(
        initialPageFormat: const PdfPageFormat(50 * PdfPageFormat.mm, 30 * PdfPageFormat.mm),
        build: (format) async {
          final doc = await _generatePdf(format);
          return doc.save();
        },
      ),
    );
  }
}
