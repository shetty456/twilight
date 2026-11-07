import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:twilight_audio/twilight_audio.dart';

class _FakePlayer extends AudioPlayer {
  final positions = StreamController<Duration>.broadcast();
  final durations = StreamController<Duration?>.broadcast();
  final buffers = StreamController<Duration>.broadcast();
  final states = StreamController<PlayerState>.broadcast();
  final indices = StreamController<int?>.broadcast();
  final errors = StreamController<PlayerException>.broadcast();
  final sources = <AudioSource>[];
  int index = 0;

  @override
  Stream<Duration> get positionStream => positions.stream;
  @override
  Stream<Duration?> get durationStream => durations.stream;
  @override
  Stream<Duration> get bufferedPositionStream => buffers.stream;
  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  Stream<int?> get currentIndexStream => indices.stream;
  @override
  Stream<PlayerException> get errorStream => errors.stream;
  @override
  Duration? get duration => const Duration(minutes: 5);
  @override
  bool get hasNext => index + 1 < sources.length;

  @override
  Future<Duration?> setAudioSources(
    List<AudioSource> audioSources, {
    bool preload = true,
    int? initialIndex,
    Duration? initialPosition,
    ShuffleOrder? shuffleOrder,
  }) async {
    sources
      ..clear()
      ..addAll(audioSources);
    index = 0;
    indices.add(index);
    durations.add(duration);
    return duration;
  }

  @override
  Future<void> addAudioSource(AudioSource audioSource) async {
    sources.add(audioSource);
  }

  @override
  Future<void> seekToNext() async {
    if (!hasNext) return;
    index++;
    indices.add(index);
  }

  @override
  Future<void> play() async {
    states.add(PlayerState(true, ProcessingState.ready));
  }

  @override
  Future<void> pause() async {
    states.add(PlayerState(false, ProcessingState.ready));
  }

  @override
  Future<void> stop() async {
    sources.clear();
    states.add(PlayerState(false, ProcessingState.idle));
  }

  @override
  Future<void> dispose() async {
    await Future.wait([
      positions.close(),
      durations.close(),
      buffers.close(),
      states.close(),
      indices.close(),
      errors.close(),
    ]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const items = [
    AudioQueueItem(id: 'one', title: 'First', album: 'A Story'),
    AudioQueueItem(id: 'two', title: 'Second', album: 'A Story'),
  ];

  test('queues the next item and exposes streamed buffer progress', () async {
    final player = _FakePlayer();
    final finished = <String>[];
    final queue = BackgroundAudioQueue(
      player: player,
      resolveUrl: (item) async =>
          Uri.parse('https://example.com/${item.id}.mp3'),
      onItemFinished: (item) => finished.add(item.id),
    );
    await queue.load(items, initialIndex: 0, autoplay: true);
    await Future<void>.delayed(Duration.zero);
    expect(player.sources.length, 2);
    expect(queue.playing, true);

    player.buffers.add(const Duration(seconds: 45));
    await Future<void>.delayed(Duration.zero);
    expect(queue.bufferedPosition, const Duration(seconds: 45));

    player.indices.add(1);
    await Future<void>.delayed(Duration.zero);
    expect(queue.currentItem?.id, 'two');
    expect(finished, ['one']);
    queue.dispose();
  });

  test(
    'retries a failed next URL at completion and resumes playback',
    () async {
      final player = _FakePlayer();
      var secondAttempts = 0;
      final queue = BackgroundAudioQueue(
        player: player,
        resolveUrl: (item) async {
          if (item.id == 'two' && ++secondAttempts == 1) {
            throw StateError('Temporary network failure');
          }
          return Uri.parse('https://example.com/${item.id}.mp3');
        },
      );
      await queue.load(items, initialIndex: 0, autoplay: true);
      await Future<void>.delayed(Duration.zero);
      expect(player.sources.length, 1);
      expect(queue.error, isNull);

      player.states.add(PlayerState(true, ProcessingState.completed));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(player.sources.length, 2);
      expect(queue.currentItem?.id, 'two');
      expect(queue.playing, true);
      queue.dispose();
    },
  );
}
