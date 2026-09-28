import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SaleSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> unit;

  const SaleSuccessScreen({super.key, required this.unit});

  @override
  Widget build(BuildContext context) {
    final product = unit['products'];
    final soldAt = unit['sold_at'] != null 
        ? DateFormat('MMM d, y h:mm a').format(DateTime.parse(unit['sold_at']).toLocal())
        : DateFormat('MMM d, y h:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Sale Confirmation'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Force them to use the Done button
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Checkmark or Product Image
                product['image_url'] != null
                    ? Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Color(0xFFD4AF37), width: 4),
                          image: DecorationImage(
                            image: NetworkImage(product['image_url']),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: const CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFFD4AF37),
                            child: Icon(Icons.check, size: 20, color: Colors.white),
                          ),
                        ),
                      )
                    : const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFFD4AF37),
                        child: Icon(Icons.check, size: 60, color: Colors.white),
                      ),
                const SizedBox(height: 24),
                const Text(
                  'Sale Successful!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 32),
                
                // The Bill / Receipt Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'RECEIPT',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF94A3B8)),
                        ),
                      ),
                      const Divider(height: 32, thickness: 2, color: Color(0xFF334155)),
                      _buildReceiptRow('Product', product['name'].toString()),
                      _buildReceiptRow('Brand', product['brand']?.toString() ?? 'N/A'),
                      _buildReceiptRow('Barcode', unit['qr_code'].toString()),
                      if (unit['received_date'] != null)
                        _buildReceiptRow('Entry Date', DateFormat('MMM d, y').format(DateTime.parse(unit['received_date']))),
                      _buildReceiptRow('Sold Date', soldAt),
                      const Divider(height: 32, thickness: 2, color: Color(0xFF334155)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(
                            '₹${product['price']}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFD4AF37)),
                        label: const Text('Print Bill', style: TextStyle(color: Color(0xFFD4AF37))),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFFD4AF37)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _printBill(context, product, soldAt),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to scanner
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Scan Next Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                    child: const Text('Scan Next Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _printBill(BuildContext context, Map<String, dynamic> product, String soldAt) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(child: pw.Text('MR Mobile Accessories', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
                pw.Divider(),
                pw.Text('Date: $soldAt', style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ]
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text('')),
                    pw.Text('Rs. '),
                  ]
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.Text('Rs. ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  ]
                ),
                pw.SizedBox(height: 20),
                pw.Center(child: pw.Text('Thank you for shopping with us!', style: const pw.TextStyle(fontSize: 12))),
                pw.SizedBox(height: 10),
                pw.Center(child: pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: unit['qr_code'],
                  width: 150,
                  height: 50,
                  drawText: true,
                )),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Bill_',
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Color(0xFF94A3B8))),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}



