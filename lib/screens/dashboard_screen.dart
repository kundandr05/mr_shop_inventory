import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../services/supabase_service.dart';
import 'print_labels_screen.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.getProducts();
      setState(() {
        _products = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _searchQuery = '';

  List<dynamic> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products.where((p) {
      final name = p['name'].toString().toLowerCase();
      final brand = (p['brand']?.toString() ?? '').toLowerCase();
      final code = (p['product_code']?.toString() ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || brand.contains(q) || code.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Search stock...',
            border: InputBorder.none,
            icon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: ListView.builder(
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  final inStock = product['in_stock_count'] ?? 0;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: product['image_url'] != null && product['image_url'].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product['image_url'], 
                              width: 50, 
                              height: 50, 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Image load error: $error');
                                return Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.broken_image, color: Colors.red[400]),
                                );
                              },
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.image, color: Colors.grey[400]),
                          ),
                    title: Text(product['name']),
                    subtitle: Text('${product['product_code']} | ${product['brand'] ?? 'No Brand'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('In Stock', style: TextStyle(fontSize: 12)),
                            Text(
                              '$inStock',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: inStock < 5 ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddProductDialog(context, product: product);
                            } else if (value == 'delete') {
                              _deleteProduct(product['product_id']);
                            } else if (value == 'reprint') {
                              _reprintBarcodes(product['product_id']);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'reprint', child: Text('Stock Barcodes')),
                            const PopupMenuItem(value: 'edit', child: Text('Edit Product')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete Product', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _reprintBarcodes(String productId) async {
    setState(() => _isLoading = true);
    try {
      final units = await SupabaseService.getInStockUnits(productId);
      if (units.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active stock for this product.')));
        }
        return;
      }
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PrintLabelsScreen(units: units)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading barcodes: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: const Text('Are you sure you want to delete this product? You cannot delete products that have existing stock.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseService.deleteProduct(id);
      _loadProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot delete: Product might have stock attached.')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddProductDialog(BuildContext context, {Map<String, dynamic>? product}) {
    final isEdit = product != null;
    final codeCtrl = TextEditingController(text: isEdit ? product['product_code'] : '');
    final nameCtrl = TextEditingController(text: isEdit ? product['name'] : '');
    final brandCtrl = TextEditingController(text: isEdit ? product['brand'] : '');
    final priceCtrl = TextEditingController(text: isEdit ? product['price']?.toString() : '');
    
    Uint8List? selectedImageBytes;
    String? currentImageUrl = isEdit ? product['image_url'] : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Product' : 'Add New Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image Picker Section
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery, 
                          imageQuality: 60,
                          maxWidth: 600,
                          maxHeight: 600,
                        );
                        if (pickedFile != null) {
                          final bytes = await pickedFile.readAsBytes();
                          setDialogState(() {
                            selectedImageBytes = bytes;
                            currentImageUrl = null;
                          });
                        }
                      },
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: selectedImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(selectedImageBytes!, fit: BoxFit.cover),
                              )
                            : (currentImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(currentImageUrl!, fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, color: Colors.grey[600]),
                                      const SizedBox(height: 4),
                                      Text('Add Photo', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    ],
                                  )),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Product Code (e.g. HP-01)')),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name')),
                    TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand')),
                    TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (codeCtrl.text.isEmpty || nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
                      return;
                    }
                    
                    final parentContext = context;
                    Navigator.pop(context);
                    
                    setState(() => _isLoading = true);
                    try {
                      String? finalImageUrl = currentImageUrl;
                      
                      if (selectedImageBytes != null) {
                        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
                        finalImageUrl = await SupabaseService.uploadProductImage(fileName, selectedImageBytes!);
                      }

                      final data = {
                        'product_code': codeCtrl.text,
                        'name': nameCtrl.text,
                        'brand': brandCtrl.text,
                        'price': double.tryParse(priceCtrl.text) ?? 0.0,
                        if (finalImageUrl != null) 'image_url': finalImageUrl,
                      };
                      
                      if (isEdit) {
                        await SupabaseService.updateProduct(product['product_id'], data);
                      } else {
                        await SupabaseService.createProduct(data);
                      }
                      
                      _loadProducts();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(content: Text('Error: $e')));
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
