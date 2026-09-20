class EquipmentModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String categoryId;
  final String categoryName;
  final double dailyRate;
  final double replacementValue;
  final String status;
  final String location;
  final int totalRentalDaysAccumulated;
  final bool requiresMaintenanceCheck;
  final String? lastMaintenanceDateUtc;
  final List<String> images;

  const EquipmentModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.categoryId,
    this.categoryName = 'Heavy Machinery',
    required this.dailyRate,
    required this.replacementValue,
    required this.status,
    required this.location,
    this.totalRentalDaysAccumulated = 0,
    this.requiresMaintenanceCheck = false,
    this.lastMaintenanceDateUtc,
    this.images = const [],
  });

  bool get isWearLocked =>
      requiresMaintenanceCheck ||
      status == 'UnderMaintenance' ||
      totalRentalDaysAccumulated >= 60;

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? 'Heavy Machinery',
      dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0.0,
      replacementValue: (json['replacementValue'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Available',
      location: json['location'] ?? 'Colombo',
      totalRentalDaysAccumulated: json['totalRentalDaysAccumulated'] ?? 0,
      requiresMaintenanceCheck: json['requiresMaintenanceCheck'] ?? false,
      lastMaintenanceDateUtc: json['lastMaintenanceDateUtc'],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'dailyRate': dailyRate,
      'replacementValue': replacementValue,
      'status': status,
      'location': location,
      'totalRentalDaysAccumulated': totalRentalDaysAccumulated,
      'requiresMaintenanceCheck': requiresMaintenanceCheck,
      'lastMaintenanceDateUtc': lastMaintenanceDateUtc,
      'images': images,
    };
  }
}
