import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../services/supabase_service.dart';
import 'sale_success_screen.dart';

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
      final res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SimpleBarcodeScannerPage(),
        ),
      );

      if (res is String && res != '-1' && res.isNotEmpty) {
        _processSale(res);
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SaleSuccessScreen(unit: result['unit']),
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Scan to Sell')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 15)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFFD4AF37)),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Ready to scan items?',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF2B2B2B), letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the button below to open the camera scanner.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt, size: 24),
                    label: const Text('Open Scanner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37), // Gold
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    onPressed: _isProcessing ? null : _startBarcodeScan,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[200])),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR ENTER MANUALLY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                    ),
                    Expanded(child: Divider(color: Colors.grey[200])),
                  ],
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _manualController,
                  decoration: InputDecoration(
                    hintText: 'Type code and press enter',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    prefixIcon: const Icon(Icons.keyboard, color: Colors.grey),
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
      ),
    );
  }
}
