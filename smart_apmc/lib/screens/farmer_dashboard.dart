import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class FarmerDashboard extends StatelessWidget {
  const FarmerDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AuthProvider>(context);
    final user = provider.appUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await provider.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Welcome, ${user?.name ?? 'Farmer'}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildDashboardCard(context, 'Book Slot', Icons.calendar_month, Colors.blue, () {
              context.push('/farmer/book_slot');
            }),
            _buildDashboardCard(context, 'Market Prices', Icons.trending_up, Colors.green, () {
              context.push('/prices');
            }),
            _buildDashboardCard(context, 'My Produce', Icons.local_florist, Colors.teal, () {
              context.push('/farmer/produce');
            }),
            _buildDashboardCard(context, 'Bidding Results', Icons.gavel, Colors.orange, () {
              context.push('/farmer/results');
            }),
            _buildDashboardCard(context, 'Payments', Icons.payment, Colors.purple, () {
              context.push('/farmer/payments');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.2), radius: 24, child: Icon(icon, color: color, size: 28)),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
