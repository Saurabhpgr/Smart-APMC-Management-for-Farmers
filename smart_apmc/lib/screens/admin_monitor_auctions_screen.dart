import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db_service.dart';
import '../models/produce_model.dart';

class AdminMonitorAuctionsScreen extends StatefulWidget {
  const AdminMonitorAuctionsScreen({Key? key}) : super(key: key);

  @override
  State<AdminMonitorAuctionsScreen> createState() => _AdminMonitorAuctionsScreenState();
}

class _AdminMonitorAuctionsScreenState extends State<AdminMonitorAuctionsScreen> {
  final DBService _dbService = DBService();

  void _showActionDialog(ProduceModel produce, String actionType) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(actionType == 'sold' ? 'Approve & Close Auction' : 'Cancel Auction'),
          content: Text(
            actionType == 'sold'
                ? 'Are you sure you want to officially end this auction? The highest bidder (${produce.highestBidderId}) will win at ₹${produce.currentHighestBid}.'
                : 'Are you sure you want to cancel this auction due to invalid listing or suspicious activity?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: actionType == 'sold' ? Colors.green : Colors.red),
              onPressed: () async {
                await _dbService.adminUpdateAuctionStatus(produce.id, actionType);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auction status changed to $actionType!')));
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
        title: const Text('Monitor Live Auctions'),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getAllLiveAuctions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) return const Center(child: Text('No active auctions at the moment.'));

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
                            child: const Text('LIVE', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Farmer ID: ${produce.farmerId}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Highest Bid', style: TextStyle(color: Colors.grey)),
                              Text('₹${produce.currentHighestBid}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Highest Bidder', style: TextStyle(color: Colors.grey)),
                              Text(produce.highestBidderId.isEmpty ? 'None' : produce.highestBidderId, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CountdownTimerAdminWidget(endTime: produce.auctionEndTime),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showActionDialog(produce, 'cancelled'),
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: produce.currentHighestBid > 0 ? () => _showActionDialog(produce, 'sold') : null,
                              icon: const Icon(Icons.check_circle, color: Colors.white),
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

class CountdownTimerAdminWidget extends StatefulWidget {
  final DateTime? endTime;
  const CountdownTimerAdminWidget({Key? key, required this.endTime}) : super(key: key);

  @override
  State<CountdownTimerAdminWidget> createState() => _CountdownTimerAdminWidgetState();
}

class _CountdownTimerAdminWidgetState extends State<CountdownTimerAdminWidget> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.endTime != null) {
      _updateTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
    }
  }

  void _updateTime() {
    if (widget.endTime == null) return;
    final now = DateTime.now();
    if (now.isAfter(widget.endTime!)) {
      setState(() => _timeLeft = Duration.zero);
      _timer?.cancel();
    } else {
      setState(() => _timeLeft = widget.endTime!.difference(now));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.endTime == null) return const SizedBox.shrink();
    
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_timeLeft.inHours);
    final minutes = twoDigits(_timeLeft.inMinutes.remainder(60));
    final seconds = twoDigits(_timeLeft.inSeconds.remainder(60));

    final isEndingSoon = _timeLeft.inMinutes < 5;

    return Center(
      child: Text(
        'Time Left: $hours:$minutes:$seconds',
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          color: isEndingSoon ? Colors.red : Colors.indigo,
          fontSize: 16,
        ),
      ),
    );
  }
}
