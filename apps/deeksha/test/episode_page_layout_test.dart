import 'package:deeksha/config/providers.dart';
import 'package:deeksha/data/origin_repository.dart';
import 'package:deeksha/features/listener/listener_library.dart';
import 'package:deeksha/features/stories/episode_page.dart';
import 'package:deeksha/stories/models/story_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';
import 'package:core/core.dart';

class _OfflineStoriesRepository implements OriginStoriesRepository {
  @override
  Future<List<StorySeries>> series() async => [];
  @override
  Future<List<StoryEpisode>> episodes(String seriesId) async => [];
  @override
  Future<EpisodeMedia> media(String episodeId) async =>
      throw const NetworkException('No internet connection');
  @override
  Future<void> saveProgress(String episodeId, double seconds) async {}
}

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
  testWidgets('player shows an offline retry without overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storiesRepositoryProvider.overrideWithValue(
            _OfflineStoriesRepository(),
          ),
          listenerLibraryProvider.overrideWith(
            (ref) => ListenerLibraryController(Future.value(_MemoryStorage())),
          ),
        ],
        child: const MaterialApp(
          home: EpisodePage(
            episode: StoryEpisode(
              id: 'episode-1',
              title: 'A Beginning',
              seriesId: 'series-1',
              episodeNumber: 1,
            ),
            series: StorySeries(id: 'series-1', title: 'A Story'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Retry audio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'leaving the player route does not dispose the playback session',
    (tester) async {
      const episode = StoryEpisode(
        id: 'episode-1',
        title: 'A Beginning',
        seriesId: 'series-1',
        episodeNumber: 1,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            episodesProvider.overrideWith((ref, id) async => [episode]),
            storiesRepositoryProvider.overrideWithValue(
              _OfflineStoriesRepository(),
            ),
            listenerLibraryProvider.overrideWith(
              (ref) =>
                  ListenerLibraryController(Future.value(_MemoryStorage())),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EpisodePage(
                        episode: episode,
                        series: StorySeries(id: 'series-1', title: 'A Story'),
                      ),
                    ),
                  ),
                  child: const Text('Open player'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open player'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('player fits a short screen and opens details from icons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const episode = StoryEpisode(
      id: 'episode-1',
      title: 'A Beginning',
      seriesId: 'series-1',
      episodeNumber: 1,
      script: 'Once upon a time',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          episodesProvider.overrideWith((ref, id) async => [episode]),
          storiesRepositoryProvider.overrideWithValue(
            _OfflineStoriesRepository(),
          ),
          listenerLibraryProvider.overrideWith(
            (ref) => ListenerLibraryController(Future.value(_MemoryStorage())),
          ),
        ],
        child: const MaterialApp(
          home: EpisodePage(
            episode: episode,
            series: StorySeries(id: 'series-1', title: 'A Story'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Scrollable), findsNothing);
    expect(find.textContaining('Playlist ·'), findsNothing);
    expect(find.text('Read this story'), findsNothing);
    expect(find.byTooltip('Episodes'), findsOneWidget);
    expect(find.byTooltip('Read story'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Read story'));
    await tester.pump();
    expect(find.text('Once upon a time'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
