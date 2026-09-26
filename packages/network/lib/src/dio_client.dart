import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';

import 'api_config.dart';
import 'auth_interceptor.dart';
import 'jwt_refresh_interceptor.dart';

class DioClient {
  DioClient(
    ApiConfig config, {
    Future<String?> Function()? getToken,
    AuthTokenStore? tokenStore,
    Dio? dio,
    Dio? refreshDio,
  }) {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: config.baseUrl,
            connectTimeout: config.connectTimeout,
            receiveTimeout: config.receiveTimeout,
            headers: {'Content-Type': 'application/json'},
          ),
        );

    if (tokenStore != null) {
      _dio.interceptors.add(JwtRefreshInterceptor(
        _dio,
        refreshDio ?? Dio(_dio.options),
        tokenStore,
      ));
    } else if (getToken != null) {
      _dio.interceptors.add(AuthInterceptor(getToken));
    }

    if (config.environment.isDevelopment) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
      ));
    }
  }

  late final Dio _dio;

  Dio get dio => _dio;
}
