/// Request payload for verifying a QR handover token with GPS coordinates.
/// Matches backend [VerifyHandoverRequestDto].
class VerifyHandoverRequestModel {
  final String token;
  final String eventType; // 'Pickup' or 'Return'
  final double latitude;
  final double longitude;
  final String? addressLine;
  final String? city;
  final String? postalCode;

  const VerifyHandoverRequestModel({
    required this.token,
    required this.eventType,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.addressLine,
    this.city,
    this.postalCode,
  });

  /// HandoverEventType integer representation (1 = Pickup, 2 = Return)
  int get eventTypeInt => eventType.toLowerCase() == 'return' ? 2 : 1;

  Map<String, dynamic> toJson() {
    return {
      'token': token.trim(),
      'eventType': eventTypeInt,
      'latitude': latitude,
      'longitude': longitude,
      'addressLine': addressLine ?? '',
      'city': city ?? '',
      'postalCode': postalCode ?? '',
    };
  }
}

/// Response returned by backend upon successful handover verification.
/// Matches backend [HandoverVerificationResponseDto].
class HandoverVerificationResponseModel {
  final String bookingId;
  final String eventType;
  final DateTime verifiedAtUtc;
  final String newBookingStatus;
  final bool isSuccess;
  final String message;

  const HandoverVerificationResponseModel({
    required this.bookingId,
    required this.eventType,
    required this.verifiedAtUtc,
    required this.newBookingStatus,
    required this.isSuccess,
    required this.message,
  });

  factory HandoverVerificationResponseModel.fromJson(Map<String, dynamic> json) {
    return HandoverVerificationResponseModel(
      bookingId: json['bookingId']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? '',
      verifiedAtUtc: DateTime.tryParse(json['verifiedAtUtc']?.toString() ?? '') ?? DateTime.now(),
      newBookingStatus: json['newBookingStatus']?.toString() ?? 'Active',
      isSuccess: json['isSuccess'] == true,
      message: json['message']?.toString() ?? 'Handover successfully verified.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'eventType': eventType,
      'verifiedAtUtc': verifiedAtUtc.toIso8601String(),
      'newBookingStatus': newBookingStatus,
      'isSuccess': isSuccess,
      'message': message,
    };
  }
}
