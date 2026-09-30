import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});

/// Service responsible for uploading photographic inspection logs, KYC identity documents,
/// and equipment images directly to Cloudinary via unsigned upload presets.
class CloudinaryService {
  final Dio _dio;

  CloudinaryService({Dio? dio}) : _dio = dio ?? Dio();

  /// Retrieve Cloudinary cloud name from compile-time defines or .env
  static String get cloudName {
    const defineVal = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
    if (defineVal.isNotEmpty) return defineVal;
    try {
      if (dotenv.isInitialized) {
        return dotenv.maybeGet('CLOUDINARY_CLOUD_NAME') ?? '';
      }
    } catch (_) {}
    return '';
  }

  /// Retrieve Cloudinary upload preset from compile-time defines or .env
  static String get uploadPreset {
    const defineVal = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');
    if (defineVal.isNotEmpty) return defineVal;
    try {
      if (dotenv.isInitialized) {
        return dotenv.maybeGet('CLOUDINARY_UPLOAD_PRESET') ?? '';
      }
    } catch (_) {}
    return '';
  }

  /// Returns true if valid, non-placeholder credentials have been configured.
  static bool get isConfigured {
    final cName = cloudName.trim();
    final preset = uploadPreset.trim();
    return cName.isNotEmpty &&
        cName != 'your_cloudinary_cloud_name' &&
        preset.isNotEmpty &&
        preset != 'rentatool_preset';
  }

  /// Uploads a single image to Cloudinary and returns its secure HTTPS URL.
  /// If credentials are not yet configured, returns a fallback demonstration CDN URL.
  Future<String> uploadImage(
    String filePath, {
    String? folder,
  }) async {
    // If the path is already a network URL, return it directly
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }

    if (!isConfigured) {
      final fileName = filePath.split(Platform.pathSeparator).last;
      debugPrint(
        '[CloudinaryService] Real credentials not set in .env. Using mock CDN URL for $fileName.',
      );
      return 'https://res.cloudinary.com/rentatool-demo/image/upload/v1/${folder ?? 'uploads'}/$fileName';
    }

    final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'upload_preset': uploadPreset,
      if (folder != null && folder.isNotEmpty) 'folder': folder,
    });

    final response = await _dio.post(
      url,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final secureUrl = response.data['secure_url'] as String?;
      if (secureUrl != null && secureUrl.isNotEmpty) {
        return secureUrl;
      }
    }

    throw Exception('Cloudinary upload failed: ${response.statusMessage}');
  }

  /// Uploads a list of image file paths in parallel and returns their URLs.
  Future<List<String>> uploadMultipleImages(
    List<String> filePaths, {
    String? folder,
  }) async {
    final futures = filePaths.map((path) => uploadImage(path, folder: folder));
    return Future.wait(futures);
  }
}
