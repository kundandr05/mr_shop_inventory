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
  double totalExpenses = 0.0;
  double netProfit = 0.0;
  List<double> weeklySales = List.filled(7, 0.0);
  Map<String, double> brandSales = {};
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
      final expenses = await SupabaseService.getExpenses();
      
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
      Map<String, double> bSales = {};
      final now = DateTime.now();
      
      // Calculate start of the week (Sunday)
      final offsetToSunday = now.weekday == 7 ? 0 : now.weekday;
      startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: offsetToSunday));

      for (var unit in soldUnits) {
        final price = (unit['products']['price'] as num?)?.toDouble() ?? 0.0;
        final brand = (unit['products']['brand'] as String?)?.trim() ?? 'Unknown';
        
        rev += price;
        bSales[brand] = (bSales[brand] ?? 0.0) + price;
        
        if (unit['sold_at'] != null) {
          final soldDate = DateTime.parse(unit['sold_at']).toLocal(); // Convert to local IST time
          final difference = DateTime(soldDate.year, soldDate.month, soldDate.day).difference(startOfWeek).inDays;
          if (difference >= 0 && difference < 7) {
            wSales[difference] += price;
          }
        }
      }

      double exp = 0;
      for (var expense in expenses) {
        exp += (expense['amount'] as num).toDouble();
      }
      
      if (mounted) {
        setState(() {
          totalProducts = products.length;
          totalStock = stockCount;
          lowStockProducts = lowStock;
          totalRevenue = rev;
          totalExpenses = exp;
          netProfit = rev - exp;
          weeklySales = wSales;
          brandSales = bSales;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddExpenseDialog() {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log New Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (e.g. Rent, Stock)')),
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount (₹)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (descCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await SupabaseService.addExpense(descCtrl.text, double.tryParse(amountCtrl.text) ?? 0.0);
              _loadStats();
            },
            child: const Text('Save Expense'),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SafeArea(
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
                  title: 'Gross Revenue',
                  value: '₹${totalRevenue.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Net Profit',
                  value: '₹${netProfit.toStringAsFixed(0)}',
                  icon: Icons.trending_up,
                  color: netProfit >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showAddExpenseDialog,
                  child: _buildStatCard(
                    title: 'Total Expenses ➕',
                    value: '₹${totalExpenses.toStringAsFixed(0)}',
                    icon: Icons.money_off,
                    color: Colors.orange,
                  ),
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
            height: 320,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 15)),
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
          if (brandSales.isNotEmpty) ...[
            const Text('Top Selling Brands', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 280,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 15)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _buildPieChartSections(),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildPieChartLegend(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
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
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 15)),
        ],
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 15, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.2)),
        ],
      ),
    );
  }

  final List<Color> _brandColors = [
    Colors.blue, Colors.red, Colors.green, Colors.orange, 
    Colors.purple, Colors.teal, Colors.pink, Colors.amber
  ];

  List<PieChartSectionData> _buildPieChartSections() {
    final List<PieChartSectionData> sections = [];
    int i = 0;
    
    brandSales.forEach((brand, revenue) {
      final color = _brandColors[i % _brandColors.length];
      final percentage = (revenue / totalRevenue) * 100;
      
      sections.add(
        PieChartSectionData(
          color: color,
          value: revenue,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        )
      );
      i++;
    });
    return sections;
  }

  List<Widget> _buildPieChartLegend() {
    final List<Widget> legends = [];
    int i = 0;
    brandSales.forEach((brand, revenue) {
      final color = _brandColors[i % _brandColors.length];
      legends.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(brand, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('₹${revenue.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        )
      );
      i++;
    });
    return legends;
  }
}
