import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/db_service.dart';
import '../models/produce_model.dart';
import '../providers/auth_provider.dart';

class FarmerBiddingResultsScreen extends StatefulWidget {
  const FarmerBiddingResultsScreen({Key? key}) : super(key: key);

  @override
  State<FarmerBiddingResultsScreen> createState() => _FarmerBiddingResultsScreenState();
}

class _FarmerBiddingResultsScreenState extends State<FarmerBiddingResultsScreen> {
  final DBService _dbService = DBService();

  @override
  Widget build(BuildContext context) {
    final farmerId = Provider.of<AuthProvider>(context, listen: false).appUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bidding Results & History'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getFarmerProduce(farmerId), // Gets all produce by this farmer
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          var docs = snapshot.data?.docs.toList() ?? [];
          if (docs.isEmpty) return const Center(child: Text('No auction history found.'));

          // Sort locally to put active auctions first, then by date
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final statusA = dataA['status'] as String? ?? '';
            final statusB = dataB['status'] as String? ?? '';
            
            // Priority: in_auction > sold > available > cancelled
            int priority(String s) {
              if (s == 'in_auction') return 3;
              if (s == 'sold') return 2;
              if (s == 'available') return 1;
              return 0; // cancelled
            }
            
            int pA = priority(statusA);
            int pB = priority(statusB);
            
            if (pA != pB) return pB.compareTo(pA); // Highest priority first
            
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
              IconData statusIcon = Icons.info;
              
              if (produce.status == 'in_auction') {
                statusColor = Colors.orange;
                statusIcon = Icons.gavel;
              } else if (produce.status == 'sold') {
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
              } else if (produce.status == 'cancelled') {
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
              } else if (produce.status == 'available') {
                statusColor = Colors.blue;
                statusIcon = Icons.store;
              }

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
                ),
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
                            label: Text(produce.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            backgroundColor: statusColor,
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (produce.status == 'sold') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Expected Price', style: TextStyle(color: Colors.grey)),
                                Text('₹${produce.expectedPrice}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const Icon(Icons.arrow_forward, color: Colors.green),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Final Selling Price', style: TextStyle(color: Colors.grey)),
                                Text('₹${produce.currentHighestBid}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.green)),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Winning Trader:', style: TextStyle(color: Colors.grey)),
                            Text(produce.highestBidderId, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Payment Status:', style: TextStyle(color: Colors.grey)),
                            Text('Pending', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                          ],
                        ),
                      ] else if (produce.status == 'in_auction') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Expected Price', style: TextStyle(color: Colors.grey)),
                                Text('₹${produce.expectedPrice}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Current Highest Bid', style: TextStyle(color: Colors.grey)),
                                Text('₹${produce.currentHighestBid}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.orange)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Auction is live! Traders are currently bidding.', style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic)),
                      ] else ...[
                        Text('Expected Price: ₹${produce.expectedPrice}', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        if (produce.status == 'available')
                          const Text('Waiting for the first bid to start the auction.', style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic))
                        else if (produce.status == 'cancelled')
                          const Text('This auction was cancelled by the APMC Admin.', style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
                      ],
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
