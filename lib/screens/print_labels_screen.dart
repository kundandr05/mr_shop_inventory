import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintLabelsScreen extends StatefulWidget {
  final List<dynamic> units;
  final Map<String, dynamic>? product;

  const PrintLabelsScreen({super.key, required this.units, this.product});

  @override
  State<PrintLabelsScreen> createState() => _PrintLabelsScreenState();
}

class _PrintLabelsScreenState extends State<PrintLabelsScreen> {
  double _selectedWidth = 80.0;
  double _selectedHeight = 50.0;
  String _selectedPreset = '80x50';

  final List<Map<String, dynamic>> _presets = [
    {'id': '80x50', 'label': '80 x 50 mm (80mm Hoin / Large)', 'w': 80.0, 'h': 50.0},
    {'id': '80x40', 'label': '80 x 40 mm (80mm Medium)', 'w': 80.0, 'h': 40.0},
    {'id': '80x30', 'label': '80 x 30 mm (80mm Compact)', 'w': 80.0, 'h': 30.0},
    {'id': '50x25', 'label': '50 x 25 mm (2" Standard Sticker)', 'w': 50.0, 'h': 25.0},
    {'id': '50x30', 'label': '50 x 30 mm (2" Medium Sticker)', 'w': 50.0, 'h': 30.0},
    {'id': '40x30', 'label': '40 x 30 mm (Mini Sticker)', 'w': 40.0, 'h': 30.0},
    {'id': 'custom', 'label': 'Custom Size (Enter mm)', 'w': 80.0, 'h': 50.0},
  ];

  final TextEditingController _customWidthController = TextEditingController(text: '80');
  final TextEditingController _customHeightController = TextEditingController(text: '50');

  @override
  void dispose() {
    _customWidthController.dispose();
    _customHeightController.dispose();
    super.dispose();
  }

  Future<pw.Document> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);

    final stickerFormat = PdfPageFormat(
      _selectedWidth * PdfPageFormat.mm,
      _selectedHeight * PdfPageFormat.mm,
      marginAll: 1.5 * PdfPageFormat.mm,
    );

    final double barcodeWidth = (_selectedWidth * 0.72).clamp(26.0, 65.0) * PdfPageFormat.mm;
    final double barcodeHeight = (_selectedHeight * 0.28).clamp(6.5, 16.0) * PdfPageFormat.mm;
    final double nameFontSize = (_selectedHeight * 0.20).clamp(6.5, 11.5);
    final double mrpFontSize = (_selectedHeight * 0.16).clamp(5.5, 9.5);
    final double codeFontSize = (_selectedHeight * 0.16).clamp(5.5, 9.0);
    final bool showStoreName = _selectedHeight >= 38;

    for (var unit in widget.units) {
      pdf.addPage(
        pw.Page(
          pageFormat: stickerFormat,
          build: (context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (showStoreName) ...[
                    pw.Text(
                      'MR MOBILE ACCESSORIES',
                      style: pw.TextStyle(fontSize: (nameFontSize * 0.75).clamp(5.5, 8.5), fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 1),
                  ],
                  if (widget.product != null) ...[
                    pw.Text(
                      '${widget.product!['name']}',
                      style: pw.TextStyle(fontSize: nameFontSize, fontWeight: pw.FontWeight.bold),
                      maxLines: 1,
                    ),
                    pw.Text(
                      'MRP Rs. ${widget.product!['price']} (Incl. taxes)',
                      style: pw.TextStyle(fontSize: mrpFontSize),
                    ),
                    pw.SizedBox(height: 1.5),
                  ],
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: unit['qr_code'],
                    width: barcodeWidth,
                    height: barcodeHeight,
                    drawText: false,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    unit['qr_code'],
                    style: pw.TextStyle(fontSize: codeFontSize, fontWeight: pw.FontWeight.bold),
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
      appBar: AppBar(
        title: const Text('Print Barcode Labels'),
      ),
      body: Column(
        children: [
          // Label Size Chooser Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.aspect_ratio, color: Color(0xFFD4AF37), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Label Size:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPreset,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            isExpanded: true,
                            items: _presets.map((preset) {
                              return DropdownMenuItem<String>(
                                value: preset['id'] as String,
                                child: Text(preset['label'] as String),
                              );
                            }).toList(),
                            onChanged: (newId) {
                              if (newId == null) return;
                              setState(() {
                                _selectedPreset = newId;
                                final chosen = _presets.firstWhere((p) => p['id'] == newId);
                                if (newId != 'custom') {
                                  _selectedWidth = chosen['w'] as double;
                                  _selectedHeight = chosen['h'] as double;
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedPreset == 'custom') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customWidthController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Width (mm)',
                            labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) {
                            final w = double.tryParse(val);
                            if (w != null && w >= 20 && w <= 100) {
                              setState(() => _selectedWidth = w);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _customHeightController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Height (mm)',
                            labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) {
                            final h = double.tryParse(val);
                            if (h != null && h >= 15 && h <= 150) {
                              setState(() => _selectedHeight = h);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Live Size Dimension Indicator Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Screen Preview Size: ${_selectedWidth.toInt()}mm × ${_selectedHeight.toInt()}mm',
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Text(
                    'Ratio ${(_selectedWidth / _selectedHeight).toStringAsFixed(1)}:1',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // PDF Preview with dynamic on-screen width scaling
          Expanded(
            child: PdfPreview(
              key: ValueKey('preview_${_selectedWidth}_${_selectedHeight}'),
              shouldRepaint: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
              maxPageWidth: (_selectedWidth * 4.2).clamp(180.0, 480.0),
              pageFormats: {
                '${_selectedWidth.toInt()}x${_selectedHeight.toInt()}mm': PdfPageFormat(
                  _selectedWidth * PdfPageFormat.mm,
                  _selectedHeight * PdfPageFormat.mm,
                  marginAll: 1.5 * PdfPageFormat.mm,
                ),
              },
              initialPageFormat: PdfPageFormat(
                _selectedWidth * PdfPageFormat.mm,
                _selectedHeight * PdfPageFormat.mm,
                marginAll: 1.5 * PdfPageFormat.mm,
              ),
              build: (format) async {
                final doc = await _generatePdf(format);
                return doc.save();
              },
            ),
          ),
        ],
      ),
    );
  }
}
