import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
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
/// Automatically handles transparent refresh token rotation on HTTP 401 Unauthorized errors.
class AuthInterceptor extends Interceptor {
  final TokenStorageService _tokenStorage;
  Completer<String?>? _refreshCompleter;

  AuthInterceptor(this._tokenStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final bool skipAuth = options.extra['skipAuth'] == true;
    if (!skipAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      final userId = await _tokenStorage.getUserId();
      if (userId != null && userId.isNotEmpty && !options.headers.containsKey('X-User-Id')) {
        options.headers['X-User-Id'] = userId;
      }
    }

    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';

    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      final isAuthCall = path.contains('/auth/login') ||
          path.contains('/auth/register') ||
          path.contains('/auth/refresh');

      if (!isAuthCall && await _tokenStorage.hasToken()) {
        final newAccessToken = await _getRefreshedToken();

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          // Retry original request with newly refreshed Bearer token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newAccessToken';

          try {
            final retryDio = Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: ApiConstants.connectTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
              ),
            );
            final response = await retryDio.fetch(options);
            return handler.resolve(response);
          } catch (retryError) {
            if (retryError is DioException) {
              return handler.next(retryError);
            }
          }
        }

        // If refresh failed or was revoked, clear all and notify session expired
        await _tokenStorage.clearAll();
        SessionEvents.notifyExpired();
      }
    }
    return handler.next(err);
  }

  Future<String?> _getRefreshedToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();
    try {
      final token = await _performTokenRefresh();
      _refreshCompleter!.complete(token);
      return token;
    } catch (_) {
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<String?> _performTokenRefresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          responseType: ResponseType.json,
        ),
      );

      final response = await refreshDio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken.trim()},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final newAccessToken = data['accessToken']?.toString();
        final newRefreshToken = data['refreshToken']?.toString();

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await _tokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          return newAccessToken;
        }
      }
    } catch (_) {}

    return null;
  }
}
