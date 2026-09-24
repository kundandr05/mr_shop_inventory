import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SupabaseService {
  static final _supabase = Supabase.instance.client;

  // 1. Get products and stock (using the view we created)
  static Future<List<dynamic>> getProducts() async {
    final response = await _supabase.from('product_stock').select().timeout(const Duration(seconds: 8));
    return response;
  }

  // 2. Create Product
  static Future<dynamic> createProduct(Map<String, dynamic> productData) async {
    final response = await _supabase.from('products').insert(productData).select().timeout(const Duration(seconds: 8));
    return response.first;
  }

  // Update Product
  static Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _supabase.from('products').update(data).eq('id', id).timeout(const Duration(seconds: 8));
  }

  // Delete Product
  static Future<void> deleteProduct(String id) async {
    await _supabase.from('products').delete().eq('id', id).timeout(const Duration(seconds: 8));
  }

  // 3. Generate batch units
  static Future<List<dynamic>> generateUnits(String productId, int quantity, String? dateStr) async {
    final DateTime rDate = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    final String formattedDate = DateFormat('yyMMdd').format(rDate);

    // Get the product code
    final productResp = await _supabase.from('products').select('product_code').eq('id', productId).single();
    final String pCode = productResp['product_code'];

    final String prefix = '$pCode-$formattedDate-';

    // Find highest sequence for this product and date using a like query
    final lastUnitResp = await _supabase
        .from('units')
        .select('qr_code')
        .like('qr_code', '$prefix%')
        .order('qr_code', ascending: false)
        .limit(1);

    int startSeq = 1;
    if (lastUnitResp.isNotEmpty) {
      final String lastQr = lastUnitResp.first['qr_code'];
      final parts = lastQr.split('-');
      final lastSeq = int.tryParse(parts.last);
      if (lastSeq != null) {
        startSeq = lastSeq + 1;
      }
    }

    // Prepare units to insert
    final List<Map<String, dynamic>> unitsToInsert = [];
    for (int i = 0; i < quantity; i++) {
      final String seqStr = (startSeq + i).toString().padLeft(3, '0');
      unitsToInsert.push({
        'qr_code': '$prefix$seqStr',
        'product_id': productId,
        'status': 'in_stock',
        'received_date': DateFormat('yyyy-MM-dd').format(rDate),
      });
    }

    final response = await _supabase.from('units').insert(unitsToInsert).select();
    return response;
  }

  // 4. Sell a product (Scan QR)
  static Future<dynamic> sellUnit(String qrCode) async {
    // Check if unit exists and its status
    final unitCheck = await _supabase.from('units').select().eq('qr_code', qrCode).maybeSingle();
    
    if (unitCheck == null) {
      throw Exception('Unit not found');
    }

    if (unitCheck['status'] == 'sold') {
      throw Exception('Already sold on ${unitCheck['sold_at']}');
    }

    // Update to sold
    final response = await _supabase
        .from('units')
        .update({
          'status': 'sold',
          'sold_at': DateTime.now().toIso8601String()
        })
        .eq('qr_code', qrCode)
        .select()
        .single();
        
    return {'message': 'Marked as sold', 'unit': response};
  }

  // 5. Get Sold Units (For History & Graphs)
  static Future<List<dynamic>> getSoldUnits() async {
    final response = await _supabase
        .from('units')
        .select('*, products!inner(name, product_code, price)')
        .eq('status', 'sold')
        .order('sold_at', ascending: false)
        .timeout(const Duration(seconds: 8));
    return response;
  }
}

extension on List {
  void push(dynamic item) {
    add(item);
  }
}
