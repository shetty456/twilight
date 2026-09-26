import 'package:auth/auth.dart';
import 'package:dio/dio.dart';

/// Adds Origin JWTs and retries one 401 after a rotating refresh.
class JwtRefreshInterceptor extends Interceptor {
  JwtRefreshInterceptor(this._dio, this._refreshDio, this._tokens);

  static const skipAuthKey = 'skipAuth';
  static const _retriedKey = 'jwtRetried';
  static const _refreshPath = 'auth/token/refresh/';

  final Dio _dio;
  final Dio _refreshDio;
  final AuthTokenStore _tokens;
  Future<AuthTokens?>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] != true) {
      final tokens = await _tokens.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.access}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final original = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        original.extra[skipAuthKey] == true ||
        original.extra[_retriedKey] == true) {
      handler.next(err);
      return;
    }

    try {
      final sent = original.headers['Authorization'];
      final current = await _tokens.read();
      if (current == null || sent == null) {
        handler.next(err);
        return;
      }

      final AuthTokens? tokens;
      if (sent != 'Bearer ${current.access}') {
        // Another request already rotated the token pair.
        tokens = current;
      } else {
        final refresh = _refreshing ??= _refreshTokens(current);
        try {
          tokens = await refresh;
        } finally {
          if (identical(_refreshing, refresh)) _refreshing = null;
        }
      }
      if (tokens == null) {
        handler.next(err);
        return;
      }

      final retry = original.copyWith(
        headers: {
          ...original.headers,
          'Authorization': 'Bearer ${tokens.access}'
        },
        extra: {...original.extra, _retriedKey: true},
      );
      handler.resolve(await _dio.fetch<dynamic>(retry));
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<AuthTokens?> _refreshTokens(AuthTokens previous) async {
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        _refreshPath,
        data: {'refresh': previous.refresh},
      );
      final data = response.data;
      if (data == null ||
          data['access'] is! String ||
          data['refresh'] is! String) {
        return null;
      }
      final rotated = AuthTokens(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
      );
      await _tokens.write(rotated);
      return rotated;
    } on DioException catch (error) {
      if (error.response?.statusCode == 400 ||
          error.response?.statusCode == 401) {
        final current = await _tokens.read();
        if (current?.refresh == previous.refresh) await _tokens.clear();
      }
      return null;
    }
  }
}
