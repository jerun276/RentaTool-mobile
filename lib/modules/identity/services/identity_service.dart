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
    String? backImagePath,
  }) async {
    final formData = FormData.fromMap({
      'documentType': documentType,
      'documentNumber': documentNumber,
      if (frontImagePath != null)
        'nicDocument': await MultipartFile.fromFile(
          frontImagePath,
          filename: 'nic_front.jpg',
        ),
      if (backImagePath != null)
        'backDocument': await MultipartFile.fromFile(
          backImagePath,
          filename: 'document_back.jpg',
        ),
    });

    await _dio.post(
      ApiConstants.kycSubmission,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  /// Updates KYC approval state in the authorised verification workflow.
  Future<UserModel> updateVerificationStatus({
    required String userId,
    required bool isVerified,
  }) async {
    final response = await _dio.patch(
      ApiConstants.kycVerificationStatus(userId),
      data: {'isVerified': isVerified},
    );
    return UserModel.fromJson(response.data);
  }
}
