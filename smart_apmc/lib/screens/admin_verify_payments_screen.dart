import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db_service.dart';
import '../models/produce_model.dart';

class AdminVerifyPaymentsScreen extends StatefulWidget {
  const AdminVerifyPaymentsScreen({Key? key}) : super(key: key);

  @override
  State<AdminVerifyPaymentsScreen> createState() => _AdminVerifyPaymentsScreenState();
}

class _AdminVerifyPaymentsScreenState extends State<AdminVerifyPaymentsScreen> {
  final DBService _dbService = DBService();

  void _showActionDialog(ProduceModel produce, bool isApproved) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isApproved ? 'Approve Payment' : 'Reject Payment'),
          content: Text(
            isApproved
                ? 'Are you sure you want to approve this payment of ₹${produce.currentHighestBid}? This will officially transfer the funds to the farmer.'
                : 'Are you sure you want to reject this payment? The trader will have to retry the payment.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isApproved ? Colors.green : Colors.red),
              onPressed: () async {
                await _dbService.adminVerifyPayment(produce.id, isApproved);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isApproved ? 'Payment Approved!' : 'Payment Rejected.')));
                }
              },
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Payments'),
        backgroundColor: Colors.brown,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getAdminPendingVerifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No payments pending verification.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final produce = ProduceModel.fromMap(data, docs[index].id);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${produce.cropName} (${produce.quantity} Qtl)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                            child: const Text('ACTION REQUIRED', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('Trader ID (Payer): ${produce.highestBidderId}', style: const TextStyle(color: Colors.grey)),
                      Text('Farmer ID (Payee): ${produce.farmerId}', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount Claimed:', style: TextStyle(fontSize: 16)),
                          Text('₹${produce.currentHighestBid}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showActionDialog(produce, false),
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text('Reject', style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showActionDialog(produce, true),
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text('Approve', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            ),
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
      ),
    );
  }
}
