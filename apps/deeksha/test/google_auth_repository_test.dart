import 'dart:convert';
import 'dart:typed_data';

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:deeksha/data/origin_google_auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

class _Google implements GoogleIdentityProvider {
  GoogleIdentity? identity;
  bool signedOut = false;

  @override
  Future<GoogleIdentity?> authenticate() async => identity;

  @override
  Future<void> signOut() async => signedOut = true;
}

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
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);

  @override
  void close({bool force = false}) {}
}

void main() {
  const config = ApiConfig(
    baseUrl: 'https://api.example.com/api/v1/',
    environment: AppEnvironment.production,
  );

  test('exchanges a Google ID token and stores the Origin session', () async {
    final google = _Google()
      ..identity = const GoogleIdentity(
        idToken: 'google-id-token',
        email: 'listener@example.com',
        displayName: 'Deeksha Listener',
        photoUrl: 'https://example.com/avatar.png',
      );
    final tokens = _Tokens();
    final dio = Dio(BaseOptions(baseUrl: config.baseUrl));
    dio.httpClientAdapter = _Adapter((options) {
      expect(options.path, 'auth/google/token/');
      expect(options.headers['Authorization'], isNull);
      final body = options.data is String
          ? jsonDecode(options.data as String) as Map<String, dynamic>
          : Map<String, dynamic>.from(options.data as Map);
      expect(body, {'id_token': 'google-id-token'});
      return ResponseBody.fromString(
        jsonEncode({'access': 'access-jwt', 'refresh': 'refresh-jwt'}),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    });
    final repository = OriginGoogleAuthRepository(
      DioClient(config, dio: dio, tokenStore: tokens),
      tokens,
      google,
    );

    expect(await repository.signIn(), isTrue);
    expect((await tokens.read())?.access, 'access-jwt');
    expect((await tokens.read())?.refresh, 'refresh-jwt');
    final profile = await repository.signedInProfile();
    expect(profile?.email, 'listener@example.com');
    expect(profile?.displayName, 'Deeksha Listener');
    expect(profile?.photoUrl, 'https://example.com/avatar.png');
    await repository.signOut();
    expect(await tokens.read(), isNull);
    expect(google.signedOut, isTrue);
  });

  test('cancelling Google sign-in leaves the session unchanged', () async {
    final google = _Google();
    final tokens = _Tokens();
    final repository = OriginGoogleAuthRepository(
      DioClient(config, dio: Dio(BaseOptions(baseUrl: config.baseUrl))),
      tokens,
      google,
    );

    expect(await repository.signIn(), isFalse);
    expect(await tokens.read(), isNull);
  });
}
