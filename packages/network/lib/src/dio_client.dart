import 'package:core/core.dart';
import 'package:dio/dio.dart';

import 'api_config.dart';
import 'auth_interceptor.dart';

class DioClient {
  DioClient(ApiConfig config, {Future<String?> Function()? getToken}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );

    if (getToken != null) {
      _dio.interceptors.add(AuthInterceptor(getToken));
    }

    if (config.environment.isDevelopment) {
      _dio.interceptors
          .add(LogInterceptor(requestBody: true, responseBody: true));
    }
  }

  late final Dio _dio;

  Dio get dio => _dio;
}
