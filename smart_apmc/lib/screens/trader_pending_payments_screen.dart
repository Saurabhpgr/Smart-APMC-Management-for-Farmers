import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/db_service.dart';
import '../models/produce_model.dart';
import '../providers/auth_provider.dart';

class TraderPendingPaymentsScreen extends StatefulWidget {
  const TraderPendingPaymentsScreen({Key? key}) : super(key: key);

  @override
  State<TraderPendingPaymentsScreen> createState() => _TraderPendingPaymentsScreenState();
}

class _TraderPendingPaymentsScreenState extends State<TraderPendingPaymentsScreen> {
  final DBService _dbService = DBService();

  void _showPaymentDialog(ProduceModel produce) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Complete Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pay for: ${produce.cropName} (${produce.quantity} Qtl)', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Payment Method: UPI / Net Banking (Simulated)'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade50, border: Border.all(color: Colors.green)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹${produce.currentHighestBid}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                  ],
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.payment, color: Colors.white),
              label: const Text('Pay Now', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                // Simulate payment processing delay
                await Future.delayed(const Duration(seconds: 2));
                await _dbService.processTraderPayment(produce.id);

                if (mounted) {
                  Navigator.pop(context); // pop loading
                  Navigator.pop(context); // pop dialog
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment submitted! Pending Admin Verification.')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final traderId = Provider.of<AuthProvider>(context, listen: false).appUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Payments'),
        backgroundColor: Colors.red.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getTraderPendingPayments(traderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          var docs = snapshot.data?.docs.toList() ?? [];
          
          // Filter to show only pending, processing, or failed (not completed locally)
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['paymentStatus'] as String? ?? 'none';
            return status != 'completed'; // Completed payments disappear from "Pending" screen
          }).toList();

          if (docs.isEmpty) return const Center(child: Text('You have no pending payments.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final produce = ProduceModel.fromMap(data, docs[index].id);

              bool isProcessing = produce.paymentStatus == 'verification_pending';
              bool isFailed = produce.paymentStatus == 'failed';

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
                          if (isProcessing)
                            const Chip(label: Text('Processing', style: TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: Colors.orange)
                          else if (isFailed)
                            const Chip(label: Text('Failed', style: TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: Colors.red)
                          else
                            const Chip(label: Text('Pending', style: TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: Colors.redAccent)
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Amount Due', style: TextStyle(color: Colors.grey)),
                              Text('₹${produce.currentHighestBid}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                            ],
                          ),
                          if (isProcessing)
                            const Text('Waiting for Admin\nVerification...', textAlign: TextAlign.right, style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic))
                          else
                            ElevatedButton(
                              onPressed: () => _showPaymentDialog(produce),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: Text(isFailed ? 'Retry Payment' : 'Pay Now', style: const TextStyle(color: Colors.white)),
                            ),
                        ],
                      ),
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
