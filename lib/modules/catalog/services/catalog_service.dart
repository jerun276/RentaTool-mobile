import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/equipment_model.dart';
import '../models/inspection_log_model.dart';

final catalogServiceProvider = Provider<CatalogService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return CatalogService(dio);
});

class CatalogService {
  final Dio _dio;

  CatalogService(this._dio);

  Future<List<EquipmentModel>> getEquipment({
    String? search,
    String? categoryId,
  }) async {
    final response = await _dio.get(
      ApiConstants.equipment,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      },
    );

    final data = response.data;
    final List<dynamic> items = data is Map<String, dynamic>
        ? (data['items'] ?? [])
        : (data is List ? data : []);

    return items.map((e) => EquipmentModel.fromJson(e)).toList();
  }

  Future<EquipmentModel> getEquipmentById(String id) async {
    final response = await _dio.get(ApiConstants.equipmentById(id));
    return EquipmentModel.fromJson(response.data);
  }

  Future<EquipmentModel> createEquipment({
    required String title,
    required String description,
    required String categoryId,
    required double dailyRate,
    required double replacementValue,
    required String location,
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
      },
    );
    return EquipmentModel.fromJson(response.data);
  }

  Future<InspectionLogModel> addInspectionLog({
    required String equipmentId,
    required String inspectionType,
    required String notes,
    required bool passed,
    List<String> photoUrls = const [],
  }) async {
    final response = await _dio.post(
      ApiConstants.equipmentInspectionLogs(equipmentId),
      data: {
        'inspectionType': inspectionType,
        'notes': notes,
        'passed': passed,
        'photoUrls': photoUrls,
      },
    );
    return InspectionLogModel.fromJson(response.data);
  }
}
