class BookingModel {
  final String id;
  final String equipmentId;
  final String renterId;
  final String ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalRentalFee;
  final String status;
  final bool pickupVerified;
  final bool returnVerified;
  final String? createdAtUtc;

  const BookingModel({
    required this.id,
    required this.equipmentId,
    required this.renterId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.totalRentalFee,
    required this.status,
    this.pickupVerified = false,
    this.returnVerified = false,
    this.createdAtUtc,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      equipmentId: json['equipmentId'] ?? '',
      renterId: json['renterId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now().add(const Duration(days: 3)),
      totalRentalFee: (json['totalRentalFee'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Requested',
      pickupVerified: json['pickupVerified'] ?? false,
      returnVerified: json['returnVerified'] ?? false,
      createdAtUtc: json['createdAtUtc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      'renterId': renterId,
      'ownerId': ownerId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalRentalFee': totalRentalFee,
      'status': status,
      'pickupVerified': pickupVerified,
      'returnVerified': returnVerified,
    };
  }
}
