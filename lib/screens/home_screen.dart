import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/supabase_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int totalProducts = 0;
  int totalStock = 0;
  double totalRevenue = 0.0;
  List<double> weeklySales = List.filled(7, 0.0);
  DateTime startOfWeek = DateTime.now();
  List<dynamic> lowStockProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final products = await SupabaseService.getProducts();
      final soldUnits = await SupabaseService.getSoldUnits();
      
      int stockCount = 0;
      List<dynamic> lowStock = [];
      for (var p in products) {
        int inStock = p['in_stock_count'] as int? ?? 0;
        stockCount += inStock;
        if (inStock < 5) {
          lowStock.add(p);
        }
      }
      
      double rev = 0;
      List<double> wSales = List.filled(7, 0.0);
      final now = DateTime.now();
      
      // Calculate start of the week (Sunday)
      final offsetToSunday = now.weekday == 7 ? 0 : now.weekday;
      startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: offsetToSunday));

      for (var unit in soldUnits) {
        final price = (unit['products']['price'] as num?)?.toDouble() ?? 0.0;
        rev += price;
        
        if (unit['sold_at'] != null) {
          final soldDate = DateTime.parse(unit['sold_at']).toLocal(); // Convert to local IST time
          final difference = DateTime(soldDate.year, soldDate.month, soldDate.day).difference(startOfWeek).inDays;
          if (difference >= 0 && difference < 7) {
            wSales[difference] += price;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          totalProducts = products.length;
          totalStock = stockCount;
          lowStockProducts = lowStock;
          totalRevenue = rev;
          weeklySales = wSales;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to MR Mobile 👋',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Here is your business overview.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Image.asset('assets/logo.png', height: 80, fit: BoxFit.contain),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Revenue',
                  value: '₹${totalRevenue.toStringAsFixed(0)}',
                  icon: Icons.currency_rupee,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Stock',
                  value: totalStock.toString(),
                  icon: Icons.inventory_2,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Revenue This Week', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: weeklySales.reduce((curr, next) => curr > next ? curr : next) * 1.2 + 10, // add padding
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final date = startOfWeek.add(Duration(days: value.toInt()));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(DateFormat('E').format(date), style: const TextStyle(fontSize: 12)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: weeklySales[index],
                        color: Colors.deepPurple,
                        width: 22,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: weeklySales.reduce((curr, next) => curr > next ? curr : next) * 1.2 + 10,
                          color: Colors.grey[100],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (lowStockProducts.isNotEmpty) ...[
            const Text('Low Stock Alerts ⚠️', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 16),
            ...lowStockProducts.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Only ${p['in_stock_count']} left in stock!', style: TextStyle(color: Colors.red[700])),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
