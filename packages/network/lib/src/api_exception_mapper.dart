import 'package:core/core.dart';
import 'package:dio/dio.dart';

NetworkException mapDioException(DioException e) {
  final body = e.response?.data;
  final statusCode = e.response?.statusCode;
  final detail = (statusCode ?? 500) < 500 ? _responseMessage(body) : null;
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      const NetworkException('Request timed out'),
    DioExceptionType.badResponse => NetworkException(
        detail ??
            ((statusCode ?? 500) >= 500 ? 'Server error' : 'Request failed'),
        statusCode: statusCode,
      ),
    DioExceptionType.connectionError =>
      const NetworkException('No internet connection'),
    _ => NetworkException(e.message ?? 'Unknown network error'),
  };
}

String? _responseMessage(dynamic body) {
  if (body is String) return body.isEmpty ? null : body;
  if (body is List) {
    for (final item in body) {
      final message = _responseMessage(item);
      if (message != null) return message;
    }
  }
  if (body is Map) {
    final detail = _responseMessage(body['detail']);
    if (detail != null) return detail;
    for (final value in body.values) {
      final message = _responseMessage(value);
      if (message != null) return message;
    }
  }
  return null;
}
