import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<dynamic> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('units')
          .select('*, products(name, price)')
          .eq('status', 'sold')
          .order('sold_at', ascending: false);
          
      setState(() {
        _sales = response;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processReturn(String qrCode) async {
    try {
      await Supabase.instance.client
          .from('units')
          .update({'status': 'in_stock', 'sold_at': null})
          .eq('qr_code', qrCode);
          
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item marked as returned (In Stock)'), backgroundColor: Colors.green));
      _loadSales();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Return Failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _exportHistoryPdf() async {
    final pdf = pw.Document();
    
    final headers = ['Product', 'Barcode', 'Price', 'Sold Date'];
    final data = _sales.map((sale) {
      final product = sale['products'];
      final soldAt = sale['sold_at'] != null 
          ? DateFormat('MMM d, y h:mm a').format(DateTime.parse(sale['sold_at']).toLocal())
          : '-';
      return [
        product['name'].toString(),
        sale['qr_code'].toString(),
        'Rs. ${product['price']}',
        soldAt,
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Sales History Export')),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellPadding: const pw.EdgeInsets.all(5),
          ),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'sales_history.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History & Returns'),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportHistoryPdf, tooltip: 'Export PDF'),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSales),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _sales.length,
              itemBuilder: (context, index) {
                final sale = _sales[index];
                final product = sale['products'];
                final soldAt = sale['sold_at'] != null 
                    ? DateFormat('MMM d, y h:mm a').format(DateTime.parse(sale['sold_at']).toLocal())
                    : 'Unknown Time';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, color: Colors.white),
                    ),
                    title: Text('${product['name']}'),
                    subtitle: Text('Code: ${sale['qr_code']}\nSold: $soldAt'),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('₹${product['price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _processReturn(sale['qr_code']),
                          child: const Text('Process Return', style: TextStyle(color: Colors.red, fontSize: 12, decoration: TextDecoration.underline)),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
