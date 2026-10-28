import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../config/providers.dart';
import '../../stories/models/story_models.dart';
import '../listener/listener_library.dart';
import 'story_artwork.dart';

class EpisodePage extends ConsumerStatefulWidget {
  const EpisodePage({super.key, required this.episode, required this.series});
  final StoryEpisode episode;
  final StorySeries series;

  @override
  ConsumerState<EpisodePage> createState() => _EpisodePageState();
}

class _EpisodePageState extends ConsumerState<EpisodePage> {
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration> _durationSubscription;
  late final StreamSubscription<PlayerState> _stateSubscription;
  late final StreamSubscription<void> _completeSubscription;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _busy = false;
  int _lastLocalSave = 0;
  bool _completed = false;
  String? _loadedUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _positionSubscription = _player.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _position = position);
        if (position.inSeconds - _lastLocalSave >= 10) {
          _lastLocalSave = position.inSeconds;
          unawaited(_saveLocal());
        }
      }
    });
    _durationSubscription = _player.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playing = state == PlayerState.playing);
    });
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        _completed = true;
        unawaited(
          ref
              .read(listenerLibraryProvider.notifier)
              .removeRecent(widget.episode.id),
        );
      }
    });
  }

  Future<void> _saveLocal() => _completed
      ? Future.value()
      : ref.read(listenerLibraryProvider.notifier).recordListening(
            series: widget.series,
            episode: widget.episode,
            position: _position,
            duration: _duration,
          );

  @override
  void dispose() {
    if (_position.inSeconds > 0 && !_completed) unawaited(_saveLocal());
    if (_position.inSeconds > 0) {
      unawaited(
        ref
            .read(storiesRepositoryProvider)
            .saveProgress(widget.episode.id, _position.inMilliseconds / 1000)
            .catchError((Object _) {}),
      );
    }
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _stateSubscription.cancel();
    _completeSubscription.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_playing) {
        await _player.pause();
        await _saveLocal();
        await ref
            .read(storiesRepositoryProvider)
            .saveProgress(widget.episode.id, _position.inMilliseconds / 1000);
      } else {
        // Origin signs media URLs for one hour. Fetch a fresh URL whenever
        // playback starts so a page left open can still resume later.
        final media =
            await ref.read(storiesRepositoryProvider).media(widget.episode.id);
        final url = media.audioUrl;
        if (url == null || url.isEmpty) {
          throw StateError('Audio is not ready.');
        }
        _completed = false;
        if (_loadedUrl == url) {
          if (_duration > Duration.zero && _position >= _duration) {
            await _player.seek(Duration.zero);
          }
          await _player.resume();
        } else {
          final saved = ref
              .read(listenerLibraryProvider)
              .valueOrNull
              ?.recent
              .where((item) => item.episode.id == widget.episode.id)
              .firstOrNull;
          final resumeAt = _position > Duration.zero
              ? _position
              : Duration(
                  milliseconds: ((saved?.positionSeconds ?? 0) * 1000).round());
          await _player.play(UrlSource(url));
          _loadedUrl = url;
          if (resumeAt > Duration.zero &&
              (_duration == Duration.zero || resumeAt < _duration)) {
            await _player.seek(resumeAt);
            if (mounted) setState(() => _position = resumeAt);
            _lastLocalSave = resumeAt.inSeconds;
          }
        }
        await _saveLocal();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Audio could not start. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skip(int seconds) async {
    final target = _position + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : _duration > Duration.zero && target > _duration
            ? _duration
            : target;
    await _player.seek(clamped);
  }

  String _time(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final episode = widget.episode;
    final media = ref.watch(episodeMediaProvider(episode.id));
    final text = episode.episodeSummary?.isNotEmpty == true
        ? episode.episodeSummary!
        : episode.script;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.series.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
        children: [
          SizedBox(
            height: 240,
            child: StoryArtwork(
              thumbnail: widget.series.thumbnailUrl ?? widget.series.thumbnail,
              borderRadius: 28,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'EPISODE ${episode.episodeNumber}',
            style: const TextStyle(
              color: VelaColors.plum,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            episode.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: VelaColors.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: media.when(
              data: (value) {
                final url = value.audioUrl;
                if (url == null || url.isEmpty) {
                  return const Row(
                    children: [
                      Icon(Icons.menu_book_outlined, color: VelaColors.plum),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Audio is being prepared. You can read this episode below.',
                        ),
                      ),
                    ],
                  );
                }
                final maximum = _duration.inMilliseconds > 0
                    ? _duration.inMilliseconds.toDouble()
                    : 1.0;
                return Column(
                  children: [
                    Text(
                      _playing ? 'Now playing' : 'Ready to listen',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: VelaColors.ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Slider(
                      value: _position.inMilliseconds.toDouble().clamp(
                            0,
                            maximum,
                          ),
                      max: maximum,
                      onChanged: _duration > Duration.zero
                          ? (value) => _player.seek(
                                Duration(milliseconds: value.round()),
                              )
                          : null,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_time(_position)),
                        Text(_time(_duration)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Back 10 seconds',
                          onPressed: _duration > Duration.zero
                              ? () => _skip(-10)
                              : null,
                          icon: const Icon(Icons.replay_10_rounded),
                          iconSize: 32,
                        ),
                        const SizedBox(width: 22),
                        IconButton.filled(
                          tooltip: _playing ? 'Pause' : 'Play',
                          onPressed: _busy ? null : _toggle,
                          iconSize: 38,
                          constraints: const BoxConstraints(
                            minWidth: 72,
                            minHeight: 72,
                          ),
                          icon: Icon(
                            _playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                        const SizedBox(width: 22),
                        IconButton(
                          tooltip: 'Forward 10 seconds',
                          onPressed: _duration > Duration.zero
                              ? () => _skip(10)
                              : null,
                          icon: const Icon(Icons.forward_10_rounded),
                          iconSize: 32,
                        ),
                      ],
                    ),
                    if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Row(
                children: [
                  const Expanded(
                    child: Text('Audio is unavailable right now.'),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(episodeMediaProvider(episode.id)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'The story',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: VelaColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text.isEmpty ? 'Story text will be available soon.' : text,
            style: const TextStyle(
              fontSize: 16,
              height: 1.65,
              color: VelaColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
