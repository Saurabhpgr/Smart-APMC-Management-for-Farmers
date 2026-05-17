class SlotModel {
  final String id;
  final String date; // e.g. '2026-05-20'
  final String startTime; // e.g. '09:00'
  final String endTime; // e.g. '10:00'
  final String cropType;
  final int capacity;
  final int bookedCount;
  final String status; // 'open', 'closed', 'full'
  final String marketYard;

  SlotModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.cropType,
    required this.capacity,
    required this.bookedCount,
    required this.status,
    required this.marketYard,
  });

  factory SlotModel.fromMap(Map<String, dynamic> data, String id) {
    return SlotModel(
      id: id,
      date: data['date'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      cropType: data['cropType'] ?? '',
      capacity: data['capacity']?.toInt() ?? 0,
      bookedCount: data['bookedCount']?.toInt() ?? 0,
      status: data['status'] ?? 'open',
      marketYard: data['marketYard'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'cropType': cropType,
      'capacity': capacity,
      'bookedCount': bookedCount,
      'status': status,
      'marketYard': marketYard,
    };
  }
}
