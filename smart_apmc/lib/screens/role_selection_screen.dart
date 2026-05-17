import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _role = 'farmer';

  // Common
  final _phoneController = TextEditingController();

  // Farmer specific
  final _aadhaarController = TextEditingController();
  final _villageController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();

  // Trader specific
  final _businessNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  void _completeSignup() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<AuthProvider>(context, listen: false);
      
      AppUser userData = AppUser(
        uid: '', 
        name: '', // will take from firebaseUser
        email: '', // will take from firebaseUser
        phone: _phoneController.text.trim(),
        role: _role,
        status: 'pending', // assigned later
        createdAt: DateTime.now(),
        aadhaar: _role == 'farmer' ? _aadhaarController.text.trim() : null,
        village: _role == 'farmer' ? _villageController.text.trim() : null,
        district: _role == 'farmer' ? _districtController.text.trim() : null,
        state: _role == 'farmer' ? _stateController.text.trim() : null,
        businessName: _role == 'trader' ? _businessNameController.text.trim() : null,
        licenseNumber: _role == 'trader' ? _licenseNumberController.text.trim() : null,
      );

      await provider.completeGoogleSignIn(userData);
      
      if (mounted) {
        if (_role == 'farmer') context.go('/farmer_dashboard');
        else if (_role == 'trader') context.go('/trader_dashboard');
        else if (_role == 'admin') context.go('/admin_dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Please provide some additional details to finish setting up your account.'),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'I am a'),
                  items: const [
                    DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
                    DropdownMenuItem(value: 'trader', child: Text('Trader / Vendor')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _role = val!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                if (_role == 'farmer') ...[
                  TextFormField(
                    controller: _aadhaarController,
                    decoration: const InputDecoration(labelText: 'Aadhaar Number'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _villageController,
                    decoration: const InputDecoration(labelText: 'Village'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _districtController,
                          decoration: const InputDecoration(labelText: 'District'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(labelText: 'State'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                ],

                if (_role == 'trader') ...[
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(labelText: 'Business Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _licenseNumberController,
                    decoration: const InputDecoration(labelText: 'License Number'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ],

                const SizedBox(height: 32),
                provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _completeSignup,
                        child: const Text('Complete Setup'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
