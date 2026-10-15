import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/cloudinary_service.dart';
import '../models/user_model.dart';
import '../models/trust_score_model.dart';
import '../models/kyc_submission_model.dart';

final identityServiceProvider = Provider<IdentityService>((ref) {
  final dio = ref.watch(apiClientProvider);
  final cloudinary = ref.watch(cloudinaryServiceProvider);
  return IdentityService(dio, cloudinary: cloudinary);
});

class IdentityService {
  final Dio _dio;
  final CloudinaryService _cloudinary;

  IdentityService(this._dio, {CloudinaryService? cloudinary})
      : _cloudinary = cloudinary ?? CloudinaryService();

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

  Future<AuthResponse> refreshToken(String token) async {
    final response = await _dio.post(
      ApiConstants.refreshToken,
      data: {
        'refreshToken': token.trim(),
      },
      options: Options(extra: {'skipAuth': true}),
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

  Future<UserModel> updateProfile({
    required String userId,
    required String name,
    required String phoneNumber,
    String? profilePhotoUrl,
  }) async {
    final response = await _dio.patch(
      '${ApiConstants.userById(userId)}/profile',
      data: {
        'name': name.trim(),
        'phoneNumber': phoneNumber.replaceAll(RegExp(r'[\s-]'), ''),
        if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      },
    );
    return UserModel.fromJson(response.data);
  }

  Future<TrustScoreModel> getTrustScore(String userId) async {
    final response = await _dio.get(ApiConstants.trustScore(userId));
    return TrustScoreModel.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getPublicProfile(String userId) async {
    final response = await _dio.get('${ApiConstants.userById(userId)}/public-profile');
    return response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : {};
  }

  Future<void> submitKyc({
    required String documentNumber,
    required String documentType,
    String? frontImagePath,
    String? backImagePath,
  }) async {
    if (frontImagePath == null || frontImagePath.isEmpty) {
      throw Exception('Front photo of your identification document is required.');
    }
    final frontUrl = await _cloudinary.uploadImage(frontImagePath, folder: 'rentatool/kyc');
    String? backUrl;

    if (backImagePath != null && backImagePath.isNotEmpty) {
      backUrl = await _cloudinary.uploadImage(backImagePath, folder: 'rentatool/kyc');
    }

    try {
      await _dio.post(
        ApiConstants.kycSubmission,
        data: {
          'documentType': documentType,
          'documentNumber': documentNumber,
          'frontImageUrl': frontUrl,
          if (backUrl != null) 'backImageUrl': backUrl,
        },
      );
    } on DioException catch (e) {
      String message = 'Failed to submit document.';
      if (e.response?.data is Map) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data['message'] != null && data['message'].toString().isNotEmpty) {
          message = data['message'].toString();
        } else if (data['detail'] != null && data['detail'].toString().isNotEmpty) {
          message = data['detail'].toString();
        } else if (data['title'] != null && data['title'].toString().isNotEmpty) {
          message = data['title'].toString();
        }
      } else if (e.response?.statusCode == 409) {
        message = 'This document number is already registered, or your account already has an active verification.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }
      throw Exception(message);
    }
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

  /// Retrieves the current user's KYC submission if one exists.
  Future<KycSubmissionModel?> getMyKycSubmission(String userId) async {
    try {
      final response = await _dio.get('${ApiConstants.users}/$userId/kyc-submission');
      if (response.data != null) {
        return KycSubmissionModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }
}
