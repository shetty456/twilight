import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';
import 'package:deeksha/config/providers.dart';
import 'package:deeksha/features/listener/listener_library.dart';
import 'package:deeksha/features/listener/listener_shell.dart';
import 'package:deeksha/stories/models/story_models.dart';

class _MemoryStorage implements StorageService {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<void> clear() async {
    values.clear();
  }
}

void main() {
  testWidgets('Profile contains saved stories and recent listening', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final libraryController = ListenerLibraryController(
      Future.value(_MemoryStorage()),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesProvider.overrideWith(
            (ref) async => const [
              StorySeries(id: 'one', title: 'Evening Stories'),
            ],
          ),
          listenerLibraryProvider.overrideWith((ref) => libraryController),
          signedInPhoneProvider.overrideWith((ref) async => '+919876543210'),
        ],
        child: const MaterialApp(home: ListenerShell()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Featured'), findsOneWidget);
    tester.view.physicalSize = const Size(320, 700);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Evening Stories'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Your profile'), findsOneWidget);
    expect(find.text('+919876543210'), findsOneWidget);
    expect(find.text('Saved stories'), findsOneWidget);
    expect(tester.widget<CircleAvatar>(find.byType(CircleAvatar)).radius, 46);
    expect(find.text('Profile completion'), findsNothing);
    expect(find.text('My Library'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Sign out'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Sign out'), findsOneWidget);

    await tester.ensureVisible(find.text('Explore stories'));
    await tester.tap(find.text('Explore stories'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save to My Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Saved series'), findsOneWidget);
    expect(find.text('Evening Stories'), findsOneWidget);

    await libraryController.recordListening(
      series: const StorySeries(id: 'one', title: 'Evening Stories'),
      episode: const StoryEpisode(
        id: 'chapter-one',
        title: 'First Chapter',
        seriesId: 'one',
        episodeNumber: 1,
      ),
      position: const Duration(seconds: 30),
      duration: const Duration(minutes: 5),
    );
    await tester.pumpAndSettle();
    expect(find.text('Continue listening'), findsOneWidget);
    expect(find.text('Episode 1 · First Chapter'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Continue listening'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Continue listening')).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('featured-story'))).dy,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
