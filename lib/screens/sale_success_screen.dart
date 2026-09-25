import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SaleSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> unit;

  const SaleSuccessScreen({super.key, required this.unit});

  @override
  Widget build(BuildContext context) {
    final product = unit['products'];
    final soldAt = unit['sold_at'] != null 
        ? DateFormat('MMM d, y h:mm a').format(DateTime.parse(unit['sold_at']).toLocal())
        : DateFormat('MMM d, y h:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Sale Confirmation'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Force them to use the Done button
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Checkmark or Product Image
                product['image_url'] != null
                    ? Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green, width: 4),
                          image: DecorationImage(
                            image: NetworkImage(product['image_url']),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.green,
                            child: Icon(Icons.check, size: 20, color: Colors.white),
                          ),
                        ),
                      )
                    : const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.green,
                        child: Icon(Icons.check, size: 60, color: Colors.white),
                      ),
                const SizedBox(height: 24),
                const Text(
                  'Sale Successful!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 32),
                
                // The Bill / Receipt Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'RECEIPT',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.grey),
                        ),
                      ),
                      const Divider(height: 32, thickness: 2),
                      _buildReceiptRow('Product', product['name'].toString()),
                      _buildReceiptRow('Brand', product['brand']?.toString() ?? 'N/A'),
                      _buildReceiptRow('Barcode', unit['qr_code'].toString()),
                      if (unit['received_date'] != null)
                        _buildReceiptRow('Entry Date', DateFormat('MMM d, y').format(DateTime.parse(unit['received_date']))),
                      _buildReceiptRow('Sold Date', soldAt),
                      const Divider(height: 32, thickness: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(
                            '₹${product['price']}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Done Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to scanner
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Scan Next Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
