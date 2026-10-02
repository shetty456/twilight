import 'dart:convert';
import 'dart:typed_data';

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

class _MemoryTokens implements AuthTokenStore {
  AuthTokens? tokens;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> write(AuthTokens value) async => tokens = value;

  @override
  Future<void> clear() async => tokens = null;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);

  final ResponseBody Function(RequestOptions) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      respond(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Map<String, Object?> value) =>
    ResponseBody.fromString(
      jsonEncode(value),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

void main() {
  const config = ApiConfig(
    baseUrl: 'https://api.example.com/api/v1/',
    environment: AppEnvironment.production,
  );

  test('rotates tokens and retries a 401 once', () async {
    final store = _MemoryTokens()
      ..tokens = const AuthTokens(access: 'old', refresh: 'old-refresh');
    var refreshes = 0;
    var protectedCalls = 0;
    final dio = Dio(BaseOptions(baseUrl: config.baseUrl));
    final refreshDio = Dio(BaseOptions(baseUrl: config.baseUrl));
    dio.httpClientAdapter = _Adapter((options) {
      protectedCalls++;
      expect(options.uri.toString(), 'https://api.example.com/api/v1/items/');
      return options.headers['Authorization'] == 'Bearer new'
          ? _json(200, {'ok': true})
          : _json(401, {'detail': 'expired'});
    });
    refreshDio.httpClientAdapter = _Adapter((options) {
      refreshes++;
      expect(options.path, 'auth/jwt/refresh/');
      expect(options.uri.toString(),
          'https://api.example.com/api/v1/auth/jwt/refresh/');
      return _json(200, {'access': 'new', 'refresh': 'new-refresh'});
    });
    final client = DioClient(
      config,
      tokenStore: store,
      dio: dio,
      refreshDio: refreshDio,
    );

    final response = await client.dio.get<Map<String, dynamic>>('items/');

    expect(response.data?['ok'], true);
    expect(protectedCalls, 2);
    expect(refreshes, 1);
    expect((await store.read())?.refresh, 'new-refresh');
  });

  test('invalid refresh clears the stored pair and does not loop', () async {
    final store = _MemoryTokens()
      ..tokens = const AuthTokens(access: 'old', refresh: 'invalid');
    var protectedCalls = 0;
    final dio = Dio(BaseOptions(baseUrl: config.baseUrl));
    final refreshDio = Dio(BaseOptions(baseUrl: config.baseUrl));
    dio.httpClientAdapter = _Adapter((_) {
      protectedCalls++;
      return _json(401, {'detail': 'expired'});
    });
    refreshDio.httpClientAdapter = _Adapter(
      (_) => _json(401, {'detail': 'invalid refresh'}),
    );
    final client = DioClient(
      config,
      tokenStore: store,
      dio: dio,
      refreshDio: refreshDio,
    );

    await expectLater(
      client.dio.get<Map<String, dynamic>>('items/'),
      throwsA(isA<DioException>()),
    );
    expect(protectedCalls, 1);
    expect(await store.read(), isNull);
  });
}
