import 'package:core/core.dart';
import 'package:dio/dio.dart';

NetworkException mapDioException(DioException e) {
  final body = e.response?.data;
  final detail = body is Map ? body['detail'] : null;
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      const NetworkException('Request timed out'),
    DioExceptionType.badResponse => NetworkException(
        detail is String ? detail : 'Server error',
        statusCode: e.response?.statusCode,
      ),
    DioExceptionType.connectionError =>
      const NetworkException('No internet connection'),
    _ => NetworkException(e.message ?? 'Unknown network error'),
  };
}
