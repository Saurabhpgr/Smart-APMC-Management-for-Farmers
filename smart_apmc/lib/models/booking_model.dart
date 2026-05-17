import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String farmerId;
  final String slotId;
  final String crop;
  final double quantity;
  final String vehicleNumber;
  final String status; // 'confirmed', 'cancelled'
  final DateTime bookedAt;

  BookingModel({
    required this.id,
    required this.farmerId,
    required this.slotId,
    required this.crop,
    required this.quantity,
    required this.vehicleNumber,
    required this.status,
    required this.bookedAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> data, String id) {
    return BookingModel(
      id: id,
      farmerId: data['farmerId'] ?? '',
      slotId: data['slotId'] ?? '',
      crop: data['crop'] ?? '',
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      vehicleNumber: data['vehicleNumber'] ?? '',
      status: data['status'] ?? 'confirmed',
      bookedAt: data['bookedAt'] != null ? (data['bookedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'slotId': slotId,
      'crop': crop,
      'quantity': quantity,
      'vehicleNumber': vehicleNumber,
      'status': status,
      'bookedAt': bookedAt,
    };
  }
}
