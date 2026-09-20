class InspectionLogModel {
  final String id;
  final String equipmentId;
  final String inspectorId;
  final String inspectionType; // 'PreRental', 'PostRental', 'Maintenance'
  final String notes;
  final List<String> photoUrls;
  final bool passed;
  final String? createdAtUtc;

  const InspectionLogModel({
    required this.id,
    required this.equipmentId,
    required this.inspectorId,
    required this.inspectionType,
    required this.notes,
    this.photoUrls = const [],
    this.passed = true,
    this.createdAtUtc,
  });

  factory InspectionLogModel.fromJson(Map<String, dynamic> json) {
    return InspectionLogModel(
      id: json['id'] ?? '',
      equipmentId: json['equipmentId'] ?? '',
      inspectorId: json['inspectorId'] ?? '',
      inspectionType: json['inspectionType'] ?? 'PreRental',
      notes: json['notes'] ?? '',
      photoUrls: (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      passed: json['passed'] ?? true,
      createdAtUtc: json['createdAtUtc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inspectionType': inspectionType,
      'notes': notes,
      'photoUrls': photoUrls,
      'passed': passed,
    };
  }
}
