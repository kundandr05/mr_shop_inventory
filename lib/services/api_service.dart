import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android emulator testing against localhost,
  // or your computer's IP address (e.g., 192.168.1.X) if testing on a physical device.
  // For production, replace this with your hosted Node.js server URL.
  static const String baseUrl = 'http://localhost:3000/api'; 

  static Future<List<dynamic>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load products');
    }
  }

  static Future<dynamic> createProduct(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(productData),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create product');
    }
  }

  static Future<List<dynamic>> generateUnits(String productId, int quantity, String? dateStr) async {
    final body = {
      'product_id': productId,
      'quantity': quantity,
    };
    if (dateStr != null) {
      body['received_date'] = dateStr;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/units/batch'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to generate units');
    }
  }

  static Future<dynamic> sellUnit(String qrCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/units/sell'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'qr_code': qrCode}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['error'] ?? 'Failed to sell unit');
    }
  }
}
