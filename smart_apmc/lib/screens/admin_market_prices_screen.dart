import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';
import '../models/price_model.dart';
import '../providers/auth_provider.dart';

class AdminMarketPricesScreen extends StatefulWidget {
  const AdminMarketPricesScreen({Key? key}) : super(key: key);

  @override
  State<AdminMarketPricesScreen> createState() => _AdminMarketPricesScreenState();
}

class _AdminMarketPricesScreenState extends State<AdminMarketPricesScreen> {
  final DBService _dbService = DBService();

  void _showPriceDialog({PriceModel? existingPrice}) {
    final isEditing = existingPrice != null;
    
    final _formKey = GlobalKey<FormState>();
    final _cropController = TextEditingController(text: existingPrice?.cropName ?? '');
    final _marketController = TextEditingController(text: existingPrice?.marketName ?? 'Nashik APMC');
    final _minPriceController = TextEditingController(text: existingPrice?.minPrice.toString() ?? '');
    final _maxPriceController = TextEditingController(text: existingPrice?.maxPrice.toString() ?? '');
    final _modalPriceController = TextEditingController(text: existingPrice?.modalPrice.toString() ?? '');
    final _qtyController = TextEditingController(text: existingPrice?.arrivalQuantity.toString() ?? '');
    
    DateTime? _selectedDate = existingPrice != null ? DateFormat('yyyy-MM-dd').parse(existingPrice.date) : DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Market Price' : 'Add Market Price'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Date'),
                        subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate!,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                      ),
                      TextFormField(
                        controller: _cropController,
                        decoration: const InputDecoration(labelText: 'Crop Name (e.g., Onion)'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: _marketController,
                        decoration: const InputDecoration(labelText: 'Market Yard'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minPriceController,
                              decoration: const InputDecoration(labelText: 'Min Price (₹)'),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _maxPriceController,
                              decoration: const InputDecoration(labelText: 'Max Price (₹)'),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: _modalPriceController,
                        decoration: const InputDecoration(labelText: 'Modal Price (₹)'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v!.isEmpty) return 'Required';
                          double? min = double.tryParse(_minPriceController.text);
                          double? max = double.tryParse(_maxPriceController.text);
                          double? modal = double.tryParse(v);
                          if (min != null && max != null && modal != null) {
                            if (max < min) return 'Max must be >= Min';
                            if (modal < min || modal > max) return 'Must be between Min & Max';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _qtyController,
                        decoration: const InputDecoration(labelText: 'Arrival Quantity (Quintal)'),
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
                      final adminId = Provider.of<AuthProvider>(context, listen: false).appUser?.uid ?? 'unknown';

                      final priceData = {
                        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
                        'cropName': _cropController.text.trim(),
                        'marketName': _marketController.text.trim(),
                        'minPrice': double.parse(_minPriceController.text.trim()),
                        'maxPrice': double.parse(_maxPriceController.text.trim()),
                        'modalPrice': double.parse(_modalPriceController.text.trim()),
                        'arrivalQuantity': double.parse(_qtyController.text.trim()),
                        'updatedBy': adminId,
                        'timestamp': FieldValue.serverTimestamp(),
                      };

                      if (isEditing) {
                        await _dbService.updateMarketPrice(existingPrice.id, priceData);
                      } else {
                        await _dbService.createMarketPrice(priceData);
                      }
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEditing ? 'Price updated' : 'Price added')));
                      }
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Add Entry'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _deletePrice(String id) async {
    await _dbService.deleteMarketPrice(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Price entry deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Prices Entry'),
        backgroundColor: Colors.green.shade800,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPriceDialog(),
        backgroundColor: Colors.green.shade800,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getMarketPrices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No market prices recorded yet.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final price = PriceModel.fromMap(data, docs[index].id);

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
                          Text(price.cropName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          Text(price.date, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Market: ${price.marketName}'),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Min Price', style: TextStyle(color: Colors.grey)),
                              Text('₹${price.minPrice}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text('Modal Price', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              Text('₹${price.modalPrice}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Max Price', style: TextStyle(color: Colors.grey)),
                              Text('₹${price.maxPrice}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Arrival Quantity: ${price.arrivalQuantity} Quintals'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showPriceDialog(existingPrice: price),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletePrice(price.id),
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
