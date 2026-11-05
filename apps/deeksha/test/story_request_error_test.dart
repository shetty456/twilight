import 'package:core/core.dart';
import 'package:deeksha/config/providers.dart';
import 'package:deeksha/features/listener/listener_library.dart';
import 'package:deeksha/features/stories/library_page.dart';
import 'package:deeksha/features/stories/story_request_error.dart';
import 'package:deeksha/stories/models/story_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

class _MemoryStorage implements StorageService {
  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async {}
  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('Home shows an offline state and retry loads stories', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var attempts = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesProvider.overrideWith((ref) async {
            attempts++;
            if (attempts == 1) {
              throw const NetworkException('No internet connection');
            }
            return const [StorySeries(id: 'one', title: 'A Story')];
          }),
          listenerLibraryProvider.overrideWith(
            (ref) => ListenerLibraryController(Future.value(_MemoryStorage())),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('A Story'), findsOneWidget);
    expect(find.text('No internet connection'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Timeout and server errors have distinct recovery copy', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryRequestError(
            error: const NetworkException('Request timed out'),
            subject: 'episodes',
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    expect(find.text('Connection timed out'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryRequestError(
            error: const NetworkException('Server error', statusCode: 500),
            subject: 'episodes',
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    expect(find.text('Could not load episodes'), findsOneWidget);
    expect(find.text('No internet connection'), findsNothing);
  });
}
