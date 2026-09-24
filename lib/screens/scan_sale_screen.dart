import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../services/supabase_service.dart';

class ScanSaleScreen extends StatefulWidget {
  const ScanSaleScreen({super.key});

  @override
  State<ScanSaleScreen> createState() => _ScanSaleScreenState();
}

class _ScanSaleScreenState extends State<ScanSaleScreen> {
  bool _isProcessing = false;
  final TextEditingController _manualController = TextEditingController();

  Future<void> _startBarcodeScan() async {
    if (_isProcessing) return;

    try {
      final result = await BarcodeScanner.scan(
        options: const ScanOptions(
          strings: {
            'cancel': 'Cancel',
            'flash_on': 'Flash on',
            'flash_off': 'Flash off',
          },
          restrictFormat: [],
          useCamera: -1,
        ),
      );

      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        _processSale(result.rawContent);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _processSale(String qrCode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final result = await SupabaseService.sellUnit(qrCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sale confirmed: ${result['unit']['qr_code']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Scan to Sell')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, size: 120, color: Colors.black87),
              const SizedBox(height: 32),
              const Text(
                'Ready to scan items?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap the button below to open the camera scanner.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt, size: 28),
                  label: const Text('Open Scanner', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37), // Gold
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  onPressed: _isProcessing ? null : _startBarcodeScan,
                ),
              ),
              const SizedBox(height: 48),
              const Divider(),
              const SizedBox(height: 24),
              const Text('Or enter manually:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _manualController,
                decoration: InputDecoration(
                  hintText: 'Type code and press enter',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.keyboard),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _processSale(value);
                    _manualController.clear();
                  }
                },
              ),
              if (_isProcessing) ...[
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: Color(0xFFD4AF37)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
