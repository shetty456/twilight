import 'dart:convert';
import 'dart:typed_data';

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:deeksha/config/providers.dart';
import 'package:deeksha/data/origin_repository.dart';
import 'package:deeksha/features/auth/phone_sign_in_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

class _Tokens implements AuthTokenStore {
  @override
  Future<AuthTokens?> read() async => null;

  @override
  Future<void> write(AuthTokens tokens) async {}

  @override
  Future<void> clear() async {}
}

class _OtpAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.path, 'auth/otp/phone/request/');
    return ResponseBody.fromString(
      jsonEncode({'detail': 'OTP sent.', 'dev_otp': '3821'}),
      200,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  for (final environment in AppEnvironment.values) {
    testWidgets('OTP display in ${environment.name}', (tester) async {
      final config = ApiConfig(
        baseUrl: 'https://api.example.com/api/v1/',
        environment: environment,
      );
      final dio = Dio(BaseOptions(baseUrl: config.baseUrl))
        ..httpClientAdapter = _OtpAdapter();
      final tokens = _Tokens();
      final repository = OriginPhoneAuthRepository(
        DioClient(config, dio: dio, tokenStore: tokens),
        tokens,
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          apiConfigProvider.overrideWithValue(config),
          phoneAuthRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: PhoneSignInPage()),
      ));
      await tester.enterText(find.byType(TextField), '+919876543210');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your code'), findsOneWidget);
      expect(
        find.text('Development OTP: 3821'),
        environment.isDevelopment ? findsOneWidget : findsNothing,
      );
    });
  }
}
