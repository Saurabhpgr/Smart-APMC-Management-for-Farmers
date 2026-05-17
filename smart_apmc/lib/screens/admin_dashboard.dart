import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AuthProvider>(context);
    final user = provider.appUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.blueGrey,
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
            Text('Welcome, ${user?.name ?? 'Admin'}!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildDashboardCard(context, 'User Approvals', Icons.verified_user, Colors.indigo, () {
              context.push('/admin/approvals');
            }),
            _buildDashboardCard(context, 'Manage Slots', Icons.event_available, Colors.teal, () {
              context.push('/admin/slots');
            }),
            _buildDashboardCard(context, 'Market Prices Entry', Icons.price_change, Colors.green, () {
              context.push('/admin/prices');
            }),
            _buildDashboardCard(context, 'Monitor Auctions', Icons.gavel, Colors.indigo, () {
              context.push('/admin/monitor_auctions');
            }),
            _buildDashboardCard(context, 'Verify Payments', Icons.fact_check, Colors.brown, () {
              context.push('/admin/payments');
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
