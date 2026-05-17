import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isLoading) {
      // wait a bit more if still loading
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;

    if (authProvider.firebaseUser == null) {
      context.go('/login');
    } else {
      if (authProvider.appUser == null) {
        context.go('/role_selection');
      } else {
        if (authProvider.appUser!.role != 'admin' && authProvider.appUser!.status != 'approved') {
          // If they open the app and are logged in but not approved, sign them out.
          authProvider.signOut();
          context.go('/login');
          return;
        }

        if (authProvider.appUser!.role == 'farmer') {
          context.go('/farmer_dashboard');
        } else if (authProvider.appUser!.role == 'trader') {
          context.go('/trader_dashboard');
        } else if (authProvider.appUser!.role == 'admin') {
          context.go('/admin_dashboard');
        } else {
          context.go('/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade800,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Smart APMC',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
