import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/supabase_service.dart';

class ScanSaleScreen extends StatefulWidget {
  const ScanSaleScreen({super.key});

  @override
  State<ScanSaleScreen> createState() => _ScanSaleScreenState();
}

class _ScanSaleScreenState extends State<ScanSaleScreen> {
  bool _isProcessing = false;

  void _handleScan(BarcodeCapture capture) async {
    if (_isProcessing) return; // Prevent multiple scans while processing

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrCode = barcodes.first.rawValue;
    if (qrCode == null) return;

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
      // Small delay before allowing another scan
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan to Sell')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleScan,
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.black87,
                  child: const Text(
                    'Point camera at QR code',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                // Fallback for Desktop USB Scanners or Manual Entry
                Container(
                  color: Colors.white.withOpacity(0.9),
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Or click here to use a USB Scanner / Type manually',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.keyboard),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _handleManualScan(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _handleManualScan(String qrCode) async {
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
}
