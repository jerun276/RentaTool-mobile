/// Claim status values matching backend ClaimStatus enum.
enum ClaimStatus {
  filed,
  underAIEvaluation,
  pendingStaffApproval,
  approved,
  revised,
  rejected,
  settled,
  unknown;

  static ClaimStatus fromString(String? raw) {
    switch ((raw ?? '').toLowerCase().replaceAll('_', '')) {
      case 'filed':
        return ClaimStatus.filed;
      case 'underaievaluation':
        return ClaimStatus.underAIEvaluation;
      case 'pendingstaffapproval':
        return ClaimStatus.pendingStaffApproval;
      case 'approved':
        return ClaimStatus.approved;
      case 'revised':
        return ClaimStatus.revised;
      case 'rejected':
        return ClaimStatus.rejected;
      case 'settled':
        return ClaimStatus.settled;
      default:
        return ClaimStatus.unknown;
    }
  }

  String get displayLabel {
    switch (this) {
      case ClaimStatus.filed:
        return 'Filed';
      case ClaimStatus.underAIEvaluation:
        return 'Under AI Evaluation';
      case ClaimStatus.pendingStaffApproval:
        return 'Pending Review';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.revised:
        return 'Revised';
      case ClaimStatus.rejected:
        return 'Rejected';
      case ClaimStatus.settled:
        return 'Settled';
      case ClaimStatus.unknown:
        return 'Unknown';
    }
  }

  bool get isTerminal =>
      this == ClaimStatus.rejected ||
      this == ClaimStatus.settled;

  bool get canAdjudicate =>
      this == ClaimStatus.filed ||
      this == ClaimStatus.underAIEvaluation ||
      this == ClaimStatus.pendingStaffApproval;

  bool get canPayout =>
      this == ClaimStatus.approved || this == ClaimStatus.revised;
}

/// Matches backend DamageClaimResponse DTO.
class DamageClaimModel {
  final String claimId;
  final String bookingId;
  final String filedByUserId;
  final String damageDescription;
  final List<String> evidencePhotos;
  final double proposedDeduction;
  final double? finalDeduction;
  final ClaimStatus status;
  final String rawStatus;
  final String? adjudicationNotes;
  final String? adjudicatedByUserId;
  final String? adjudicatedAtUtc;
  final String? createdAtUtc;

  const DamageClaimModel({
    required this.claimId,
    required this.bookingId,
    required this.filedByUserId,
    required this.damageDescription,
    this.evidencePhotos = const [],
    required this.proposedDeduction,
    this.finalDeduction,
    required this.status,
    required this.rawStatus,
    this.adjudicationNotes,
    this.adjudicatedByUserId,
    this.adjudicatedAtUtc,
    this.createdAtUtc,
  });

  factory DamageClaimModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? 'Filed').toString();
    return DamageClaimModel(
      claimId: (json['claimId'] ?? json['id'] ?? '').toString(),
      bookingId: (json['bookingId'] ?? '').toString(),
      filedByUserId: (json['filedByUserId'] ?? '').toString(),
      damageDescription: (json['damageDescription'] ?? '').toString(),
      evidencePhotos: (json['evidencePhotos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      proposedDeduction:
          ((json['proposedDeduction']) as num? ?? 0).toDouble(),
      finalDeduction: (json['finalDeduction'] as num?)?.toDouble(),
      status: ClaimStatus.fromString(rawStatus),
      rawStatus: rawStatus,
      adjudicationNotes: json['adjudicationNotes']?.toString(),
      adjudicatedByUserId: json['adjudicatedByUserId']?.toString(),
      adjudicatedAtUtc: json['adjudicatedAtUtc']?.toString(),
      createdAtUtc: json['createdAtUtc']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'claimId': claimId,
        'bookingId': bookingId,
        'filedByUserId': filedByUserId,
        'damageDescription': damageDescription,
        'evidencePhotos': evidencePhotos,
        'proposedDeduction': proposedDeduction,
        'finalDeduction': finalDeduction,
        'status': rawStatus,
        'adjudicationNotes': adjudicationNotes,
      };
}

/// Matches backend PayoutClaimResponse DTO.
class PayoutClaimResponse {
  final String claimId;
  final String bookingId;
  final double ownerPayoutAmount;
  final double renterRefundAmount;
  final String status;
  final String settlementReference;
  final String settledAtUtc;

  const PayoutClaimResponse({
    required this.claimId,
    required this.bookingId,
    required this.ownerPayoutAmount,
    required this.renterRefundAmount,
    required this.status,
    required this.settlementReference,
    required this.settledAtUtc,
  });

  factory PayoutClaimResponse.fromJson(Map<String, dynamic> json) {
    return PayoutClaimResponse(
      claimId: (json['claimId'] ?? '').toString(),
      bookingId: (json['bookingId'] ?? '').toString(),
      ownerPayoutAmount:
          ((json['ownerPayoutAmount']) as num? ?? 0).toDouble(),
      renterRefundAmount:
          ((json['renterRefundAmount']) as num? ?? 0).toDouble(),
      status: (json['status'] ?? 'Settled').toString(),
      settlementReference:
          (json['settlementReference'] ?? '').toString(),
      settledAtUtc: (json['settledAtUtc'] ?? '').toString(),
    );
  }
}
