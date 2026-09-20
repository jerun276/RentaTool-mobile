import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/user_model.dart';
import '../models/trust_score_model.dart';

final identityServiceProvider = Provider<IdentityService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return IdentityService(dio);
});

class IdentityService {
  final Dio _dio;

  IdentityService(this._dio);

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {
        'email': email.trim(),
        'password': password,
      },
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
  }) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'phoneNumber': phoneNumber.replaceAll(RegExp(r'[\s-]'), ''),
        'role': role,
      },
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<UserModel> getUserProfile(String userId) async {
    final response = await _dio.get(ApiConstants.userById(userId));
    return UserModel.fromJson(response.data);
  }

  Future<TrustScoreModel> getTrustScore(String userId) async {
    final response = await _dio.get(ApiConstants.trustScore(userId));
    return TrustScoreModel.fromJson(response.data);
  }

  Future<void> submitKyc({
    required String documentNumber,
    required String documentType,
    String? frontImagePath,
  }) async {
    final formData = FormData.fromMap({
      'documentType': documentType,
      'documentNumber': documentNumber,
      if (frontImagePath != null)
        'nicDocument': await MultipartFile.fromFile(
          frontImagePath,
          filename: 'nic_front.jpg',
        ),
    });

    await _dio.post(
      ApiConstants.kycSubmission,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
