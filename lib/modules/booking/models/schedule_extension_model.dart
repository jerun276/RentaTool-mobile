/// Request model to extend the rental schedule.
/// Matches backend [ExtendScheduleRequestDto].
class ExtendScheduleRequestModel {
  final DateTime newEndDate;

  const ExtendScheduleRequestModel({
    required this.newEndDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'newEndDate': newEndDate.toIso8601String(),
    };
  }
}

/// Response returned by backend with dynamic surge pricing details.
/// Matches backend [ExtendScheduleResponseDto].
class ExtendScheduleResponseModel {
  final String bookingId;
  final DateTime previousEndDate;
  final DateTime newEndDate;
  final int extendedDays;
  final double baseDailyRate;
  final double surgeMultiplier;
  final double surgeDailyRate;
  final double additionalFee;
  final double newTotalRentalFee;
  final String reason;

  const ExtendScheduleResponseModel({
    required this.bookingId,
    required this.previousEndDate,
    required this.newEndDate,
    required this.extendedDays,
    required this.baseDailyRate,
    required this.surgeMultiplier,
    required this.surgeDailyRate,
    required this.additionalFee,
    required this.newTotalRentalFee,
    required this.reason,
  });

  /// Percentage surge increase for UI chips (e.g. "+25%")
  String get surgePercentageString {
    final pct = ((surgeMultiplier - 1.0) * 100).round();
    return pct > 0 ? '+$pct%' : 'Standard Rate';
  }

  /// True if surge pricing applied
  bool get hasSurge => surgeMultiplier > 1.0;

  factory ExtendScheduleResponseModel.fromJson(Map<String, dynamic> json) {
    return ExtendScheduleResponseModel(
      bookingId: json['bookingId']?.toString() ?? '',
      previousEndDate: DateTime.tryParse(json['previousEndDate']?.toString() ?? '') ?? DateTime.now(),
      newEndDate: DateTime.tryParse(json['newEndDate']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 1)),
      extendedDays: (json['extendedDays'] as num?)?.toInt() ?? 1,
      baseDailyRate: (json['baseDailyRate'] as num?)?.toDouble() ?? 0.0,
      surgeMultiplier: (json['surgeMultiplier'] as num?)?.toDouble() ?? 1.0,
      surgeDailyRate: (json['surgeDailyRate'] as num?)?.toDouble() ?? 0.0,
      additionalFee: (json['additionalFee'] as num?)?.toDouble() ?? 0.0,
      newTotalRentalFee: (json['newTotalRentalFee'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason']?.toString() ?? 'Standard schedule extension',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'previousEndDate': previousEndDate.toIso8601String(),
      'newEndDate': newEndDate.toIso8601String(),
      'extendedDays': extendedDays,
      'baseDailyRate': baseDailyRate,
      'surgeMultiplier': surgeMultiplier,
      'surgeDailyRate': surgeDailyRate,
      'additionalFee': additionalFee,
      'newTotalRentalFee': newTotalRentalFee,
      'reason': reason,
    };
  }
}
