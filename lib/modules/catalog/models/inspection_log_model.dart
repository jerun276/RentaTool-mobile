import 'dart:convert';

class InspectionPhotoModel {
  final String angle; // 'Casing', 'Cord', 'Motor', 'General'
  final String photoUrl;
  final String? observationNote;
  final DateTime? capturedAtUtc;

  const InspectionPhotoModel({
    required this.angle,
    required this.photoUrl,
    this.observationNote,
    this.capturedAtUtc,
  });

  factory InspectionPhotoModel.fromJson(dynamic json) {
    if (json is String) {
      return InspectionPhotoModel(angle: 'General', photoUrl: json);
    }
    if (json is Map) {
      final url = json['photoUrl'] ??
          json['PhotoUrl'] ??
          json['photo_url'] ??
          json['url'] ??
          json['Url'] ??
          '';
      final angle = json['angle'] ?? json['Angle'] ?? 'General';
      final note = json['observationNote'] ?? json['ObservationNote'] ?? json['note'];
      final dateVal = json['capturedAtUtc'] ?? json['CapturedAtUtc'];
      return InspectionPhotoModel(
        angle: angle.toString(),
        photoUrl: url.toString(),
        observationNote: note?.toString(),
        capturedAtUtc: dateVal != null ? DateTime.tryParse(dateVal.toString()) : null,
      );
    }
    return const InspectionPhotoModel(angle: 'General', photoUrl: '');
  }

  Map<String, dynamic> toJson() {
    return {
      'angle': angle,
      'photoUrl': photoUrl,
      'observationNote': observationNote,
      if (capturedAtUtc != null) 'capturedAtUtc': capturedAtUtc!.toIso8601String(),
    };
  }
}

class InspectionLogModel {
  final String id;
  final String equipmentId;
  final String? bookingId;
  final String inspectorId;
  final String inspectionType; // 'PreRental', 'PostRental', 'PeriodicMaintenance', 'DamageAssessment'
  final String severity; // 'None', 'Minor', 'Moderate', 'Severe', 'Critical'
  final String conditionNotes;
  final List<InspectionPhotoModel> photos;
  final bool passed;
  final String? createdAtUtc;

  const InspectionLogModel({
    required this.id,
    required this.equipmentId,
    this.bookingId,
    required this.inspectorId,
    required this.inspectionType,
    this.severity = 'None',
    required this.conditionNotes,
    this.photos = const [],
    this.passed = true,
    this.createdAtUtc,
  });

  bool get isSevereOrCritical =>
      severity.toLowerCase() == 'severe' ||
      severity.toLowerCase() == 'critical' ||
      severity.toLowerCase() == 'structuraldamage';

  factory InspectionLogModel.fromJson(Map<String, dynamic> json) {
    List<InspectionPhotoModel> parsedPhotos = [];

    final rawPhotos = json['photos'] ?? json['Photos'];
    final rawPhotosJson = json['photosJson'] ?? json['PhotosJson'];
    final rawPhotoUrls = json['photoUrls'] ?? json['PhotoUrls'];

    if (rawPhotos is List) {
      parsedPhotos = rawPhotos
          .map((p) => InspectionPhotoModel.fromJson(p))
          .toList();
    } else if (rawPhotosJson != null && rawPhotosJson.toString().trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPhotosJson.toString());
        if (decoded is List) {
          parsedPhotos = decoded
              .map((p) => InspectionPhotoModel.fromJson(p))
              .toList();
        }
      } catch (_) {}
    } else if (rawPhotoUrls is List) {
      parsedPhotos = rawPhotoUrls
          .map((url) => InspectionPhotoModel(angle: 'General', photoUrl: url.toString()))
          .toList();
    }

    // Determine passed status from severity if not explicitly passed
    final rawSeverity = json['severity']?.toString() ?? 'None';
    final isNoneOrMinor = rawSeverity.toLowerCase() == 'none' || rawSeverity.toLowerCase() == 'minor';
    final passedBool = json['passed'] is bool ? json['passed'] as bool : isNoneOrMinor;

    return InspectionLogModel(
      id: json['id'] ?? '',
      equipmentId: json['equipmentId'] ?? '',
      bookingId: json['bookingId'],
      inspectorId: json['inspectorUserId'] ?? json['inspectorId'] ?? '',
      inspectionType: json['type'] ?? json['inspectionType'] ?? 'PreRental',
      severity: rawSeverity,
      conditionNotes: json['conditionNotes'] ?? json['notes'] ?? '',
      photos: parsedPhotos,
      passed: passedBool,
      createdAtUtc: json['createdAtUtc']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      if (bookingId != null) 'bookingId': bookingId,
      'inspectorUserId': inspectorId,
      'type': inspectionType,
      'severity': severity,
      'conditionNotes': conditionNotes,
      'photos': photos.map((p) => p.toJson()).toList(),
      'passed': passed,
      'createdAtUtc': createdAtUtc,
    };
  }
}
