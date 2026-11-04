import 'package:deeksha/config/providers.dart';
import 'package:deeksha/features/listener/listener_library.dart';
import 'package:deeksha/features/listener/listener_shell.dart';
import 'package:deeksha/features/stories/story_artwork.dart';
import 'package:deeksha/features/stories/story_cards.dart';
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
  testWidgets('story cards fit narrow screens and See all opens search', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesProvider.overrideWith(
            (ref) async => const [
              StorySeries(id: 'one', title: 'Evening Stories'),
              StorySeries(id: 'two', title: 'The Quiet Path'),
              StorySeries(id: 'three', title: 'Moonlit Moments'),
              StorySeries(id: 'four', title: 'The Lotus Lake'),
            ],
          ),
          listenerLibraryProvider.overrideWith(
            (ref) => ListenerLibraryController(Future.value(_MemoryStorage())),
          ),
        ],
        child: const MaterialApp(home: ListenerShell()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Stories for you'), findsOneWidget);
    expect(find.text('See all'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final posterArtwork = find.descendant(
      of: find.byType(StoryPosterCard).first,
      matching: find.byType(StoryArtwork),
    );
    final posterSize = tester.getSize(posterArtwork);
    expect(posterSize.width / posterSize.height, closeTo(9 / 16, 0.001));
    expect(
      tester.getTopRight(find.byType(StoryPosterCard).at(2)).dx,
      lessThanOrEqualTo(370),
    );

    tester.view.physicalSize = const Size(320, 700);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopRight(find.byType(StoryPosterCard).at(2)).dx,
      lessThanOrEqualTo(300),
    );

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
    expect(find.text('Search'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
