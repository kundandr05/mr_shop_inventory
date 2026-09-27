import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintLabelsScreen extends StatelessWidget {
  final List<dynamic> units;
  final Map<String, dynamic>? product;

  const PrintLabelsScreen({super.key, required this.units, this.product});

  Future<pw.Document> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);

    // Thermal Label Printer Size: 50x25mm as requested by user picture
    final stickerFormat = const PdfPageFormat(50 * PdfPageFormat.mm, 25 * PdfPageFormat.mm, marginAll: 1 * PdfPageFormat.mm);

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
                  if (product != null) ...[
                    pw.Text(
                      '${product!['name']}',
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                      maxLines: 1,
                    ),
                    pw.Text(
                      'MRP Rs. ${product!['price']} (Incl. taxes)',
                      style: const pw.TextStyle(fontSize: 6),
                    ),
                    pw.SizedBox(height: 2),
                  ],
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: unit['qr_code'],
                    width: 40 * PdfPageFormat.mm,
                    height: 10 * PdfPageFormat.mm,
                    drawText: false,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    unit['qr_code'],
                    style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
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
