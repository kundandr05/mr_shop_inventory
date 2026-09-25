import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/download_stub.dart' if (dart.library.html) '../utils/web_download.dart';
import 'sale_success_screen.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<dynamic> _allSales = [];
  List<dynamic> _sales = [];
  bool _isLoading = true;
  String _filter = 'All Time';

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  void _applyFilter() {
    final now = DateTime.now();
    setState(() {
      if (_filter == 'All Time') {
        _sales = _allSales;
      } else {
        _sales = _allSales.where((sale) {
          if (sale['sold_at'] == null) return false;
          final soldAt = DateTime.parse(sale['sold_at']).toLocal();
          final diff = DateTime(now.year, now.month, now.day)
              .difference(DateTime(soldAt.year, soldAt.month, soldAt.day))
              .inDays;
              
          if (_filter == 'Today') return diff == 0;
          if (_filter == 'Yesterday') return diff == 1;
          if (_filter == 'Last 7 Days') return diff >= 0 && diff <= 7;
          return true;
        }).toList();
      }
    });
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('units')
          .select('*, products(*)')
          .eq('status', 'sold')
          .order('sold_at', ascending: false);
          
      setState(() {
        _allSales = response;
      });
      _applyFilter();
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

  Future<void> _exportHistoryCsv() async {
    final headers = ['Product', 'Brand', 'Barcode', 'Price', 'Entry Date', 'Sold Date'];
    final rows = _sales.map((sale) {
      final product = sale['products'];
      final soldAt = sale['sold_at'] != null 
          ? DateFormat('MMM d, y h:mm a').format(DateTime.parse(sale['sold_at']).toLocal())
          : '-';
      final entryDate = sale['received_date'] != null
          ? DateFormat('MMM d, y').format(DateTime.parse(sale['received_date']))
          : '-';
      return [
        '"${product['name'].toString().replaceAll('"', '""')}"',
        '"${product['brand']?.toString().replaceAll('"', '""') ?? 'N/A'}"',
        '"${sale['qr_code'].toString().replaceAll('"', '""')}"',
        '"${product['price']}"',
        '"$entryDate"',
        '"$soldAt"',
      ].join(',');
    });

    final csvData = [headers.join(','), ...rows].join('\n');
    
    if (kIsWeb) {
      downloadCsvWeb(csvData, 'sales_history.csv');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download started!')));
      }
    } else {
      final bytes = utf8.encode(csvData);
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'text/csv', name: 'sales_history.csv')],
        text: 'Sales History Export',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History & Returns'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by Date',
            onSelected: (value) {
              _filter = value;
              _applyFilter();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All Time', child: Text('All Time')),
              const PopupMenuItem(value: 'Today', child: Text('Today')),
              const PopupMenuItem(value: 'Yesterday', child: Text('Yesterday')),
              const PopupMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
            ],
          ),
          IconButton(icon: const Icon(Icons.table_chart), onPressed: _exportHistoryCsv, tooltip: 'Export Excel/CSV'),
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
                final entryDate = sale['received_date'] != null
                    ? DateFormat('MMM d, y').format(DateTime.parse(sale['received_date']))
                    : 'Unknown Date';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SaleSuccessScreen(unit: sale),
                        ),
                      );
                    },
                    leading: product['image_url'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(product['image_url'], width: 50, height: 50, fit: BoxFit.cover),
                          )
                        : const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.check, color: Colors.white),
                          ),
                    title: Text('${product['name']}'),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Code: ${sale['qr_code']}'),
                          Text('Entry: $entryDate\nSold: $soldAt', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
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
