import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storage/storage.dart';
import 'package:deeksha/features/listener/listener_library.dart';
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

class _FailingStorage implements StorageService {
  int writes = 0;

  @override
  Future<String?> read(String key) async => throw StateError('Read failed');
  @override
  Future<void> write(String key, String value) async {
    writes++;
  }

  @override
  Future<void> delete(String key) async {}
  @override
  Future<void> clear() async {}
}

class _FailingWriteStorage extends _MemoryStorage {
  @override
  Future<void> write(String key, String value) async {
    throw StateError('Write failed');
  }
}

void main() {
  const series = StorySeries(
    id: 'series-1',
    title: 'Evening Stories',
    thumbnail: 'stories/images/art.jpg',
    thumbnailUrl: 'https://example.com/art.jpg?signature=example',
  );
  const episode = StoryEpisode(
    id: 'episode-1',
    seriesId: 'series-1',
    episodeNumber: 1,
    title: 'A Beginning',
  );

  test(
    'saved artwork and recent playback survive a controller restart',
    () async {
      final storage = _MemoryStorage();
      final first = ListenerLibraryController(Future.value(storage));
      await first.ready;
      await first.toggleSaved(series);
      await first.recordListening(
        series: series,
        episode: episode,
        position: const Duration(seconds: 42),
        duration: const Duration(minutes: 5),
      );
      first.dispose();

      final restored = ListenerLibraryController(Future.value(storage));
      await restored.ready;
      final library = restored.state.valueOrNull!;
      expect(library.isSaved(series.id), isTrue);
      expect(library.saved.single.thumbnail, series.thumbnail);
      expect(library.saved.single.thumbnailUrl, series.thumbnailUrl);
      expect(library.recent.single.episode.id, episode.id);
      expect(library.recent.single.positionSeconds, 42);

      await restored.removeRecent(episode.id);
      expect(restored.state.valueOrNull!.recent, isEmpty);
      await restored.clear();
      expect(restored.state.valueOrNull!.saved, isEmpty);
      restored.dispose();
    },
  );

  test(
    'a failed library read remains an error and cannot overwrite data',
    () async {
      final storage = _FailingStorage();
      final controller = ListenerLibraryController(Future.value(storage));
      await controller.ready;

      expect(controller.state.hasError, isTrue);
      await controller.toggleSaved(series);
      expect(storage.writes, 0);
      controller.dispose();
    },
  );

  test('a failed library write is shown as an error', () async {
    final controller = ListenerLibraryController(
      Future.value(_FailingWriteStorage()),
    );
    await controller.ready;
    await controller.toggleSaved(series);

    expect(controller.state.hasError, isTrue);
    controller.dispose();
  });
}
