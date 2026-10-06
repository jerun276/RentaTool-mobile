/// Request payload for creating a new booking reservation.
/// Matches backend [CreateBookingRequestDto].
class CreateBookingRequestModel {
  final String equipmentId;
  final String ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final double dailyRate;

  const CreateBookingRequestModel({
    required this.equipmentId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.dailyRate,
  });

  /// Duration in days
  int get durationInDays {
    final diff = endDate.difference(startDate).inDays;
    return diff <= 0 ? 1 : diff + 1;
  }

  /// Estimated total rental fee
  double get estimatedTotalFee => durationInDays * dailyRate;

  Map<String, dynamic> toJson() {
    return {
      'equipmentId': equipmentId,
      'ownerId': ownerId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'dailyRate': dailyRate,
    };
  }
}
