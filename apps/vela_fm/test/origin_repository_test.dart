import 'dart:convert';
import 'dart:typed_data';

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vela_fm/data/origin_repository.dart';
import 'package:network/network.dart';

class _Tokens implements AuthTokenStore {
  AuthTokens? value;

  @override
  Future<AuthTokens?> read() async => value;
  @override
  Future<void> write(AuthTokens tokens) async => value = tokens;
  @override
  Future<void> clear() async => value = null;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      respond(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body) => ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );

void main() {
  const config = ApiConfig(
    baseUrl: 'https://api.example.com/api/v1/',
    environment: AppEnvironment.production,
  );

  test('phone OTP uses Origin routes and stores returned JWT pair', () async {
    final tokens = _Tokens();
    final dio = Dio(BaseOptions(baseUrl: config.baseUrl));
    dio.httpClientAdapter = _Adapter((options) {
      expect(options.headers['Authorization'], isNull);
      final body = options.data is String
          ? jsonDecode(options.data as String) as Map<String, dynamic>
          : Map<String, dynamic>.from(options.data as Map);
      expect(body['phone'], '+919876543210');
      if (options.path == 'auth/otp/phone/request/') {
        return _json({'detail': 'OTP sent.'});
      }
      expect(options.path, 'auth/otp/phone/verify/');
      expect(body['otp'], '3821');
      return _json({'access': 'access-jwt', 'refresh': 'refresh-jwt'});
    });
    final repository = OriginPhoneAuthRepository(
      DioClient(config, dio: dio, tokenStore: tokens), tokens,
    );

    await repository.requestCode('+919876543210');
    await repository.verifyCode('+919876543210', '3821');

    expect((await tokens.read())?.access, 'access-jwt');
    expect((await tokens.read())?.refresh, 'refresh-jwt');
  });

  test('story repository decodes Origin series, episodes, and media', () async {
    final tokens = _Tokens()
      ..value = const AuthTokens(access: 'access-jwt', refresh: 'refresh-jwt');
    final dio = Dio(BaseOptions(baseUrl: config.baseUrl));
    dio.httpClientAdapter = _Adapter((options) {
      expect(options.headers['Authorization'], 'Bearer access-jwt');
      if (options.path == 'stories/series/') {
        return _json([
          {'id': 'series-1', 'title': 'Gentle Evenings',
            'description': 'A calming story.', 'status': 'active'},
        ]);
      }
      if (options.path == 'stories/series/series-1/episodes/') {
        return _json([
          {'id': 'episode-1', 'series_id': 'series-1',
            'episode_number': 1, 'title': 'A Beginning',
            'script': 'Once upon a time', 'audio_key': 'stories/audio/one.mp3'},
        ]);
      }
      expect(options.path, 'stories/episodes/episode-1/media/');
      return _json({'episode_id': 'episode-1',
        'audio_url': 'https://assets.example/one.mp3', 'expires_in': 3600});
    });
    final repository = OriginStoriesRepository(
      DioClient(config, dio: dio, tokenStore: tokens),
    );

    final series = await repository.series();
    final episodes = await repository.episodes(series.single.id);
    final media = await repository.media(episodes.single.id);

    expect(series.single.title, 'Gentle Evenings');
    expect(episodes.single.audioKey, 'stories/audio/one.mp3');
    expect(media.audioUrl, 'https://assets.example/one.mp3');
  });
}
