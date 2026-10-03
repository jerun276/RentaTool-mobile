class KycSubmissionModel {
  final String? kycRecordId;
  final String userId;
  final String? name;
  final String documentType;
  final String documentNumber;
  final String? frontImageUrl;
  final String? backImageUrl;
  final String status;
  final String? rejectionReason;
  final String? submittedAtUtc;

  const KycSubmissionModel({
    this.kycRecordId,
    required this.userId,
    this.name,
    this.documentType = 'NIC',
    required this.documentNumber,
    this.frontImageUrl,
    this.backImageUrl,
    this.status = 'Pending',
    this.rejectionReason,
    this.submittedAtUtc,
  });

  static String _parseStatus(dynamic val) {
    if (val == null) return 'Pending';
    if (val is int) {
      if (val == 2) return 'Approved';
      if (val == 3) return 'Rejected';
      return 'Pending';
    }
    final s = val.toString().trim();
    if (s.toLowerCase() == 'approved' || s == '2') return 'Approved';
    if (s.toLowerCase() == 'rejected' || s == '3') return 'Rejected';
    if (s.toLowerCase() == 'pending' || s == '1') return 'Pending';
    return s;
  }

  factory KycSubmissionModel.fromJson(Map<String, dynamic> json) {
    return KycSubmissionModel(
      kycRecordId: json['kycRecordId'],
      userId: json['userId'] ?? '',
      name: json['name'],
      documentType: json['documentType'] ?? 'NIC',
      documentNumber: json['documentNumber'] ?? '',
      frontImageUrl: json['frontImageUrl'],
      backImageUrl: json['backImageUrl'],
      status: _parseStatus(json['status']),
      rejectionReason: json['rejectionReason'],
      submittedAtUtc: json['submittedAtUtc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentType': documentType,
      'documentNumber': documentNumber,
    };
  }
}
