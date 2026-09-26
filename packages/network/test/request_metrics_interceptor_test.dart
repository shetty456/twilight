import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

class _Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString('ok', 200);

  @override
  void close({bool force = false}) {}
}

void main() {
  test('request metric excludes query values and headers', () async {
    final metrics = <RequestMetric>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
      ..httpClientAdapter = _Adapter()
      ..interceptors.add(RequestMetricsInterceptor(metrics.add));

    await dio.get<dynamic>('/items?secret=private',
        options: Options(headers: {
          'Authorization': 'Bearer private',
        }));

    expect(metrics, hasLength(1));
    expect(metrics.single.method, 'GET');
    expect(metrics.single.path, '/items');
    expect(metrics.single.statusCode, 200);
    expect(metrics.single.succeeded, isTrue);
  });
}
