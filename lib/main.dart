import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/receive_stock_screen.dart';
import 'screens/scan_sale_screen.dart';
import 'screens/sales_history_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://igzksccsskqoqagcfttd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlnemtzY2Nzc2txb3FhZ2NmdHRkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk2Njc0NjMsImV4cCI6MjEwNTI0MzQ2M30.fgTlXGZHETPts3z0hbSJtk_s8wD0onjgN0e6hIKyFV4',
  );
  
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shop Inventory',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFFD4AF37), // Gold
          primary: const Color(0xFFD4AF37),
          secondary: const Color(0xFF2B2B2B), // Elegant Dark Grey
          surface: Colors.white,
          background: const Color(0xFFF8F9FA), // Soft off-white background
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, color: Color(0xFF2B2B2B)),
          headlineMedium: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700, color: Color(0xFF2B2B2B)),
          bodyLarge: TextStyle(fontFamily: 'Roboto', color: Color(0xFF4A4A4A)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2B2B2B),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFF2B2B2B)),
          titleTextStyle: TextStyle(color: Color(0xFF2B2B2B), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFD4AF37).withOpacity(0.15),
          elevation: 10,
          shadowColor: Colors.black.withOpacity(0.05),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) return const IconThemeData(color: Color(0xFFD4AF37), size: 28);
            return const IconThemeData(color: Color(0xFF8E8E93), size: 24);
          }),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) return const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w700, fontSize: 13);
            return const TextStyle(color: Color(0xFF8E8E93), fontWeight: FontWeight.w500, fontSize: 12);
          }),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final session = snapshot.data?.session;
        if (session != null) {
          return const MainLayout();
        }
        return const LoginScreen();
      },
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DashboardScreen(),
    const ReceiveStockScreen(),
    const ScanSaleScreen(),
    const SalesHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MR Mobile Accessories', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          )
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.add_box), label: 'Receive'),
          NavigationDestination(icon: Icon(Icons.barcode_reader), label: 'Sell'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
