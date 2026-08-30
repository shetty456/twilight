import 'package:core/core.dart';
import 'package:dio/dio.dart';

NetworkException mapDioException(DioException e) {
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      const NetworkException('Request timed out'),
    DioExceptionType.badResponse => NetworkException(
        e.response?.data?['detail']?.toString() ?? 'Server error',
        statusCode: e.response?.statusCode,
      ),
    DioExceptionType.connectionError =>
      const NetworkException('No internet connection'),
    _ => NetworkException(e.message ?? 'Unknown network error'),
  };
}
