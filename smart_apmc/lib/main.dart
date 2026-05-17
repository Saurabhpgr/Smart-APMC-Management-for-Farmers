import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/farmer_dashboard.dart';
import 'screens/trader_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/user_approvals_screen.dart';

import 'screens/admin_manage_slots_screen.dart';
import 'screens/farmer_book_slot_screen.dart';
import 'screens/admin_market_prices_screen.dart';
import 'screens/market_prices_screen.dart';
import 'screens/farmer_my_produce_screen.dart';
import 'screens/trader_available_produce_screen.dart';
import 'screens/trader_active_bids_screen.dart';
import 'screens/admin_monitor_auctions_screen.dart';
import 'screens/farmer_bidding_results_screen.dart';
import 'screens/trader_pending_payments_screen.dart';
import 'screens/admin_verify_payments_screen.dart';
import 'screens/farmer_payments_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GoRouter _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/role_selection',
          builder: (context, state) => const RoleSelectionScreen(),
        ),
        GoRoute(
          path: '/farmer_dashboard',
          builder: (context, state) => const FarmerDashboard(),
        ),
        GoRoute(
          path: '/trader_dashboard',
          builder: (context, state) => const TraderDashboard(),
        ),
        GoRoute(
          path: '/admin_dashboard',
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/admin/approvals',
          builder: (context, state) => const UserApprovalsScreen(),
        ),
        GoRoute(
          path: '/admin/slots',
          builder: (context, state) => const AdminManageSlotsScreen(),
        ),
        GoRoute(
          path: '/farmer/book_slot',
          builder: (context, state) => const FarmerBookSlotScreen(),
        ),
        GoRoute(
          path: '/admin/prices',
          builder: (context, state) => const AdminMarketPricesScreen(),
        ),
        GoRoute(
          path: '/prices',
          builder: (context, state) => const MarketPricesScreen(),
        ),
        GoRoute(
          path: '/farmer/produce',
          builder: (context, state) => const FarmerMyProduceScreen(),
        ),
        GoRoute(
          path: '/trader/produce',
          builder: (context, state) => const TraderAvailableProduceScreen(),
        ),
        GoRoute(
          path: '/trader/bids',
          builder: (context, state) => const TraderActiveBidsScreen(),
        ),
        GoRoute(
          path: '/admin/monitor_auctions',
          builder: (context, state) => const AdminMonitorAuctionsScreen(),
        ),
        GoRoute(
          path: '/farmer/results',
          builder: (context, state) => const FarmerBiddingResultsScreen(),
        ),
        GoRoute(
          path: '/trader/payments',
          builder: (context, state) => const TraderPendingPaymentsScreen(),
        ),
        GoRoute(
          path: '/admin/payments',
          builder: (context, state) => const AdminVerifyPaymentsScreen(),
        ),
        GoRoute(
          path: '/farmer/payments',
          builder: (context, state) => const FarmerPaymentsScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Smart APMC',
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
