import 'package:cloud_firestore/cloud_firestore.dart';

class ProduceModel {
  final String id;
  final String farmerId;
  final String cropName;
  final double quantity; // Quintals
  final String grade; // e.g. 'A', 'B', 'Premium'
  final double expectedPrice;
  final String status; // 'available', 'in_auction', 'sold'
  final String market;
  final DateTime createdAt;
  final double currentHighestBid;
  final String highestBidderId;
  final DateTime? auctionEndTime;
  final List<String> participants;
  final String paymentStatus;

  ProduceModel({
    required this.id,
    required this.farmerId,
    required this.cropName,
    required this.quantity,
    required this.grade,
    required this.expectedPrice,
    required this.status,
    required this.market,
    required this.createdAt,
    required this.currentHighestBid,
    required this.highestBidderId,
    this.auctionEndTime,
    this.participants = const [],
    this.paymentStatus = 'none',
  });

  factory ProduceModel.fromMap(Map<String, dynamic> data, String id) {
    return ProduceModel(
      id: id,
      farmerId: data['farmerId'] ?? '',
      cropName: data['cropName'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      grade: data['grade'] ?? 'Standard',
      expectedPrice: (data['expectedPrice'] ?? 0).toDouble(),
      status: data['status'] ?? 'available',
      market: data['market'] ?? 'Nashik APMC',
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      currentHighestBid: (data['currentHighestBid'] ?? 0).toDouble(),
      highestBidderId: data['highestBidderId'] ?? '',
      auctionEndTime: data['auctionEndTime'] != null ? (data['auctionEndTime'] as Timestamp).toDate() : null,
      participants: List<String>.from(data['participants'] ?? []),
      paymentStatus: data['paymentStatus'] ?? 'none',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'cropName': cropName,
      'quantity': quantity,
      'grade': grade,
      'expectedPrice': expectedPrice,
      'status': status,
      'market': market,
      'createdAt': createdAt,
      'currentHighestBid': currentHighestBid,
      'highestBidderId': highestBidderId,
      'auctionEndTime': auctionEndTime,
      'participants': participants,
      'paymentStatus': paymentStatus,
    };
  }
}
