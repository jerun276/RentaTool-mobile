import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/batch_availability_model.dart';
import '../models/category_model.dart';
import '../models/equipment_history_model.dart';
import '../models/equipment_model.dart';
import '../models/inspection_log_model.dart';

final catalogServiceProvider = Provider<CatalogService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return CatalogService(dio);
});

class CatalogService {
  final Dio _dio;

  CatalogService(this._dio);

  /// Retrieves equipment feed with search, category filtering, status, and pagination
  Future<List<EquipmentModel>> getEquipment({
    String? search,
    String? categoryId,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      ApiConstants.equipment,
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'searchTerm': search.trim(),
        if (categoryId != null && categoryId.isNotEmpty && categoryId != 'All') 'categoryId': categoryId,
        if (status != null && status.isNotEmpty && status != 'All') 'status': status,
        'page': page,
        'pageSize': pageSize,
      },
    );

    final data = response.data;
    final List<dynamic> items = data is Map<String, dynamic>
        ? (data['items'] ?? [])
        : (data is List ? data : []);

    return items.map((e) => EquipmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Retrieves a single equipment listing with full specifications and photos
  Future<EquipmentModel> getEquipmentById(String id) async {
    final response = await _dio.get(ApiConstants.equipmentById(id));
    return EquipmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Creates a new machinery / equipment listing
  Future<EquipmentModel> createEquipment({
    required String title,
    required String description,
    required String categoryId,
    required double dailyRate,
    required double replacementValue,
    required String location,
    String specificationsJson = '{}',
    List<ToolImageModel> images = const [],
  }) async {
    final response = await _dio.post(
      ApiConstants.equipment,
      data: {
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'dailyRate': dailyRate,
        'replacementValue': replacementValue,
        'location': location,
        'specificationsJson': specificationsJson,
        'images': images.map((img) => img.toJson()).toList(),
      },
    );
    return EquipmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Records pre/post-rental condition inspection with multi-angle photographic evidence
  Future<InspectionLogModel> createInspectionLog({
    required String equipmentId,
    String? bookingId,
    required String type, // 'PreRental', 'PostRental', 'MaintenanceCheck'
    required String severity, // 'None', 'MinorWear', 'ModerateDamage', 'StructuralDamage'
    required String conditionNotes,
    List<InspectionPhotoModel> photos = const [],
  }) async {
    // Normalize type to backend InspectionType enum (PreRental, PostRental, MaintenanceCheck)
    String normalizedType = type;
    switch (type.toLowerCase()) {
      case 'periodicmaintenance':
      case 'maintenance':
      case 'maintenancecheck':
        normalizedType = 'MaintenanceCheck';
        break;
      case 'damageassessment':
      case 'damage':
      case 'postrental':
        normalizedType = 'PostRental';
        break;
      case 'prerental':
        normalizedType = 'PreRental';
        break;
      default:
        normalizedType = type;
        break;
    }

    // Normalize severity to backend InspectionSeverity enum (None, MinorWear, ModerateDamage, StructuralDamage)
    String normalizedSeverity = severity;
    switch (severity.toLowerCase()) {
      case 'minor':
      case 'minorwear':
        normalizedSeverity = 'MinorWear';
        break;
      case 'moderate':
      case 'moderatedamage':
        normalizedSeverity = 'ModerateDamage';
        break;
      case 'severe':
      case 'critical':
      case 'structuraldamage':
        normalizedSeverity = 'StructuralDamage';
        break;
      case 'none':
        normalizedSeverity = 'None';
        break;
      default:
        normalizedSeverity = severity;
        break;
    }

    final response = await _dio.post(
      ApiConstants.equipmentInspectionLogs(equipmentId),
      data: {
        if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
        'type': normalizedType,
        'severity': normalizedSeverity,
        'conditionNotes': conditionNotes,
        'photos': photos.map((p) => p.toJson()).toList(),
      },
    );
    return InspectionLogModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Retrieves maintenance history and inspection timeline for an equipment item
  Future<EquipmentHistoryTimelineModel> getEquipmentHistory(String equipmentId) async {
    final response = await _dio.get(ApiConstants.equipmentHistory(equipmentId));
    return EquipmentHistoryTimelineModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Business-specific check for maintenance wear lockouts and dispatch safety
  Future<BatchAvailabilityResultModel> checkBatchAvailability({
    required List<String> equipmentIds,
    required DateTime desiredStartDate,
    required DateTime desiredEndDate,
  }) async {
    final response = await _dio.post(
      ApiConstants.batchAvailability,
      data: {
        'equipmentIds': equipmentIds,
        'desiredStartDate': desiredStartDate.toIso8601String(),
        'desiredEndDate': desiredEndDate.toIso8601String(),
      },
    );
    return BatchAvailabilityResultModel.fromJson(response.data as Map<String, dynamic>);
  }

  static const List<CategoryModel> defaultCategories = [
    CategoryModel(
      id: 'c15d534b-8707-4d21-b04d-d5d3c1914c46',
      name: 'Heavy Machinery',
      description: 'Earthmoving, compaction, and civil construction equipment',
      iconUrl: 'https://cdn.rentatool.lk/icons/excavator.svg',
      specificationSchema: [
        CategorySpecFieldModel(key: 'operating_weight', label: 'Operating Weight', unit: 'tons', fieldType: 'number', isRequired: true),
        CategorySpecFieldModel(key: 'engine_power', label: 'Engine Power', unit: 'HP / kW', fieldType: 'text', isRequired: true),
        CategorySpecFieldModel(key: 'bucket_capacity', label: 'Bucket / Blade Capacity', unit: 'm³', fieldType: 'number'),
        CategorySpecFieldModel(key: 'max_dig_depth', label: 'Max Digging / Reach Depth', unit: 'm', fieldType: 'number'),
        CategorySpecFieldModel(key: 'fuel_type', label: 'Fuel Type', fieldType: 'select', isRequired: true, options: ['Diesel', 'Electric', 'Hybrid']),
      ],
    ),
    CategoryModel(
      id: '030da95c-0141-4f12-adf9-28793e5d3c6d',
      name: 'Power Tools',
      description: 'Heavy-duty electric & cordless drilling, fastening, and cutting tools',
      iconUrl: 'https://cdn.rentatool.lk/icons/drill.svg',
      specificationSchema: [
        CategorySpecFieldModel(key: 'power_rating', label: 'Power Rating', unit: 'W / kW', fieldType: 'text', isRequired: true),
        CategorySpecFieldModel(key: 'voltage', label: 'Operating Voltage', unit: 'V', fieldType: 'select', isRequired: true, options: ['110V', '230V / Single-Phase', '400V / 3-Phase', '18V Cordless Battery', '36V Cordless Battery']),
        CategorySpecFieldModel(key: 'chuck_blade_size', label: 'Chuck / Blade Size', unit: 'mm / inch', fieldType: 'text'),
        CategorySpecFieldModel(key: 'no_load_speed', label: 'Max Speed / RPM', unit: 'RPM', fieldType: 'number'),
        CategorySpecFieldModel(key: 'power_source', label: 'Power Source', fieldType: 'select', isRequired: true, options: ['Electric Corded', 'Cordless Li-ion', 'Pneumatic / Air', 'Petrol Engine']),
        CategorySpecFieldModel(key: 'weight', label: 'Tool Weight', unit: 'kg', fieldType: 'number'),
      ],
    ),
    CategoryModel(
      id: '641349d0-2a8d-4ca4-b896-2fd239cd283f',
      name: 'Generators & Power',
      description: 'Silent diesel & petrol portable power generators',
      iconUrl: 'https://cdn.rentatool.lk/icons/generator.svg',
      specificationSchema: [
        CategorySpecFieldModel(key: 'rated_output', label: 'Rated Output', unit: 'kVA / kW', fieldType: 'text', isRequired: true),
        CategorySpecFieldModel(key: 'voltage_phase', label: 'Voltage & Phase', fieldType: 'select', isRequired: true, options: ['230V Single-Phase', '400V Three-Phase', 'Dual Voltage (230V/400V)']),
        CategorySpecFieldModel(key: 'fuel_type', label: 'Fuel Type', fieldType: 'select', isRequired: true, options: ['Diesel', 'Petrol', 'LPG / Natural Gas', 'Solar Battery']),
        CategorySpecFieldModel(key: 'tank_capacity', label: 'Fuel Tank Capacity', unit: 'Liters', fieldType: 'number'),
        CategorySpecFieldModel(key: 'sound_level', label: 'Noise Level', unit: 'dBA @ 7m', fieldType: 'number'),
      ],
    ),
    CategoryModel(
      id: '7436c584-29c1-4e02-993f-f4af41fb2c9d',
      name: 'Cleaning Equipment',
      description: 'Industrial high-pressure washers, vacuum cleaners, and scrubbers',
      iconUrl: 'https://cdn.rentatool.lk/icons/washer.svg',
      specificationSchema: [
        CategorySpecFieldModel(key: 'working_pressure', label: 'Operating Pressure', unit: 'Bar / PSI', fieldType: 'text', isRequired: true),
        CategorySpecFieldModel(key: 'flow_rate', label: 'Water Flow Rate', unit: 'L/min', fieldType: 'number'),
        CategorySpecFieldModel(key: 'tank_capacity', label: 'Solution Tank Capacity', unit: 'Liters', fieldType: 'number'),
        CategorySpecFieldModel(key: 'power_source', label: 'Power Source', fieldType: 'select', isRequired: true, options: ['230V Electric', '400V 3-Phase', 'Petrol Engine', 'Diesel Engine']),
      ],
    ),
  ];

  /// Retrieves list of equipment categories and their technical specification schemas.
  /// Gracefully falls back to seeded categories if the backend does not host the /categories endpoint yet.
  Future<List<CategoryModel>> getCategories({bool activeOnly = true}) async {
    try {
      final response = await _dio.get(
        ApiConstants.categories,
        queryParameters: {'activeOnly': activeOnly},
      );
      final data = response.data;
      final List<dynamic> items = data is List ? data : (data['items'] ?? []);
      final list = items.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
      return list.isNotEmpty ? list : defaultCategories;
    } catch (_) {
      return defaultCategories;
    }
  }

  /// Retrieves a specific category by ID with its specification schema
  Future<CategoryModel> getCategoryById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.categoryById(id));
      return CategoryModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return defaultCategories.firstWhere(
        (c) => c.id == id,
        orElse: () => CategoryModel(id: id, name: 'General Equipment'),
      );
    }
  }

  /// Creates a new category with dynamic specification schema (Admin only)
  Future<CategoryModel> createCategory({
    required String name,
    String description = '',
    String iconUrl = '',
    List<CategorySpecFieldModel> specificationSchema = const [],
  }) async {
    final response = await _dio.post(
      ApiConstants.categories,
      data: {
        'name': name.trim(),
        'description': description.trim(),
        'iconUrl': iconUrl.trim(),
        'specificationSchema': specificationSchema.map((s) => s.toJson()).toList(),
      },
    );
    return CategoryModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Updates an existing category and its specification schema (Admin only)
  Future<CategoryModel> updateCategory({
    required String id,
    required String name,
    String description = '',
    String iconUrl = '',
    bool isActive = true,
    List<CategorySpecFieldModel> specificationSchema = const [],
  }) async {
    final response = await _dio.put(
      ApiConstants.categoryById(id),
      data: {
        'name': name.trim(),
        'description': description.trim(),
        'iconUrl': iconUrl.trim(),
        'isActive': isActive,
        'specificationSchema': specificationSchema.map((s) => s.toJson()).toList(),
      },
    );
    return CategoryModel.fromJson(response.data as Map<String, dynamic>);
  }
}
