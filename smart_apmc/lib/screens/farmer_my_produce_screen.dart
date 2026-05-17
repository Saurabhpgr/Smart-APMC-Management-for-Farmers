import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/db_service.dart';
import '../models/produce_model.dart';
import '../providers/auth_provider.dart';

class FarmerMyProduceScreen extends StatefulWidget {
  const FarmerMyProduceScreen({Key? key}) : super(key: key);

  @override
  State<FarmerMyProduceScreen> createState() => _FarmerMyProduceScreenState();
}

class _FarmerMyProduceScreenState extends State<FarmerMyProduceScreen> {
  final DBService _dbService = DBService();

  void _showUploadDialog() {
    final _formKey = GlobalKey<FormState>();
    final _cropController = TextEditingController();
    final _qtyController = TextEditingController();
    final _expectedPriceController = TextEditingController();
    String _selectedGrade = 'A';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Upload Produce'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _cropController,
                        decoration: const InputDecoration(labelText: 'Crop Name (e.g., Onion)'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: _qtyController,
                        decoration: const InputDecoration(labelText: 'Quantity (Quintal)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedGrade,
                        decoration: const InputDecoration(labelText: 'Grade / Quality'),
                        items: ['A', 'B', 'Premium', 'Standard'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedGrade = newValue!;
                          });
                        },
                      ),
                      TextFormField(
                        controller: _expectedPriceController,
                        decoration: const InputDecoration(labelText: 'Expected Price (₹/Quintal)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
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
                      final farmerId = Provider.of<AuthProvider>(context, listen: false).appUser!.uid;

                      final produceData = {
                        'farmerId': farmerId,
                        'cropName': _cropController.text.trim(),
                        'quantity': double.parse(_qtyController.text.trim()),
                        'grade': _selectedGrade,
                        'expectedPrice': double.parse(_expectedPriceController.text.trim()),
                        'status': 'available',
                        'market': 'Nashik APMC', // Could be dynamic
                        'createdAt': FieldValue.serverTimestamp(),
                        'currentHighestBid': 0.0,
                        'highestBidderId': '',
                      };

                      await _dbService.addProduce(produceData);
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produce uploaded to market!')));
                      }
                    }
                  },
                  child: const Text('Upload'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final farmerId = Provider.of<AuthProvider>(context, listen: false).appUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Produce Inventory'),
        backgroundColor: Colors.blue.shade700,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadDialog,
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Produce', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getFarmerProduce(farmerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          var docs = snapshot.data?.docs.toList() ?? [];
          if (docs.isEmpty) return const Center(child: Text('You have not uploaded any produce yet.'));

          // Sort docs locally to avoid Firebase index error
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final timeA = dataA['createdAt'] as Timestamp?;
            final timeB = dataB['createdAt'] as Timestamp?;
            if (timeA == null || timeB == null) return 0;
            return timeB.compareTo(timeA); // Descending
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final produce = ProduceModel.fromMap(data, docs[index].id);

              Color statusColor = Colors.green;
              if (produce.status == 'in_auction') statusColor = Colors.orange;
              if (produce.status == 'sold') statusColor = Colors.red;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${produce.cropName} (${produce.grade} Grade)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text(produce.status.toUpperCase().replaceAll('_', ' '), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Quantity: ${produce.quantity} Quintal'),
                      Text('Expected: ₹${produce.expectedPrice}'),
                      const Divider(),
                      if (produce.currentHighestBid > 0)
                        Row(
                          children: [
                            const Icon(Icons.gavel, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            Text('Current Highest Bid: ₹${produce.currentHighestBid}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          ],
                        )
                      else
                        const Text('No bids yet.', style: TextStyle(color: Colors.grey)),
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
