import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/db_service.dart';
import '../models/produce_model.dart';
import '../providers/auth_provider.dart';

class TraderActiveBidsScreen extends StatefulWidget {
  const TraderActiveBidsScreen({Key? key}) : super(key: key);

  @override
  State<TraderActiveBidsScreen> createState() => _TraderActiveBidsScreenState();
}

class _TraderActiveBidsScreenState extends State<TraderActiveBidsScreen> {
  final DBService _dbService = DBService();

  void _showBidDialog(ProduceModel produce) {
    final _formKey = GlobalKey<FormState>();
    final _bidController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Place Higher Bid: ${produce.cropName}'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Highest Bid: ₹${produce.currentHighestBid}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bidController,
                  decoration: const InputDecoration(labelText: 'Your New Bid Amount (₹)'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v!.isEmpty) return 'Required';
                    double? bid = double.tryParse(v);
                    if (bid == null) return 'Invalid number';
                    if (bid <= produce.currentHighestBid) return 'Must be higher than current bid';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final traderId = Provider.of<AuthProvider>(context, listen: false).appUser!.uid;
                  final bidAmount = double.parse(_bidController.text.trim());

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  bool success = await _dbService.placeBid(produce.id, traderId, bidAmount);

                  Navigator.pop(context); // Pop loading
                  Navigator.pop(context); // Pop form

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid placed successfully!')));
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to place bid. Someone might have bid higher!')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Confirm Bid'),
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
        title: const Text('Active Bids'),
        backgroundColor: Colors.orange.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getTraderActiveBids(traderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final docs = snapshot.data?.docs ?? [];
          
          // Filter out expired auctions locally (simulate auction close)
          final activeDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final produce = ProduceModel.fromMap(data, doc.id);
            if (produce.auctionEndTime != null && DateTime.now().isAfter(produce.auctionEndTime!)) {
              return false; // Auction ended
            }
            return true;
          }).toList();

          if (activeDocs.isEmpty) {
            return const Center(child: Text('You have no active bids currently.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeDocs.length,
            itemBuilder: (context, index) {
              final data = activeDocs[index].data() as Map<String, dynamic>;
              final produce = ProduceModel.fromMap(data, activeDocs[index].id);

              final isWinning = produce.highestBidderId == traderId;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isWinning ? Colors.green : Colors.red, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.gavel, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text('${produce.cropName} (${produce.quantity} Qtl)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isWinning ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isWinning ? 'WINNING' : 'OUTBID',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Current Highest Bid', style: TextStyle(color: Colors.grey)),
                              Text('₹${produce.currentHighestBid}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: isWinning ? Colors.green : Colors.red)),
                            ],
                          ),
                          if (!isWinning)
                            ElevatedButton.icon(
                              onPressed: () => _showBidDialog(produce),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                              label: const Text('Bid Again', style: TextStyle(color: Colors.white)),
                            ),
                        ],
                      ),
                      const Divider(height: 24),
                      CountdownTimerWidget(endTime: produce.auctionEndTime),
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

class CountdownTimerWidget extends StatefulWidget {
  final DateTime? endTime;
  const CountdownTimerWidget({Key? key, required this.endTime}) : super(key: key);

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.endTime != null) {
      _updateTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateTime();
      });
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
    if (widget.endTime == null) return const Text('No time limit');
    
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_timeLeft.inHours);
    final minutes = twoDigits(_timeLeft.inMinutes.remainder(60));
    final seconds = twoDigits(_timeLeft.inSeconds.remainder(60));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.timer, color: Colors.grey, size: 16),
        const SizedBox(width: 4),
        Text(
          'Time Left: $hours:$minutes:$seconds',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ],
    );
  }
}
