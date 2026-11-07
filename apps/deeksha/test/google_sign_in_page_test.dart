import 'dart:convert';
import 'dart:typed_data';

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:deeksha/app.dart';
import 'package:deeksha/config/providers.dart';
import 'package:deeksha/features/auth/google_sign_in_page.dart';
import 'package:deeksha/features/auth/phone_sign_in_page.dart';
import 'package:deeksha/features/listener/listener_library.dart';
import 'package:deeksha/features/listener/listener_shell.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:storage/storage.dart';

class _EmptyTokens implements AuthTokenStore {
  @override
  Future<AuthTokens?> read() async => null;

  @override
  Future<void> write(AuthTokens tokens) async {}

  @override
  Future<void> clear() async {}
}

class _MemoryTokens implements AuthTokenStore {
  AuthTokens? value;

  @override
  Future<AuthTokens?> read() async => value;

  @override
  Future<void> write(AuthTokens tokens) async => value = tokens;

  @override
  Future<void> clear() async => value = null;
}

class _Google implements GoogleIdentityProvider {
  @override
  Future<GoogleIdentity?> authenticate() async => const GoogleIdentity(
    idToken: 'google-id-token',
    email: 'listener@example.com',
    displayName: 'Deeksha Listener',
  );

  @override
  Future<void> signOut() async {}
}

class _MemoryStorage implements StorageService {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> clear() async => values.clear();
}

class _Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == 'auth/google/token/') {
      expect(options.data, {'id_token': 'google-id-token'});
      return _json({'access': 'access-jwt', 'refresh': 'refresh-jwt'});
    }
    if (options.path == 'stories/series/') return _json([]);
    throw StateError('Unexpected request: ${options.path}');
  }

  ResponseBody _json(Object data) => ResponseBody.fromString(
    jsonEncode(data),
    200,
    headers: {Headers.contentTypeHeader: ['application/json']},
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('Google sign-in opens the profile with account details', (
    tester,
  ) async {
    const config = ApiConfig(
      baseUrl: 'https://api.example.com/api/v1/',
      environment: AppEnvironment.development,
    );
    final tokens = _MemoryTokens();
    final dio = Dio(BaseOptions(baseUrl: config.baseUrl))
      ..httpClientAdapter = _Adapter();
    final library = ListenerLibraryController(Future.value(_MemoryStorage()));
    await tester.pumpWidget(ProviderScope(
      overrides: [
        apiConfigProvider.overrideWithValue(config),
        authTokenStoreProvider.overrideWithValue(tokens),
        dioClientProvider.overrideWithValue(
          DioClient(config, dio: dio, tokenStore: tokens),
        ),
        googleIdentityProvider.overrideWithValue(_Google()),
        listenerLibraryProvider.overrideWith((ref) => library),
      ],
      child: const DeekshaApp(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('google-sign-in')));
    await tester.pumpAndSettle();
    expect(find.byType(ListenerShell), findsOneWidget);
    expect(tokens.value?.access, 'access-jwt');

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Deeksha Listener'), findsOneWidget);
    expect(find.text('listener@example.com'), findsOneWidget);
  });

  testWidgets('logged-out app opens Google sign-in by default', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiConfigProvider.overrideWithValue(
            const ApiConfig(
              baseUrl: 'https://api.example.com/api/v1/',
              environment: AppEnvironment.development,
            ),
          ),
          authTokenStoreProvider.overrideWithValue(_EmptyTokens()),
        ],
        child: const DeekshaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GoogleSignInPage), findsOneWidget);
    expect(find.byType(PhoneSignInPage), findsNothing);
  });

  for (final height in [568.0, 844.0]) {
    testWidgets('Google sign-in branding and bottom button fit at $height', (
      tester,
    ) async {
      tester.view.physicalSize = Size(390, height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: GoogleSignInPage())),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byKey(const ValueKey('copy-google-id-token')), findsNothing);
      final button = find.byKey(const ValueKey('google-sign-in'));
      expect(button, findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Continue with Google')).style?.color,
        const Color(0xFF202124),
      );
      expect(tester.getBottomLeft(button).dy, lessThan(height - 20));
      expect(tester.getBottomLeft(button).dy, greaterThan(height * 0.55));
    });
  }
}
