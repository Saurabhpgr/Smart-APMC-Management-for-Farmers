import 'package:cloud_firestore/cloud_firestore.dart';

class PriceModel {
  final String id;
  final String cropName;
  final String marketName;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;
  final double arrivalQuantity;
  final String date; // 'YYYY-MM-DD'
  final String updatedBy;
  final DateTime timestamp;

  PriceModel({
    required this.id,
    required this.cropName,
    required this.marketName,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.arrivalQuantity,
    required this.date,
    required this.updatedBy,
    required this.timestamp,
  });

  factory PriceModel.fromMap(Map<String, dynamic> data, String id) {
    return PriceModel(
      id: id,
      cropName: data['cropName'] ?? '',
      marketName: data['marketName'] ?? '',
      minPrice: (data['minPrice'] ?? 0).toDouble(),
      maxPrice: (data['maxPrice'] ?? 0).toDouble(),
      modalPrice: (data['modalPrice'] ?? 0).toDouble(),
      arrivalQuantity: (data['arrivalQuantity'] ?? 0).toDouble(),
      date: data['date'] ?? '',
      updatedBy: data['updatedBy'] ?? '',
      timestamp: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cropName': cropName,
      'marketName': marketName,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'modalPrice': modalPrice,
      'arrivalQuantity': arrivalQuantity,
      'date': date,
      'updatedBy': updatedBy,
      'timestamp': timestamp,
    };
  }
}
