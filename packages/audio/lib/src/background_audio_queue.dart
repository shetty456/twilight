import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

@immutable
class AudioQueueItem {
  const AudioQueueItem({
    required this.id,
    required this.title,
    required this.album,
    this.artUri,
    this.duration,
  });

  final String id;
  final String title;
  final String album;
  final Uri? artUri;
  final Duration? duration;
}

typedef AudioUrlResolver = Future<Uri> Function(AudioQueueItem item);
typedef AudioPositionCallback = void Function(AudioQueueItem item, Duration position, Duration duration);
typedef AudioItemCallback = void Function(AudioQueueItem item);

/// Owns one player for the app lifetime. The queue continues when a route is closed.
class BackgroundAudioQueue extends ChangeNotifier {
  BackgroundAudioQueue({
    required AudioUrlResolver resolveUrl,
    AudioPlayer? player,
    this.onPosition,
    this.onItemFinished,
  }) : _resolveUrl = resolveUrl,
       player = player ?? AudioPlayer() {
    _subscriptions.addAll([
      this.player.positionStream.listen((value) {
        position = value;
        _notifyPosition();
        notifyListeners();
      }),
      this.player.durationStream.listen((value) {
        duration = value ?? currentItem?.duration ?? Duration.zero;
        notifyListeners();
      }),
      this.player.bufferedPositionStream.listen((value) {
        bufferedPosition = value;
        notifyListeners();
      }),
      this.player.playerStateStream.listen((state) {
        playing = state.playing;
        processingState = state.processingState;
        notifyListeners();
        if (state.processingState == ProcessingState.completed) {
          unawaited(_resumeAfterCompletion());
        }
      }),
      this.player.currentIndexStream.listen(_onPlayerIndex),
      this.player.errorStream.listen((error) {
        this.error = error;
        notifyListeners();
      }),
    ]);
  }

  static Future<void> initialize({
    required String notificationChannelId,
    required String notificationChannelName,
  }) async {
    await JustAudioBackground.init(
      androidNotificationChannelId: notificationChannelId,
      androidNotificationChannelName: notificationChannelName,
      androidNotificationOngoing: true,
    );
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  final AudioUrlResolver _resolveUrl;
  final AudioPlayer player;
  final AudioPositionCallback? onPosition;
  final AudioItemCallback? onItemFinished;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _retryTimer;
  List<AudioQueueItem> _items = const [];
  int _firstQueueIndex = 0;
  int _loadedCount = 0;
  int _generation = 0;
  bool _adding = false;
  int _lastPositionSecond = -1;

  AudioQueueItem? currentItem;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  Duration bufferedPosition = Duration.zero;
  ProcessingState processingState = ProcessingState.idle;
  bool playing = false;
  bool loading = false;
  bool ready = false;
  Object? error;

  List<AudioQueueItem> get items => List.unmodifiable(_items);
  int get currentQueueIndex => currentItem == null
      ? -1
      : _items.indexWhere((item) => item.id == currentItem!.id);
  bool get hasNext => currentQueueIndex >= 0 && currentQueueIndex + 1 < _items.length;
  bool get hasPrevious => currentQueueIndex > 0;
  bool get buffering => loading || processingState == ProcessingState.loading ||
      processingState == ProcessingState.buffering;

  Future<void> load(
    List<AudioQueueItem> items, {
    required int initialIndex,
    Duration initialPosition = Duration.zero,
    bool autoplay = false,
  }) async {
    if (items.isEmpty || initialIndex < 0 || initialIndex >= items.length) {
      throw RangeError.index(initialIndex, items);
    }
    final generation = ++_generation;
    _retryTimer?.cancel();
    _items = List.unmodifiable(items);
    _firstQueueIndex = initialIndex;
    _loadedCount = 0;
    currentItem = items[initialIndex];
    position = initialPosition;
    duration = currentItem?.duration ?? Duration.zero;
    bufferedPosition = Duration.zero;
    loading = true;
    ready = false;
    error = null;
    notifyListeners();
    try {
      final source = await _sourceFor(currentItem!);
      if (generation != _generation) return;
      await player.setAudioSources(
        [source],
        initialPosition: initialPosition,
      );
      if (generation != _generation) return;
      _loadedCount = 1;
      ready = true;
      loading = false;
      duration = player.duration ?? currentItem?.duration ?? Duration.zero;
      notifyListeners();
      if (autoplay) play();
      unawaited(_prefetchNext(generation));
    } catch (caught) {
      if (generation != _generation) return;
      error = caught;
      loading = false;
      ready = false;
      notifyListeners();
    }
  }

  Future<AudioSource> _sourceFor(AudioQueueItem item) async {
    final uri = await _resolveUrl(item);
    return AudioSource.uri(
      uri,
      tag: MediaItem(
        id: item.id,
        title: item.title,
        album: item.album,
        artUri: item.artUri,
        duration: item.duration,
      ),
    );
  }

  Future<void> _prefetchNext(int generation) async {
    if (_adding || generation != _generation || !ready) return;
    final nextIndex = _firstQueueIndex + _loadedCount;
    if (nextIndex >= _items.length) return;
    _adding = true;
    var appended = false;
    try {
      final source = await _sourceFor(_items[nextIndex]);
      if (generation != _generation) return;
      await player.addAudioSource(source);
      if (generation != _generation) return;
      _loadedCount++;
      appended = true;
      error = null;
      notifyListeners();
      if (processingState == ProcessingState.completed) {
        await _resumeAfterCompletion();
      }
    } catch (caught) {
      if (generation != _generation) return;
      // Keep the current item playing; retry its successor without declaring
      // the active stream offline.
      if (processingState == ProcessingState.completed) {
        error = caught;
        notifyListeners();
      }
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(seconds: 15), () {
        unawaited(_prefetchNext(generation));
      });
    } finally {
      _adding = false;
      if (appended && generation == _generation &&
          _firstQueueIndex + _loadedCount < _items.length &&
          currentQueueIndex >= _firstQueueIndex + _loadedCount - 1) {
        unawaited(_prefetchNext(generation));
      }
    }
  }

  void _onPlayerIndex(int? index) {
    if (index == null || _loadedCount == 0) return;
    final queueIndex = _firstQueueIndex + index;
    if (queueIndex < 0 || queueIndex >= _items.length) return;
    final next = _items[queueIndex];
    final previous = currentItem;
    if (previous?.id == next.id) return;
    if (previous != null) onItemFinished?.call(previous);
    currentItem = next;
    position = Duration.zero;
    duration = next.duration ?? Duration.zero;
    bufferedPosition = Duration.zero;
    error = null;
    notifyListeners();
    unawaited(_prefetchNext(_generation));
  }

  Future<void> _resumeAfterCompletion() async {
    if (!ready) return;
    if (!hasNext) {
      await player.pause();
      return;
    }
    if (player.hasNext) {
      await player.seekToNext();
      play();
    } else {
      await _prefetchNext(_generation);
    }
  }

  void _notifyPosition() {
    final item = currentItem;
    if (item == null || position.inSeconds == _lastPositionSecond) return;
    _lastPositionSecond = position.inSeconds;
    onPosition?.call(item, position, duration);
  }

  void play() {
    if (!ready) return;
    error = null;
    notifyListeners();
    unawaited(player.play().catchError((Object caught) {
      error = caught;
      notifyListeners();
    }));
  }

  Future<void> pause() => player.pause();

  Future<void> stop() async {
    _generation++;
    _retryTimer?.cancel();
    await player.stop();
    _items = const [];
    _loadedCount = 0;
    _firstQueueIndex = 0;
    currentItem = null;
    position = Duration.zero;
    duration = Duration.zero;
    bufferedPosition = Duration.zero;
    ready = false;
    loading = false;
    playing = false;
    error = null;
    notifyListeners();
  }

  Future<void> seek(Duration target) => player.seek(target);

  Future<void> skip(Duration offset) async {
    final target = position + offset;
    final clamped = target < Duration.zero
        ? Duration.zero
        : duration > Duration.zero && target > duration
        ? duration
        : target;
    await seek(clamped);
  }

  Future<void> select(int index, {bool autoplay = true}) async {
    if (index < 0 || index >= _items.length) return;
    await load(_items, initialIndex: index, autoplay: autoplay);
  }

  Future<void> retry() async {
    if (!ready) {
      if (currentQueueIndex >= 0) {
        await load(_items, initialIndex: currentQueueIndex, autoplay: true);
      }
      return;
    }
    if (processingState == ProcessingState.completed) {
      await _prefetchNext(_generation);
    } else {
      play();
    }
  }

  @override
  void dispose() {
    _generation++;
    _retryTimer?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(player.dispose());
    super.dispose();
  }
}
