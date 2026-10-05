/// Escrow status values matching backend EscrowStatus enum (Held|Disbursed|Refunded|Disputed).
enum EscrowStatus {
  held,
  disbursed,
  refunded,
  disputed,
  unknown;

  static EscrowStatus fromString(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'held':
        return EscrowStatus.held;
      case 'disbursed':
        return EscrowStatus.disbursed;
      case 'refunded':
        return EscrowStatus.refunded;
      case 'disputed':
        return EscrowStatus.disputed;
      default:
        return EscrowStatus.unknown;
    }
  }

  String get displayLabel {
    switch (this) {
      case EscrowStatus.held:
        return 'Held';
      case EscrowStatus.disbursed:
        return 'Disbursed';
      case EscrowStatus.refunded:
        return 'Refunded';
      case EscrowStatus.disputed:
        return 'Disputed';
      case EscrowStatus.unknown:
        return 'Unknown';
    }
  }
}

/// Matches backend PreAuthorizeDepositResponse and GetByBooking anonymous object.
class EscrowHoldModel {
  final String id;
  final String bookingId;
  final double depositAmount;
  final String preAuthTransactionId;
  final EscrowStatus status;
  final String rawStatus;
  final String? heldAtUtc;
  final String? settledAtUtc;

  const EscrowHoldModel({
    required this.id,
    required this.bookingId,
    required this.depositAmount,
    required this.preAuthTransactionId,
    required this.status,
    required this.rawStatus,
    this.heldAtUtc,
    this.settledAtUtc,
  });

  factory EscrowHoldModel.fromJson(Map<String, dynamic> json) {
    final rawStatus =
        (json['status'] ?? json['Status'] ?? 'Held').toString();
    return EscrowHoldModel(
      id: (json['id'] ?? json['escrowId'] ?? '').toString(),
      bookingId: (json['bookingId'] ?? '').toString(),
      depositAmount:
          ((json['depositAmount'] ?? json['DepositAmount']) as num? ?? 0)
              .toDouble(),
      preAuthTransactionId:
          (json['preAuthTransactionId'] ?? '').toString(),
      status: EscrowStatus.fromString(rawStatus),
      rawStatus: rawStatus,
      heldAtUtc: json['heldAtUtc']?.toString(),
      settledAtUtc: json['settledAtUtc']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingId': bookingId,
        'depositAmount': depositAmount,
        'preAuthTransactionId': preAuthTransactionId,
        'status': rawStatus,
        'heldAtUtc': heldAtUtc,
        'settledAtUtc': settledAtUtc,
      };
}
