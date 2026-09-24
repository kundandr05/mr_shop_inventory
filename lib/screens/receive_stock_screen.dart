import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'print_labels_screen.dart';

class ReceiveStockScreen extends StatefulWidget {
  const ReceiveStockScreen({super.key});

  @override
  State<ReceiveStockScreen> createState() => _ReceiveStockScreenState();
}

class _ReceiveStockScreenState extends State<ReceiveStockScreen> {
  List<dynamic> _products = [];
  String? _selectedProductId;
  final _quantityController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await SupabaseService.getProducts();
      setState(() {
        _products = data;
        if (_products.isNotEmpty) {
          _selectedProductId = _products.first['product_id'];
        }
      });
    } catch (e) {
      // Handle error quietly or show snackbar
    }
  }

  Future<void> _generateStock() async {
    if (_selectedProductId == null || _quantityController.text.isEmpty) return;
    
    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) return;

    setState(() => _isLoading = true);
    try {
      final units = await SupabaseService.generateUnits(_selectedProductId!, quantity, null);
      
      if (mounted) {
        // Navigate to Print Labels screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrintLabelsScreen(units: units),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating units: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive Stock')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedProductId,
              decoration: const InputDecoration(labelText: 'Select Product'),
              items: _products.map((p) {
                return DropdownMenuItem<String>(
                  value: p['product_id'],
                  child: Text('${p['name']} (${p['product_code']})'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedProductId = val);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity Received'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateStock,
              child: _isLoading 
                  ? const CircularProgressIndicator() 
                  : const Text('Generate Barcodes'),
            ),
          ],
        ),
      ),
    );
  }
}
