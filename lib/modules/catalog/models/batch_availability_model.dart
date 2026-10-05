class EquipmentAvailabilityItemModel {
  final String equipmentId;
  final String title;
  final double dailyRate;
  final int accumulatedDays;
  final bool isSafeForDispatch;

  const EquipmentAvailabilityItemModel({
    required this.equipmentId,
    required this.title,
    required this.dailyRate,
    required this.accumulatedDays,
    this.isSafeForDispatch = true,
  });

  factory EquipmentAvailabilityItemModel.fromJson(Map<String, dynamic> json) {
    return EquipmentAvailabilityItemModel(
      equipmentId: json['equipmentId'] ?? '',
      title: json['title'] ?? '',
      dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0.0,
      accumulatedDays: json['accumulatedDays'] ?? 0,
      isSafeForDispatch: json['isSafeForDispatch'] ?? true,
    );
  }
}

class LockedOutEquipmentModel {
  final String equipmentId;
  final String title;
  final String lockoutReason;
  final String requiredAction;
  final int accumulatedRentalDays;
  final bool servicingMandatory;

  const LockedOutEquipmentModel({
    required this.equipmentId,
    required this.title,
    required this.lockoutReason,
    required this.requiredAction,
    required this.accumulatedRentalDays,
    required this.servicingMandatory,
  });

  factory LockedOutEquipmentModel.fromJson(Map<String, dynamic> json) {
    return LockedOutEquipmentModel(
      equipmentId: json['equipmentId'] ?? '',
      title: json['title'] ?? '',
      lockoutReason: json['lockoutReason'] ?? 'Wear limit reached',
      requiredAction: json['requiredAction'] ?? 'Mandatory servicing required',
      accumulatedRentalDays: json['accumulatedRentalDays'] ?? 0,
      servicingMandatory: json['servicingMandatory'] ?? true,
    );
  }
}

class BatchAvailabilityResultModel {
  final int totalRequested;
  final int totalAvailable;
  final int totalLockedOut;
  final List<EquipmentAvailabilityItemModel> availableItems;
  final List<LockedOutEquipmentModel> lockedOutItems;

  const BatchAvailabilityResultModel({
    required this.totalRequested,
    required this.totalAvailable,
    required this.totalLockedOut,
    this.availableItems = const [],
    this.lockedOutItems = const [],
  });

  bool get hasLockouts => totalLockedOut > 0;

  factory BatchAvailabilityResultModel.fromJson(Map<String, dynamic> json) {
    var availRaw = json['availableItems'] as List<dynamic>? ?? [];
    var lockedRaw = json['lockedOutItems'] as List<dynamic>? ?? [];

    return BatchAvailabilityResultModel(
      totalRequested: json['totalRequested'] ?? 0,
      totalAvailable: json['totalAvailable'] ?? 0,
      totalLockedOut: json['totalLockedOut'] ?? 0,
      availableItems: availRaw
          .map((e) => EquipmentAvailabilityItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      lockedOutItems: lockedRaw
          .map((e) => LockedOutEquipmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
