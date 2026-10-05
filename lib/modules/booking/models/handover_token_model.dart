/// Single-use cryptographically hashed handover token model.
/// Aligns with backend [HandoverTokenResponseDto].
class HandoverTokenModel {
  final String bookingId;
  final String token;
  final String eventType; // 'Pickup' or 'Return'
  final DateTime expiresAt;
  final String instructions;
  final String qrPayload;

  const HandoverTokenModel({
    required this.bookingId,
    required this.token,
    required this.eventType,
    required this.expiresAt,
    this.instructions = '',
    required this.qrPayload,
  });

  /// Backward-compatible getter for ISO string format
  String get expiresAtUtc => expiresAt.toIso8601String();

  /// True if token TTL has expired
  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  /// Seconds remaining before expiration
  int get remainingSeconds {
    final diff = expiresAt.difference(DateTime.now().toUtc()).inSeconds;
    return diff <= 0 ? 0 : diff;
  }

  /// Formatted countdown string (e.g. "14:52")
  String get formattedRemainingTime {
    final sec = remainingSeconds;
    final mins = sec ~/ 60;
    final remainder = sec % 60;
    return '${mins.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  factory HandoverTokenModel.fromJson(Map<String, dynamic> json) {
    final expParsed = DateTime.tryParse(json['expiresAtUtc']?.toString() ?? '') ??
        DateTime.now().toUtc().add(const Duration(minutes: 15));
    final rawToken = json['token']?.toString() ?? '';

    return HandoverTokenModel(
      bookingId: json['bookingId']?.toString() ?? '',
      token: rawToken,
      eventType: json['eventType']?.toString() ?? 'Pickup',
      expiresAt: expParsed,
      instructions: json['instructions']?.toString() ??
          'Present this single-use QR token to the counterparty within 15 minutes.',
      qrPayload: json['qrPayload']?.toString() ?? rawToken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'token': token,
      'eventType': eventType,
      'expiresAtUtc': expiresAt.toIso8601String(),
      'instructions': instructions,
      'qrPayload': qrPayload,
    };
  }
}
