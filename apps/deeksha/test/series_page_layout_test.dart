import 'package:deeksha/config/providers.dart';
import 'package:deeksha/features/listener/listener_library.dart';
import 'package:deeksha/features/stories/series_page.dart';
import 'package:deeksha/features/stories/story_artwork.dart';
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
  testWidgets('Story details uses a compact poster and leaves scroll space', (
    tester,
  ) async {
    const description =
        'A gentle journey through the quiet forest, where every path leads '
        'to another surprising encounter and every evening brings a new '
        'chapter to enjoy with the whole family.';
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          episodesProvider.overrideWith(
            (ref, id) async => const [
              StoryEpisode(
                id: 'chapter-one',
                title: 'First Chapter',
                seriesId: 'one',
                episodeNumber: 1,
              ),
            ],
          ),
          listenerLibraryProvider.overrideWith(
            (ref) => ListenerLibraryController(Future.value(_MemoryStorage())),
          ),
        ],
        child: const MaterialApp(
          home: SeriesPage(
            series: StorySeries(
              id: 'one',
              title: 'A Story',
              description: description,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final poster = find.byType(StoryArtwork).first;
    final size = tester.getSize(poster);
    expect(size, const Size(80, 100));
    expect(size.width / size.height, closeTo(4 / 5, 0.001));
    expect(
      tester.getTopLeft(find.text('A Story')).dx,
      greaterThan(tester.getTopRight(poster).dx),
    );
    expect(find.text('Story details'), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(description)).dy,
      greaterThan(tester.getBottomLeft(find.text('A Story')).dy),
    );
    expect(tester.widget<Text>(find.text(description)).maxLines, 3);
    await tester.tap(find.text('Read more'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text(description)).maxLines, isNull);
    expect(find.text('Read less'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    final episode = find.byType(ListTile).last;
    expect(700 - tester.getBottomLeft(episode).dy, greaterThan(50));
    expect(tester.takeException(), isNull);
  });
}
