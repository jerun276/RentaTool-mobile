import 'inspection_log_model.dart';

class EquipmentHistoryTimelineModel {
  final String equipmentId;
  final String title;
  final int totalRentalDays;
  final bool requiresMaintenance;
  final String? lastServicingDateUtc;
  final List<InspectionLogModel> inspectionTimeline;

  const EquipmentHistoryTimelineModel({
    required this.equipmentId,
    required this.title,
    required this.totalRentalDays,
    required this.requiresMaintenance,
    this.lastServicingDateUtc,
    this.inspectionTimeline = const [],
  });

  bool get isLockoutTriggered =>
      requiresMaintenance || totalRentalDays >= 60;

  factory EquipmentHistoryTimelineModel.fromJson(Map<String, dynamic> json) {
    var rawList = json['inspectionTimeline'] as List<dynamic>? ?? [];
    var timeline = rawList
        .map((e) => InspectionLogModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return EquipmentHistoryTimelineModel(
      equipmentId: json['equipmentId'] ?? '',
      title: json['title'] ?? '',
      totalRentalDays: json['totalRentalDays'] ?? 0,
      requiresMaintenance: json['requiresMaintenance'] ?? false,
      lastServicingDateUtc: json['lastServicingDateUtc'],
      inspectionTimeline: timeline,
    );
  }
}
