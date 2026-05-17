import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db_service.dart';
import '../models/user_model.dart';

class UserApprovalsScreen extends StatefulWidget {
  const UserApprovalsScreen({Key? key}) : super(key: key);

  @override
  State<UserApprovalsScreen> createState() => _UserApprovalsScreenState();
}

class _UserApprovalsScreenState extends State<UserApprovalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DBService _dbService = DBService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Approvals'),
        backgroundColor: Colors.indigo,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Farmers'),
            Tab(text: 'Traders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApprovalList('farmers'),
          _buildApprovalList('traders'),
        ],
      ),
    );
  }

  Widget _buildApprovalList(String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: _dbService.getPendingUsers(collection),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('No pending approvals at this time.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final uid = docs[index].id;
            final user = AppUser.fromMap(data, uid);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Email: ${user.email}'),
                    Text('Phone: ${user.phone}'),
                    if (user.role == 'farmer') ...[
                      Text('Village: ${user.village ?? 'N/A'}'),
                      Text('Aadhaar: ${user.aadhaar ?? 'N/A'}'),
                    ],
                    if (user.role == 'trader') ...[
                      Text('Business: ${user.businessName ?? 'N/A'}'),
                      Text('License: ${user.licenseNumber ?? 'N/A'}'),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _updateStatus(uid, user.role, 'rejected'),
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Reject', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => _updateStatus(uid, user.role, 'approved'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text('Approve', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _updateStatus(String uid, String role, String status) async {
    try {
      await _dbService.updateUserStatus(uid, role, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User $status successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
