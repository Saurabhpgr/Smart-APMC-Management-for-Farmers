class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // 'farmer', 'trader', 'admin'
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;

  // Role specific fields
  final String? aadhaar;
  final String? village;
  final String? district;
  final String? state;
  final String? businessName;
  final String? licenseNumber;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
    this.aadhaar,
    this.village,
    this.district,
    this.state,
    this.businessName,
    this.licenseNumber,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'farmer',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] != null ? data['createdAt'].toDate() : DateTime.now(),
      aadhaar: data['aadhaar'],
      village: data['village'],
      district: data['district'],
      state: data['state'],
      businessName: data['business_name'],
      licenseNumber: data['license_number'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'createdAt': createdAt,
    };
    if (aadhaar != null) map['aadhaar'] = aadhaar!;
    if (village != null) map['village'] = village!;
    if (district != null) map['district'] = district!;
    if (state != null) map['state'] = state!;
    if (businessName != null) map['business_name'] = businessName!;
    if (licenseNumber != null) map['license_number'] = licenseNumber!;
    return map;
  }
}
