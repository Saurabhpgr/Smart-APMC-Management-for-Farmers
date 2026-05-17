import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    final provider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await provider.signInWithEmail(_emailController.text.trim(), _passwordController.text);
    if (success && mounted) {
      if (provider.appUser != null) {
        if (provider.appUser!.role == 'farmer') context.go('/farmer_dashboard');
        else if (provider.appUser!.role == 'trader') context.go('/trader_dashboard');
        else if (provider.appUser!.role == 'admin') context.go('/admin_dashboard');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error)));
    }
  }

  void _googleSignIn() async {
    final provider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await provider.signInWithGoogle();
    if (success && mounted) {
      if (provider.appUser == null) {
        context.go('/role_selection');
      } else {
        if (provider.appUser!.role == 'farmer') context.go('/farmer_dashboard');
        else if (provider.appUser!.role == 'trader') context.go('/trader_dashboard');
        else if (provider.appUser!.role == 'admin') context.go('/admin_dashboard');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AuthProvider>(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.agriculture, size: 80, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        child: const Text('Login'),
                      ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                  onPressed: provider.isLoading ? null : _googleSignIn,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text('Don\'t have an account? Register here.'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
