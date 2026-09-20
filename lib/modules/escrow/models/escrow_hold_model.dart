class EscrowHoldModel {
  final String id;
  final String bookingId;
  final double depositAmount;
  final String preAuthTransactionId;
  final String status; // 'Held', 'Settled', 'Released', 'PartiallyDeducted'
  final String? heldAtUtc;
  final String? settledAtUtc;

  const EscrowHoldModel({
    required this.id,
    required this.bookingId,
    required this.depositAmount,
    required this.preAuthTransactionId,
    required this.status,
    this.heldAtUtc,
    this.settledAtUtc,
  });

  factory EscrowHoldModel.fromJson(Map<String, dynamic> json) {
    return EscrowHoldModel(
      id: json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0.0,
      preAuthTransactionId: json['preAuthTransactionId'] ?? '',
      status: json['status'] ?? 'Held',
      heldAtUtc: json['heldAtUtc'],
      settledAtUtc: json['settledAtUtc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'depositAmount': depositAmount,
      'preAuthTransactionId': preAuthTransactionId,
      'status': status,
      'heldAtUtc': heldAtUtc,
      'settledAtUtc': settledAtUtc,
    };
  }
}
