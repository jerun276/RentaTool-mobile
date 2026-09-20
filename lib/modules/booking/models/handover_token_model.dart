class HandoverTokenModel {
  final String bookingId;
  final String token;
  final String eventType; // 'Pickup' or 'Return'
  final String expiresAtUtc;
  final String qrPayload;

  const HandoverTokenModel({
    required this.bookingId,
    required this.token,
    required this.eventType,
    required this.expiresAtUtc,
    required this.qrPayload,
  });

  factory HandoverTokenModel.fromJson(Map<String, dynamic> json) {
    return HandoverTokenModel(
      bookingId: json['bookingId'] ?? '',
      token: json['token'] ?? '',
      eventType: json['eventType'] ?? 'Pickup',
      expiresAtUtc: json['expiresAtUtc'] ?? '',
      qrPayload: json['qrPayload'] ?? json['token'] ?? '',
    );
  }
}
