import 'dart:async';
import 'package:dio/dio.dart';
import '../services/token_storage_service.dart';

/// Broadcasts when the backend rejects the stored session (expired/invalid JWT).
class SessionEvents {
  SessionEvents._();
  static final StreamController<void> _expired = StreamController<void>.broadcast();
  static Stream<void> get onExpired => _expired.stream;
  static void notifyExpired() {
    if (!_expired.isClosed) _expired.add(null);
  }
}

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
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Auto-logout on 401 for authenticated requests (not login/register attempts)
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      final isAuthCall = path.contains('/auth/login') || path.contains('/auth/register');
      if (!isAuthCall && await _tokenStorage.hasToken()) {
        await _tokenStorage.clearAll();
        SessionEvents.notifyExpired();
      }
    }
    return handler.next(err);
  }
}
