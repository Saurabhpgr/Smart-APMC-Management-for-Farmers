import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db_service.dart';
import '../models/price_model.dart';

class MarketPricesScreen extends StatelessWidget {
  const MarketPricesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DBService _dbService = DBService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Market Prices'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dbService.getMarketPrices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No prices available.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final price = PriceModel.fromMap(data, docs[index].id);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.eco, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(price.cropName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(price.date, style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Market Yard: ${price.marketName}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPriceColumn('Min', price.minPrice, Colors.red.shade700),
                          _buildPriceColumn('MODAL', price.modalPrice, Colors.green, isModal: true),
                          _buildPriceColumn('Max', price.maxPrice, Colors.blue.shade700),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Arrivals today: ${price.arrivalQuantity} Quintals',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                        ),
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

  Widget _buildPriceColumn(String label, double priceValue, Color color, {bool isModal = false}) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: isModal ? 14 : 12, fontWeight: isModal ? FontWeight.bold : FontWeight.normal)),
        const SizedBox(height: 4),
        Text(
          '₹${priceValue.toStringAsFixed(0)}', 
          style: TextStyle(
            fontSize: isModal ? 24 : 18, 
            fontWeight: FontWeight.bold, 
            color: color
          )
        ),
        if (isModal)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
            child: const Text('Most Trades', style: TextStyle(color: Colors.white, fontSize: 10)),
          )
      ],
    );
  }
}
