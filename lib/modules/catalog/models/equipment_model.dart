class ToolImageModel {
  final String imageUrl;
  final String angle; // 'Casing', 'Cord', 'Motor', 'General'
  final bool isPrimary;

  const ToolImageModel({
    required this.imageUrl,
    this.angle = 'General',
    this.isPrimary = false,
  });

  factory ToolImageModel.fromJson(dynamic json) {
    if (json is String) {
      return ToolImageModel(imageUrl: json);
    }
    if (json is Map<String, dynamic>) {
      return ToolImageModel(
        imageUrl: json['imageUrl'] ?? '',
        angle: json['angle'] ?? 'General',
        isPrimary: json['isPrimary'] ?? false,
      );
    }
    return const ToolImageModel(imageUrl: '');
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'angle': angle,
      'isPrimary': isPrimary,
    };
  }
}

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
  final String specificationsJson;
  final List<ToolImageModel> images;

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
    this.specificationsJson = '{}',
    this.images = const [],
  });

  /// True if total rental days reached or exceeded the 60-day policy threshold
  bool get isWearLimitReached => totalRentalDaysAccumulated >= 60;

  /// True if locked out from booking due to mandatory wear servicing or maintenance
  bool get isWearLocked =>
      requiresMaintenanceCheck ||
      status.toLowerCase() == 'undermaintenance' ||
      isWearLimitReached;

  /// Days remaining before mandatory 60-day inspection lockout
  int get daysUntilLockout =>
      (60 - totalRentalDaysAccumulated).clamp(0, 60);

  /// Primary image URL or fallback to first image
  String get primaryImageUrl {
    if (images.isEmpty) return '';
    final primary = images.firstWhere(
      (img) => img.isPrimary,
      orElse: () => images.first,
    );
    return primary.imageUrl;
  }

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    var rawImages = json['images'] as List<dynamic>? ?? [];
    List<ToolImageModel> parsedImages = rawImages
        .map((img) => ToolImageModel.fromJson(img))
        .where((img) => img.imageUrl.isNotEmpty)
        .toList();

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
      specificationsJson: json['specificationsJson'] ?? '{}',
      images: parsedImages,
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
      'specificationsJson': specificationsJson,
      'images': images.map((e) => e.toJson()).toList(),
    };
  }
}
