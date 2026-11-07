import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twilight_audio/twilight_audio.dart';

import '../../config/providers.dart';
import '../../data/origin_repository.dart';
import '../../stories/models/story_models.dart';
import '../listener/listener_library.dart';

final storyPlaybackProvider = Provider<StoryPlaybackSession>((ref) {
  final session = StoryPlaybackSession(
    repository: ref.read(storiesRepositoryProvider),
    library: ref.read(listenerLibraryProvider.notifier),
    resumePositionSeconds: (episodeId) =>
        ref
            .read(listenerLibraryProvider)
            .valueOrNull
            ?.recent
            .where((item) => item.episode.id == episodeId)
            .firstOrNull
            ?.positionSeconds ??
        0,
  );
  ref.onDispose(session.dispose);
  return session;
});

class StoryPlaybackSession {
  StoryPlaybackSession({
    required this.repository,
    required this.library,
    this.resumePositionSeconds,
    BackgroundAudioQueue? queue,
  }) {
    this.queue =
        queue ??
        BackgroundAudioQueue(
          resolveUrl: (item) async {
            final media = await repository.media(item.id);
            final url = media.audioUrl;
            if (url == null || url.isEmpty) {
              throw StateError('Audio is being prepared for this episode.');
            }
            return Uri.parse(url);
          },
          onPosition: _onPosition,
          onItemFinished: _onItemFinished,
        );
  }

  final OriginStoriesRepository repository;
  final ListenerLibraryController library;
  final double Function(String episodeId)? resumePositionSeconds;
  late final BackgroundAudioQueue queue;
  StorySeries? series;
  List<StoryEpisode> episodes = const [];
  int _lastLocalSave = 0;
  int _lastRemoteSave = 0;
  int _loadSerial = 0;

  StoryEpisode? get currentEpisode {
    final id = queue.currentItem?.id;
    if (id == null) return null;
    for (final episode in episodes) {
      if (episode.id == id) return episode;
    }
    return null;
  }

  Future<void> open(
    StorySeries nextSeries,
    StoryEpisode episode, {
    List<StoryEpisode>? knownEpisodes,
    bool autoplay = false,
  }) async {
    if (series?.id == nextSeries.id && queue.currentItem?.id == episode.id) {
      if (autoplay) queue.play();
      return;
    }
    final serial = ++_loadSerial;
    _saveCurrent();
    series = nextSeries;
    List<StoryEpisode> ordered;
    if (knownEpisodes != null && knownEpisodes.isNotEmpty) {
      ordered = [...knownEpisodes];
    } else {
      try {
        ordered = await repository.episodes(nextSeries.id);
      } catch (_) {
        ordered = [episode];
      }
    }
    if (serial != _loadSerial) return;
    if (!ordered.any((item) => item.id == episode.id)) ordered.add(episode);
    ordered.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
    episodes = List.unmodifiable(ordered);
    _lastLocalSave = 0;
    _lastRemoteSave = 0;
    final resumeAt = Duration(
      milliseconds: ((resumePositionSeconds?.call(episode.id) ?? 0) * 1000)
          .round(),
    );
    await queue.load(
      [for (final item in episodes) _toQueueItem(nextSeries, item)],
      initialIndex: episodes.indexWhere((item) => item.id == episode.id),
      initialPosition: resumeAt,
      autoplay: autoplay,
    );
  }

  AudioQueueItem _toQueueItem(StorySeries story, StoryEpisode episode) {
    final artwork = story.thumbnailUrl ?? story.thumbnail;
    final artUri = artwork == null ? null : Uri.tryParse(artwork);
    return AudioQueueItem(
      id: episode.id,
      title: episode.title,
      album: story.title,
      artUri: artUri?.hasScheme == true ? artUri : null,
      duration: episode.audioDuration == null
          ? null
          : Duration(seconds: episode.audioDuration!),
    );
  }

  void _onPosition(AudioQueueItem item, Duration position, Duration duration) {
    final story = series;
    final episode = currentEpisode;
    if (story == null || episode == null || episode.id != item.id) return;
    if (position.inSeconds - _lastLocalSave >= 10) {
      _lastLocalSave = position.inSeconds;
      unawaited(
        library
            .recordListening(
              series: story,
              episode: episode,
              position: position,
              duration: duration,
            )
            .catchError((Object _) {}),
      );
    }
    if (position.inSeconds - _lastRemoteSave >= 30) {
      _lastRemoteSave = position.inSeconds;
      unawaited(
        repository
            .saveProgress(episode.id, position.inMilliseconds / 1000)
            .catchError((Object _) {}),
      );
    }
  }

  void _onItemFinished(AudioQueueItem item) {
    _lastLocalSave = 0;
    _lastRemoteSave = 0;
    final atEnd =
        queue.duration > Duration.zero &&
        queue.position >= queue.duration - const Duration(seconds: 3);
    if (atEnd) {
      unawaited(library.removeRecent(item.id).catchError((Object _) {}));
    } else {
      _saveCurrent();
    }
  }

  void _saveCurrent() {
    final story = series;
    final episode = currentEpisode;
    if (story == null || episode == null || queue.position <= Duration.zero) {
      return;
    }
    unawaited(
      library
          .recordListening(
            series: story,
            episode: episode,
            position: queue.position,
            duration: queue.duration,
          )
          .catchError((Object _) {}),
    );
    unawaited(
      repository
          .saveProgress(episode.id, queue.position.inMilliseconds / 1000)
          .catchError((Object _) {}),
    );
  }

  Future<void> pause() async {
    await queue.pause();
    _saveCurrent();
  }

  Future<void> stop() async {
    _loadSerial++;
    _saveCurrent();
    await queue.stop();
    series = null;
    episodes = const [];
  }

  Future<void> select(StoryEpisode episode) async {
    final story = series;
    if (story == null) return;
    await open(story, episode, knownEpisodes: episodes, autoplay: true);
  }

  void dispose() {
    _loadSerial++;
    _saveCurrent();
    queue.dispose();
  }
}
