import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  /// Updates an existing machinery / equipment listing
  Future<EquipmentModel> updateEquipment({
    required String id,
    required String title,
    required String description,
    required String categoryId,
    required double dailyRate,
    required double replacementValue,
    required String location,
    String specificationsJson = '{}',
    List<ToolImageModel> images = const [],
  }) async {
    final response = await _dio.put(
      '${ApiConstants.equipment}/$id',
      data: {
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'dailyRate': dailyRate,
        'replacementValue': replacementValue,
        'location': location,
        'specificationsJson': specificationsJson,
        if (images.isNotEmpty) 'images': images.map((img) => img.toJson()).toList(),
      },
    );
    return EquipmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Deletes an equipment listing (Owner or Admin only)
  Future<void> deleteEquipment(String id) async {
    await _dio.delete('${ApiConstants.equipment}/$id');
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
    // Map type to backend enum integer (PreRental = 1, PostRental = 2, MaintenanceCheck = 3)
    int typeInt = 1;
    switch (type.toLowerCase()) {
      case 'postrental':
      case '2':
        typeInt = 2;
        break;
      case 'maintenancecheck':
      case 'periodicmaintenance':
      case 'maintenance':
      case '3':
        typeInt = 3;
        break;
      case 'prerental':
      case '1':
      default:
        typeInt = 1;
        break;
    }

    // Map severity to backend enum integer (None = 0, MinorWear = 1, ModerateDamage = 2, StructuralDamage = 3)
    int severityInt = 0;
    switch (severity.toLowerCase()) {
      case 'minor':
      case 'minorwear':
      case '1':
        severityInt = 1;
        break;
      case 'moderate':
      case 'moderatedamage':
      case '2':
        severityInt = 2;
        break;
      case 'severe':
      case 'critical':
      case 'structuraldamage':
      case '3':
        severityInt = 3;
        break;
      case 'none':
      case '0':
      default:
        severityInt = 0;
        break;
    }

    final response = await _dio.post(
      ApiConstants.equipmentInspectionLogs(equipmentId),
      data: {
        if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
        'type': typeInt,
        'severity': severityInt,
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

  static const List<CategoryModel> defaultSeedCategories = [
    CategoryModel(
      id: '352ea07e-bd97-481b-a287-027036658902',
      name: 'Heavy Machinery',
      description: 'Earthmoving, compaction, and civil construction equipment',
      iconUrl: 'https://cdn.rentatool.lk/icons/excavator.svg',
    ),
    CategoryModel(
      id: 'b25c3bf2-9d33-4df4-b3c9-02660a92d244',
      name: 'Power Tools',
      description: 'Heavy-duty electric & cordless drilling, fastening, and cutting tools',
      iconUrl: 'https://cdn.rentatool.lk/icons/drill.svg',
    ),
    CategoryModel(
      id: '64949df2-eb06-4447-920a-f0fbf1fa000a',
      name: 'Generators & Power',
      description: 'Silent diesel & petrol portable power generators',
      iconUrl: 'https://cdn.rentatool.lk/icons/generator.svg',
    ),
    CategoryModel(
      id: '8ca549e3-2fc5-48b3-aa2d-aa5d15a7cf93',
      name: 'Cleaning Equipment',
      description: 'Industrial high-pressure washers, vacuum cleaners, and scrubbers',
      iconUrl: 'https://cdn.rentatool.lk/icons/washer.svg',
    ),
  ];

  /// Retrieves list of equipment categories and their technical specification schemas from the authoritative backend.
  Future<List<CategoryModel>> getCategories({bool activeOnly = true}) async {
    try {
      final response = await _dio.get(
        ApiConstants.categories,
        queryParameters: {'activeOnly': activeOnly},
      );
      final data = response.data;
      final List<dynamic> items = data is List ? data : (data['items'] ?? []);
      final parsed = items.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
      if (parsed.isNotEmpty) {
        return parsed;
      }
      return defaultSeedCategories;
    } catch (e) {
      debugPrint('getCategories error (falling back to seeds): $e');
      return defaultSeedCategories;
    }
  }

  /// Retrieves a specific category by ID with its specification schema
  Future<CategoryModel> getCategoryById(String id) async {
    final response = await _dio.get(ApiConstants.categoryById(id));
    return CategoryModel.fromJson(response.data as Map<String, dynamic>);
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
