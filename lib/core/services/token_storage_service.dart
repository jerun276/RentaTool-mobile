import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStorageServiceProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});

/// Service responsible for persisting and reading sensitive session tokens and credentials.
class TokenStorageService {
  final FlutterSecureStorage _storage;

  TokenStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _keyAccessToken = 'rentatool_access_token';
  static const String _keyRefreshToken = 'rentatool_refresh_token';
  static const String _keyUserId = 'rentatool_user_id';
  static const String _keyUserRole = 'rentatool_user_role';
  static const String _keyUserName = 'rentatool_user_name';
  static const String _keyUserEmail = 'rentatool_user_email';

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<void> saveUser({
    required String userId,
    required String role,
    String? name,
    String? email,
  }) async {
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUserRole, value: role);
    if (name != null) await _storage.write(key: _keyUserName, value: name);
    if (email != null) await _storage.write(key: _keyUserEmail, value: email);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: _keyUserRole);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: _keyUserName);
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  String _profilePhotoKey(String userId) => 'rentatool_profile_photo_$userId';

  Future<void> saveProfilePhoto(String userId, String path) async {
    await _storage.write(key: _profilePhotoKey(userId), value: path);
  }

  Future<String?> getProfilePhoto(String userId) async {
    return _storage.read(key: _profilePhotoKey(userId));
  }

  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
