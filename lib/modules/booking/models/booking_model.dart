/// Unified mobile representation of a RentaTool Booking.
/// Aligns with both [BookingResponseDto] and [ActiveBookingSummaryDto] from the .NET backend.
class BookingModel {
  final String id;
  final String equipmentId;
  final String renterId;
  final String ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final double dailyRate;
  final double totalRentalFee;
  final String status;
  final bool pickupVerified;
  final bool returnVerified;
  final String? cancellationReason;
  final String? createdAtUtc;
  final String? updatedAtUtc;

  const BookingModel({
    required this.id,
    required this.equipmentId,
    required this.renterId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    this.dailyRate = 0.0,
    required this.totalRentalFee,
    required this.status,
    this.pickupVerified = false,
    this.returnVerified = false,
    this.cancellationReason,
    this.createdAtUtc,
    this.updatedAtUtc,
  });

  /// Duration of rental in days (minimum 1 day)
  int get durationInDays {
    final diff = endDate.difference(startDate).inDays;
    return (diff <= 0 ? 1 : diff + 1);
  }

  /// True if current status is Requested (pending confirmation)
  bool get isRequested => status.toLowerCase() == 'requested';

  /// True if booking is confirmed and ready for pickup verification
  bool get isConfirmed => status.toLowerCase() == 'confirmed';

  /// True if equipment is actively in renter possession
  bool get isActive => status.toLowerCase() == 'active';

  /// True if equipment return was verified and rental concluded
  bool get isCompleted => status.toLowerCase() == 'completed';

  /// True if booking was cancelled
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  /// True if booking is in escrow damage dispute
  bool get isDisputed => status.toLowerCase() == 'disputed';

  /// Only confirmed bookings that haven't verified pickup yet can generate pickup tokens
  bool get canGeneratePickupToken => isConfirmed && !pickupVerified;

  /// Only active rentals that haven't verified return yet can generate return tokens
  bool get canGenerateReturnToken => isActive && !returnVerified;

  /// Only Confirmed or Active bookings can be extended per backend business rules
  bool get canExtendSchedule => isConfirmed || isActive;

  /// Damage disputes can be filed during active rental or after return
  bool get canDispute => isActive || isCompleted;

  /// Short display code (e.g. BKG-A1B2C3D4)
  String get displayCode {
    if (id.isEmpty) return 'BKG-UNKNOWN';
    final sub = id.length >= 8 ? id.substring(0, 8) : id;
    return 'BKG-${sub.toUpperCase()}';
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final sDate = DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now();
    final eDate = DateTime.tryParse(json['endDate']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 3));
    final totalFee = (json['totalRentalFee'] as num?)?.toDouble() ?? 0.0;
    
    // If dailyRate is omitted (e.g., from ActiveBookingSummaryDto), compute estimate
    double dRate = (json['dailyRate'] as num?)?.toDouble() ?? 0.0;
    if (dRate <= 0.0) {
      final days = (eDate.difference(sDate).inDays) + 1;
      dRate = days > 0 ? (totalFee / days) : totalFee;
    }

    return BookingModel(
      id: json['id']?.toString() ?? '',
      equipmentId: json['equipmentId']?.toString() ?? '',
      renterId: json['renterId']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      startDate: sDate,
      endDate: eDate,
      dailyRate: dRate,
      totalRentalFee: totalFee,
      status: json['status']?.toString() ?? 'Requested',
      pickupVerified: json['pickupVerified'] == true,
      returnVerified: json['returnVerified'] == true,
      cancellationReason: json['cancellationReason']?.toString(),
      createdAtUtc: json['createdAtUtc']?.toString(),
      updatedAtUtc: json['updatedAtUtc']?.toString(),
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
      'dailyRate': dailyRate,
      'totalRentalFee': totalRentalFee,
      'status': status,
      'pickupVerified': pickupVerified,
      'returnVerified': returnVerified,
      'cancellationReason': cancellationReason,
      'createdAtUtc': createdAtUtc,
      'updatedAtUtc': updatedAtUtc,
    };
  }

  BookingModel copyWith({
    String? id,
    String? equipmentId,
    String? renterId,
    String? ownerId,
    DateTime? startDate,
    DateTime? endDate,
    double? dailyRate,
    double? totalRentalFee,
    String? status,
    bool? pickupVerified,
    bool? returnVerified,
    String? cancellationReason,
    String? createdAtUtc,
    String? updatedAtUtc,
  }) {
    return BookingModel(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      renterId: renterId ?? this.renterId,
      ownerId: ownerId ?? this.ownerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dailyRate: dailyRate ?? this.dailyRate,
      totalRentalFee: totalRentalFee ?? this.totalRentalFee,
      status: status ?? this.status,
      pickupVerified: pickupVerified ?? this.pickupVerified,
      returnVerified: returnVerified ?? this.returnVerified,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }
}
