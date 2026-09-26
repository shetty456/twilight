import 'package:dio/dio.dart';

/// Safe request metadata for diagnostics; bodies, headers, and query values are omitted.
class RequestMetric {
  const RequestMetric({
    required this.method,
    required this.path,
    required this.duration,
    this.statusCode,
    this.errorType,
  });

  final String method;
  final String path;
  final Duration duration;
  final int? statusCode;
  final DioExceptionType? errorType;
  bool get succeeded =>
      errorType == null && statusCode != null && statusCode! < 400;
}

/// Attach to a Dio client and forward summaries to an app-owned observer.
class RequestMetricsInterceptor extends Interceptor {
  RequestMetricsInterceptor(this.onMetric);

  final void Function(RequestMetric metric) onMetric;
  final Expando<Stopwatch> _timers = Expando<Stopwatch>();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _timers[options] = Stopwatch()..start();
    handler.next(options);
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    _emit(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _emit(err.requestOptions, err.response?.statusCode, err.type);
    handler.next(err);
  }

  void _emit(RequestOptions options, int? statusCode,
      [DioExceptionType? type]) {
    final timer = _timers[options];
    timer?.stop();
    _timers[options] = null;
    try {
      onMetric(RequestMetric(
        method: options.method,
        path: options.uri.path,
        duration: timer?.elapsed ?? Duration.zero,
        statusCode: statusCode,
        errorType: type,
      ));
    } catch (_) {
      // Diagnostics must never change the outcome of an API request.
    }
  }
}
