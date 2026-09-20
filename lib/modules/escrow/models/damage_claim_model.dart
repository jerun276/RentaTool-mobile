class DamageClaimModel {
  final String claimId;
  final String bookingId;
  final String filedByUserId;
  final String damageDescription;
  final List<String> evidencePhotos;
  final double proposedDeduction;
  final double? finalDeduction;
  final String status; // 'Filed', 'UnderAIEvaluation', 'PendingStaffApproval', 'Approved', 'Revised', 'Rejected', 'Settled'
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
    this.adjudicationNotes,
    this.adjudicatedByUserId,
    this.adjudicatedAtUtc,
    this.createdAtUtc,
  });

  factory DamageClaimModel.fromJson(Map<String, dynamic> json) {
    return DamageClaimModel(
      claimId: json['claimId'] ?? json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      filedByUserId: json['filedByUserId'] ?? '',
      damageDescription: json['damageDescription'] ?? '',
      evidencePhotos: (json['evidencePhotos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      proposedDeduction: (json['proposedDeduction'] as num?)?.toDouble() ?? 0.0,
      finalDeduction: (json['finalDeduction'] as num?)?.toDouble(),
      status: json['status'] ?? 'Filed',
      adjudicationNotes: json['adjudicationNotes'],
      adjudicatedByUserId: json['adjudicatedByUserId'],
      adjudicatedAtUtc: json['adjudicatedAtUtc'],
      createdAtUtc: json['createdAtUtc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'claimId': claimId,
      'bookingId': bookingId,
      'filedByUserId': filedByUserId,
      'damageDescription': damageDescription,
      'evidencePhotos': evidencePhotos,
      'proposedDeduction': proposedDeduction,
      'finalDeduction': finalDeduction,
      'status': status,
      'adjudicationNotes': adjudicationNotes,
    };
  }
}
