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
    required String type, // 'PreRental', 'PostRental', 'PeriodicMaintenance', 'DamageAssessment'
    required String severity, // 'None', 'Minor', 'Moderate', 'Severe', 'Critical'
    required String conditionNotes,
    List<InspectionPhotoModel> photos = const [],
  }) async {
    final response = await _dio.post(
      ApiConstants.equipmentInspectionLogs(equipmentId),
      data: {
        if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
        'type': type,
        'severity': severity,
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

  /// Retrieves list of equipment categories and their technical specification schemas
  Future<List<CategoryModel>> getCategories({bool activeOnly = true}) async {
    final response = await _dio.get(
      ApiConstants.categories,
      queryParameters: {'activeOnly': activeOnly},
    );
    final data = response.data;
    final List<dynamic> items = data is List ? data : (data['items'] ?? []);
    return items.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
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
