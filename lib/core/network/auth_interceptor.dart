import 'package:dio/dio.dart';
import '../services/token_storage_service.dart';

/// Interceptor that attaches the Bearer JWT token and User ID headers to every outgoing request.
class AuthInterceptor extends Interceptor {
  final TokenStorageService _tokenStorage;

  AuthInterceptor(this._tokenStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    final userId = await _tokenStorage.getUserId();
    if (userId != null && userId.isNotEmpty) {
      options.headers['X-User-Id'] = userId;
    }

    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Intercept 401 Unauthorized errors
    if (err.response?.statusCode == 401) {
      // Future hook: clear session or attempt refresh token
    }
    return handler.next(err);
  }
}
