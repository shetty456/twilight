import 'dart:convert';
import 'dart:typed_data';

import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:deeksha/app.dart';
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
  testWidgets('phone form validates input and shows the OTP step', (
    tester,
  ) async {
    const config = ApiConfig(
      baseUrl: 'https://api.example.com/api/v1/',
      environment: AppEnvironment.development,
    );
    final dio = Dio(BaseOptions(baseUrl: config.baseUrl))
      ..httpClientAdapter = _OtpAdapter();
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
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    await tester.tap(field);
    await tester.pump();
    expect(tester.widget<TextField>(field).decoration?.errorText, isNull);

    await tester.tap(find.text('Send code'));
    await tester.pump();
    expect(
      tester.widget<TextField>(field).decoration?.errorText,
      'Enter a valid phone number with country code.',
    );

    await tester.enterText(field, '98765 43210');
    await tester.pump();
    expect(tester.widget<TextField>(field).decoration?.errorText, isNull);
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    final activeDigit = tester.widget<Container>(
      find.byKey(const ValueKey('otp-digit-0')),
    );
    final decoration = activeDigit.decoration! as BoxDecoration;
    expect(decoration.border!.top.color, VelaColors.ink);

    await tester.pumpWidget(const SizedBox());
  });

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
      expect(find.text("We'll text you a 4-digit code."), findsOneWidget);
      await tester.enterText(find.byType(TextField), '98765 43210');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      expect(adapter.sentPhones, ['+919876543210']);
      expect(find.text('Enter your code'), findsOneWidget);
      expect(find.text('Code sent to +919876543210'), findsOneWidget);
      expect(find.text('Resend in 30s'), findsOneWidget);
      for (var index = 0; index < 4; index++) {
        expect(find.byKey(ValueKey('otp-digit-$index')), findsOneWidget);
      }
      await tester.enterText(find.byType(TextField), '3821');
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(
        find.text('Development OTP: 3821'),
        environment.isDevelopment ? findsOneWidget : findsNothing,
      );

      await tester.pump(const Duration(seconds: 30));
      expect(find.text('Resend code'), findsOneWidget);
      await tester.tap(find.text('Resend code'));
      await tester.pumpAndSettle();
      expect(adapter.sentPhones, ['+919876543210', '+919876543210']);
      expect(find.text('New code sent to +919876543210'), findsOneWidget);

      await tester.tap(find.text('Change number'));
      await tester.pump();
      expect(find.text('Sign in with phone'), findsOneWidget);
      expect(find.byKey(const ValueKey('otp-digit-0')), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });
  }
}
