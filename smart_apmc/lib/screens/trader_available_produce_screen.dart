import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/db_service.dart';
import '../models/produce_model.dart';
import '../providers/auth_provider.dart';

class TraderAvailableProduceScreen extends StatefulWidget {
  const TraderAvailableProduceScreen({Key? key}) : super(key: key);

  @override
  State<TraderAvailableProduceScreen> createState() => _TraderAvailableProduceScreenState();
}

class _TraderAvailableProduceScreenState extends State<TraderAvailableProduceScreen> {
  final DBService _dbService = DBService();
  String _searchQuery = '';
  String _selectedGradeFilter = 'All';

  void _showBidDialog(ProduceModel produce) {
    final _formKey = GlobalKey<FormState>();
    final _bidController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Place Bid: ${produce.cropName}'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quantity: ${produce.quantity} Quintal (${produce.grade} Grade)'),
                Text('Expected: ₹${produce.expectedPrice}'),
                const SizedBox(height: 8),
                Text('Current Highest Bid: ₹${produce.currentHighestBid}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bidController,
                  decoration: const InputDecoration(labelText: 'Your Bid Amount (₹)'),
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

                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  bool success = await _dbService.placeBid(produce.id, traderId, bidAmount);

                  // Pop loading
                  Navigator.pop(context);
                  // Pop form
                  Navigator.pop(context);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Produce'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search crop (e.g. Onion)',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGradeFilter,
                      items: ['All', 'A', 'B', 'Premium', 'Standard'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value == 'All' ? 'All Grades' : 'Grade $value'),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedGradeFilter = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _dbService.getAvailableProduce(), // Fetches status == 'available' OR 'in_auction' (Wait, the method only fetches 'available'. Let's fetch both or just available? Bidding implies it stays visible while in auction. I'll modify the stream if needed, but for now we only fetch 'available' which turns to 'in_auction' upon first bid. Let's fix that locally. Wait, the DB service only fetches 'available'. So once bid, it disappears. I will update the query in db_service to not filter by status here and filter locally.)
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                var docs = snapshot.data?.docs.toList() ?? [];
                
                // Filter locally
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final cropName = (data['cropName'] as String? ?? '').toLowerCase();
                  final grade = data['grade'] as String? ?? '';
                  final status = data['status'] as String? ?? '';

                  if (status == 'sold') return false; // Hide sold items
                  
                  if (_searchQuery.isNotEmpty && !cropName.contains(_searchQuery)) return false;
                  if (_selectedGradeFilter != 'All' && grade != _selectedGradeFilter) return false;
                  
                  return true;
                }).toList();

                if (docs.isEmpty) return const Center(child: Text('No produce matches your criteria.'));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final produce = ProduceModel.fromMap(data, docs[index].id);

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                    const Icon(Icons.local_florist, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Text(produce.cropName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text(produce.market, style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
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
                                    const Text('Quantity', style: TextStyle(color: Colors.grey)),
                                    Text('${produce.quantity} Quintal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Grade', style: TextStyle(color: Colors.grey)),
                                    Text(produce.grade, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Expected Price', style: TextStyle(color: Colors.grey)),
                                    Text('₹${produce.expectedPrice}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (produce.currentHighestBid > 0)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Current Highest Bid', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      Text('₹${produce.currentHighestBid}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                                    ],
                                  )
                                else
                                  const Text('No bids yet. Be the first!', style: TextStyle(color: Colors.orange, fontStyle: FontStyle.italic)),
                                ElevatedButton.icon(
                                  onPressed: () => _showBidDialog(produce),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                                  icon: const Icon(Icons.gavel, color: Colors.white, size: 18),
                                  label: const Text('Place Bid', style: TextStyle(color: Colors.white)),
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
          ),
        ],
      ),
    );
  }
}
