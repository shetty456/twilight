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
  final sentPhones = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.path, 'auth/otp/phone/request/');
    final body = options.data is String
        ? jsonDecode(options.data as String) as Map<String, dynamic>
        : Map<String, dynamic>.from(options.data as Map);
    sentPhones.add(body['phone'] as String);
    return ResponseBody.fromString(
      jsonEncode({'detail': 'OTP sent.', 'dev_otp': '3821'}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  for (final environment in AppEnvironment.values) {
    testWidgets('OTP display in ${environment.name}', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final config = ApiConfig(
        baseUrl: 'https://api.example.com/api/v1/',
        environment: environment,
      );
      final dio = Dio(BaseOptions(baseUrl: config.baseUrl))
        ..httpClientAdapter = _OtpAdapter();
      final adapter = dio.httpClientAdapter as _OtpAdapter;
      final tokens = _Tokens();
      final repository = OriginPhoneAuthRepository(
        DioClient(config, dio: dio, tokenStore: tokens),
        tokens,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiConfigProvider.overrideWithValue(config),
            phoneAuthRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: PhoneSignInPage()),
        ),
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.text('India +91 is prefilled. Replace it for another country.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), '98765 43210');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      expect(adapter.sentPhones, ['+919876543210']);
      expect(find.text('Enter your code'), findsOneWidget);
      expect(
        find.text('We sent a 4-digit code to +919876543210.'),
        findsOneWidget,
      );
      expect(find.text('Resend in 30s'), findsOneWidget);
      expect(
        find.text('Development OTP: 3821'),
        environment.isDevelopment ? findsOneWidget : findsNothing,
      );

      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Resend code'), findsOneWidget);
      await tester.tap(find.text('Resend code'));
      await tester.pumpAndSettle();
      expect(adapter.sentPhones, ['+919876543210', '+919876543210']);
      expect(
        find.text('A new code was sent to +919876543210.'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox());
    });
  }
}
