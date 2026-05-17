import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/db_service.dart';
import '../models/produce_model.dart';
import '../providers/auth_provider.dart';

class FarmerPaymentsScreen extends StatefulWidget {
  const FarmerPaymentsScreen({Key? key}) : super(key: key);

  @override
  State<FarmerPaymentsScreen> createState() => _FarmerPaymentsScreenState();
}

class _FarmerPaymentsScreenState extends State<FarmerPaymentsScreen> {
  final DBService _dbService = DBService();

  @override
  Widget build(BuildContext context) {
    final farmerId = Provider.of<AuthProvider>(context, listen: false).appUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & Receipts'),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getFarmerProduce(farmerId), // Gets all produce by this farmer
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          var docs = snapshot.data?.docs.toList() ?? [];
          
          // Filter to show ONLY sold items (which require payment)
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? '';
            return status == 'sold';
          }).toList();

          if (docs.isEmpty) return const Center(child: Text('You have no payment records yet.'));

          // Sort by date descending
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final timeA = dataA['createdAt'] as Timestamp?;
            final timeB = dataB['createdAt'] as Timestamp?;
            if (timeA == null || timeB == null) return 0;
            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final produce = ProduceModel.fromMap(data, docs[index].id);

              Color statusColor = Colors.grey;
              String displayStatus = 'Unknown';
              IconData statusIcon = Icons.info;

              if (produce.paymentStatus == 'completed') {
                statusColor = Colors.green;
                displayStatus = 'Completed';
                statusIcon = Icons.check_circle;
              } else if (produce.paymentStatus == 'verification_pending') {
                statusColor = Colors.orange;
                displayStatus = 'Processing';
                statusIcon = Icons.hourglass_top;
              } else if (produce.paymentStatus == 'failed') {
                statusColor = Colors.red;
                displayStatus = 'Failed (Retrying)';
                statusIcon = Icons.error;
              } else {
                statusColor = Colors.redAccent;
                displayStatus = 'Pending Buyer Payment';
                statusIcon = Icons.pending_actions;
              }

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
                          Chip(
                            avatar: Icon(statusIcon, color: Colors.white, size: 16),
                            label: Text(displayStatus.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                            backgroundColor: statusColor,
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Trader ID (Payer): ${produce.highestBidderId}', style: const TextStyle(color: Colors.grey)),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Amount Settled', style: TextStyle(color: Colors.grey)),
                              Text('₹${produce.currentHighestBid}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.green)),
                            ],
                          ),
                          if (produce.paymentStatus == 'completed')
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading Invoice Receipt...')));
                              },
                              icon: const Icon(Icons.download, color: Colors.purple),
                              label: const Text('Receipt', style: TextStyle(color: Colors.purple)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.purple)),
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
