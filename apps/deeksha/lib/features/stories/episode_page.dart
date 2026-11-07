import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';
import 'package:twilight_audio/twilight_audio.dart';

import '../../app.dart';
import '../../config/providers.dart';
import '../../stories/models/story_models.dart';
import 'story_artwork.dart';
import 'story_playback.dart';

class EpisodePage extends ConsumerStatefulWidget {
  const EpisodePage({
    super.key,
    required this.episode,
    required this.series,
    this.playback,
  });
  final StoryEpisode episode;
  final StorySeries series;
  final StoryPlaybackSession? playback;

  @override
  ConsumerState<EpisodePage> createState() => _EpisodePageState();
}

class _EpisodePageState extends ConsumerState<EpisodePage>
    with SingleTickerProviderStateMixin {
  late final StoryPlaybackSession _session;
  late final BackgroundAudioQueue _queue;
  late final AnimationController _disc;
  late StoryEpisode _episode = widget.episode;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  bool _playing = false;
  bool _busy = false;
  bool _ready = false;
  bool _preparing = true;
  bool _buffering = false;
  String? _error;
  bool _offlineError = false;

  @override
  void initState() {
    super.initState();
    _session = widget.playback ?? ref.read(storyPlaybackProvider);
    _queue = _session.queue;
    _disc = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _queue.addListener(_refresh);
    _refresh();
    unawaited(_open());
  }

  Future<void> _open() async {
    await _session.open(
      widget.series,
      widget.episode,
      knownEpisodes: ref.read(episodesProvider(widget.series.id)).valueOrNull,
    );
    if (mounted) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    final sameSeries = _session.series?.id == widget.series.id;
    final activeEpisode = sameSeries ? _session.currentEpisode : null;
    final error = sameSeries ? _queue.error : null;
    setState(() {
      if (activeEpisode != null) _episode = activeEpisode;
      _position = sameSeries ? _queue.position : Duration.zero;
      _duration = sameSeries ? _queue.duration : Duration.zero;
      _bufferedPosition = sameSeries ? _queue.bufferedPosition : Duration.zero;
      _playing = sameSeries && _queue.playing;
      _ready = sameSeries && _queue.ready;
      _preparing = !sameSeries || _queue.loading;
      _buffering = sameSeries && _queue.buffering && !_queue.loading;
      _offlineError =
          error is NetworkException &&
          error.message == 'No internet connection';
      _error = error == null
          ? null
          : error is StateError
          ? error.message.toString()
          : _offlineError
          ? 'No internet connection'
          : 'Audio could not load. Please try again.';
    });
    if (_playing && !_disc.isAnimating) _disc.repeat();
    if (!_playing && _disc.isAnimating) _disc.stop();
  }

  @override
  void dispose() {
    _queue.removeListener(_refresh);
    _disc.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy || !_ready) return;
    setState(() => _busy = true);
    try {
      if (_playing) {
        await _session.pause();
      } else {
        _queue.play();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _prepare() => _queue.retry();

  Future<void> _selectEpisode(
    StoryEpisode episode, {
    bool autoplay = false,
  }) async {
    if (episode.id == _episode.id) return;
    await _session.open(
      widget.series,
      episode,
      knownEpisodes: _session.episodes,
      autoplay: autoplay,
    );
  }

  Future<void> _skip(int seconds) => _queue.skip(Duration(seconds: seconds));

  String _time(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showStory() {
    final text = _episode.script.isNotEmpty
        ? _episode.script
        : _episode.episodeSummary ?? '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: VelaColors.surface,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.78,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
            children: [
              Text(
                _episode.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              Text(
                text.isEmpty ? 'Story text will be available soon.' : text,
                style: const TextStyle(fontSize: 17, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlaylist(List<StoryEpisode> episodes) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: VelaColors.surface,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Text(
                  'Up next',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: episodes.length,
                  itemBuilder: (context, index) {
                    final item = episodes[index];
                    final selected = item.id == _episode.id;
                    return ListTile(
                      selected: selected,
                      leading: Text('${item.episodeNumber}'.padLeft(2, '0')),
                      title: Text(item.title),
                      subtitle: Text('Episode ${item.episodeNumber}'),
                      trailing: selected
                          ? const Icon(
                              Icons.graphic_eq_rounded,
                              color: VelaColors.apricot,
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        unawaited(_selectEpisode(item, autoplay: true));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final episodes =
        ref.watch(episodesProvider(widget.series.id)).valueOrNull ??
        _session.episodes;
    final index = episodes.indexWhere((item) => item.id == _episode.id);
    final previous = index > 0 ? episodes[index - 1] : null;
    final next = index >= 0 && index + 1 < episodes.length
        ? episodes[index + 1]
        : null;
    final maximum = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF392337), VelaColors.cream, VelaColors.cream],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 650;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'NOW PLAYING',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: VelaColors.plum,
                                ),
                              ),
                              Text(
                                widget.series.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Episodes',
                          onPressed:
                              !_preparing && !_busy && episodes.isNotEmpty
                              ? () => _showPlaylist(episodes)
                              : null,
                          icon: const Icon(Icons.queue_music_rounded),
                        ),
                        IconButton(
                          tooltip: 'Read story',
                          onPressed: _showStory,
                          icon: const Icon(Icons.menu_book_outlined),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 4 : 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, inner) {
                          final size = (inner.maxWidth - 32)
                              .clamp(0.0, inner.maxHeight)
                              .clamp(0.0, 340.0);
                          return Center(
                            child: SizedBox(
                              width: size,
                              height: size,
                              child: _preparing
                                  ? AppSkeletonBox(
                                      width: size,
                                      height: size,
                                      radius: size / 2,
                                    )
                                  : _DiscArtwork(
                                      thumbnail:
                                          widget.series.thumbnailUrl ??
                                          widget.series.thumbnail,
                                      rotation: _disc,
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'EPISODE ${_episode.episodeNumber}',
                        style: const TextStyle(
                          color: VelaColors.apricot,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _episode.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 16),
                    if (_preparing) ...[
                      const AppSkeletonBox(
                        width: double.infinity,
                        height: 5,
                        radius: 3,
                      ),
                      const SizedBox(height: 34),
                      const AppSkeletonBox(width: 76, height: 76, radius: 38),
                      const SizedBox(height: 8),
                      const Text(
                        'Preparing audio…',
                        style: TextStyle(color: VelaColors.plum),
                      ),
                    ] else ...[
                      Slider(
                        value: _position.inMilliseconds.toDouble().clamp(
                          0,
                          maximum,
                        ),
                        max: maximum,
                        secondaryTrackValue: _bufferedPosition.inMilliseconds
                            .toDouble()
                            .clamp(
                              _position.inMilliseconds.toDouble().clamp(
                                0,
                                maximum,
                              ),
                              maximum,
                            ),
                        onChanged: _ready && !_busy && _duration > Duration.zero
                            ? (value) => _queue.seek(
                                Duration(milliseconds: value.round()),
                              )
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_time(_position)),
                            Text(_time(_duration)),
                          ],
                        ),
                      ),
                      if (_buffering)
                        const Text(
                          'Buffering audio…',
                          style: TextStyle(
                            color: VelaColors.plum,
                            fontSize: 12,
                          ),
                        ),
                      SizedBox(height: compact ? 4 : 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            tooltip: 'Previous episode',
                            onPressed: _ready && !_busy && previous != null
                                ? () => _selectEpisode(previous, autoplay: true)
                                : null,
                            icon: const Icon(Icons.skip_previous_rounded),
                            iconSize: 32,
                          ),
                          IconButton(
                            tooltip: 'Back 10 seconds',
                            onPressed:
                                _ready && !_busy && _duration > Duration.zero
                                ? () => _skip(-10)
                                : null,
                            icon: const Icon(Icons.replay_10_rounded),
                            iconSize: 30,
                          ),
                          IconButton.filled(
                            tooltip: _playing ? 'Pause' : 'Play',
                            onPressed: _ready && !_busy ? _toggle : null,
                            iconSize: 38,
                            constraints: const BoxConstraints(
                              minWidth: 76,
                              minHeight: 76,
                            ),
                            icon: Icon(
                              _playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Forward 10 seconds',
                            onPressed:
                                _ready && !_busy && _duration > Duration.zero
                                ? () => _skip(10)
                                : null,
                            icon: const Icon(Icons.forward_10_rounded),
                            iconSize: 30,
                          ),
                          IconButton(
                            tooltip: 'Next episode',
                            onPressed: _ready && !_busy && next != null
                                ? () => _selectEpisode(next, autoplay: true)
                                : null,
                            icon: const Icon(Icons.skip_next_rounded),
                            iconSize: 32,
                          ),
                        ],
                      ),
                    ],
                    if (_offlineError)
                      AppOfflineBanner(
                        isOffline: true,
                        message: 'No internet connection',
                        retryLabel: 'Retry audio',
                        onRetry: _prepare,
                      )
                    else if (_error != null)
                      SizedBox(
                        height: 40,
                        child: TextButton(
                          onPressed: _prepare,
                          child: Text(
                            'Retry audio · $_error',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DiscArtwork extends StatelessWidget {
  const _DiscArtwork({required this.thumbnail, required this.rotation});

  final String? thumbnail;
  final Animation<double> rotation;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: VelaColors.action.withValues(alpha: 0.28),
          blurRadius: 38,
          spreadRadius: 6,
        ),
      ],
    ),
    child: RotationTransition(
      turns: rotation,
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            StoryArtwork(thumbnail: thumbnail, borderRadius: 180),
            const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x22000000),
                    Color(0x11000000),
                    Color(0x77000000),
                  ],
                  stops: [0.0, 0.65, 1.0],
                ),
              ),
            ),
            Center(
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: VelaColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: VelaColors.apricot, width: 5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x99000000), blurRadius: 12),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF100D13),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
