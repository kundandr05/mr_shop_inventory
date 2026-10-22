import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
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
  final FocusNode _manualFocusNode = FocusNode();
  Timer? _debounceTimer;
  String _lastScanned = '';

  @override
  void initState() {
    super.initState();
    // Global hardware keyboard listener for barcode scanner guns
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _manualFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _manualController.dispose();
    _manualFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        final text = _manualController.text.trim();
        if (text.isNotEmpty) {
          _debounceTimer?.cancel();
          _processSale(text);
          _manualController.clear();
          return true;
        }
      } else if (!_manualFocusNode.hasFocus && event.character != null && event.character!.isNotEmpty) {
        // Automatically refocus textfield when scanner starts typing anywhere
        _manualFocusNode.requestFocus();
        _manualController.text += event.character!;
        _manualController.selection = TextSelection.fromPosition(
          TextPosition(offset: _manualController.text.length),
        );
      }
    }
    return false;
  }

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
        _processSale(res.trim());
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Camera Scanner Error', e.toString());
      }
    }
  }

  Future<void> _processSale(String qrCode) async {
    final cleanCode = qrCode.trim();
    if (cleanCode.isEmpty || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _lastScanned = cleanCode;
    });

    try {
      final result = await SupabaseService.sellUnit(cleanCode);
      if (mounted) {
        _manualController.clear();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SaleSuccessScreen(unit: result['unit']),
          ),
        );
        if (mounted) {
          _manualFocusNode.requestFocus();
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        _showErrorDialog(cleanCode, errorMsg);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showErrorDialog(String code, String reason) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('Scan Unsuccessful', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The scanner read this barcode:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Database Response:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              reason.contains('Unit not found')
                  ? '⚠️ Unit not found in inventory. Make sure this product was received and added to stock in the "Receive" tab first.'
                  : reason,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _manualController.clear();
              _manualFocusNode.requestFocus();
            },
            child: const Text('OK / Try Next', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Navy
      appBar: AppBar(
        title: const Text('Scan to Sell'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
            tooltip: 'Refocus Scanner',
            onPressed: () {
              _manualFocusNode.requestFocus();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanner input active'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _manualFocusNode.requestFocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              children: [
                // Active Scanner Ready Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.radar, color: Color(0xFF10B981), size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hardware Scanner Ready',
                              style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Point barcode gun at the paper and pull trigger. Auto-sells instantly.',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Main Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // Lighter Navy
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.qr_code_scanner, size: 64, color: Color(0xFFD4AF37)),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Point Scanner Gun',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Or use the manual box below if needed',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 32),

                      // Manual / Hardware input field
                      TextField(
                        controller: _manualController,
                        focusNode: _manualFocusNode,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Ready for barcode input...',
                          hintStyle: const TextStyle(color: Color(0xFF64748B)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          prefixIcon: const Icon(Icons.barcode_reader, color: Color(0xFFD4AF37)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFFD4AF37)),
                            onPressed: () {
                              if (_manualController.text.isNotEmpty) {
                                _processSale(_manualController.text.trim());
                              }
                            },
                          ),
                        ),
                        onChanged: (value) {
                          if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                          if (value.trim().isNotEmpty) {
                            _debounceTimer = Timer(const Duration(milliseconds: 600), () {
                              if (_manualController.text.trim().isNotEmpty) {
                                _processSale(_manualController.text.trim());
                              }
                            });
                          }
                        },
                        onSubmitted: (value) {
                          if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                          if (value.trim().isNotEmpty) {
                            _processSale(value.trim());
                          }
                        },
                      ),

                      if (_isProcessing) ...[
                        const SizedBox(height: 24),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Processing sale in database...', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],

                      if (_lastScanned.isNotEmpty && !_isProcessing) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Last scanned: $_lastScanned',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(child: Divider(color: const Color(0xFF334155))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR USE MOBILE CAMERA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1)),
                          ),
                          Expanded(child: Divider(color: const Color(0xFF334155))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt, size: 20, color: Color(0xFFD4AF37)),
                          label: const Text('Open Phone Camera Scanner', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD4AF37)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isProcessing ? null : _startBarcodeScan,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
