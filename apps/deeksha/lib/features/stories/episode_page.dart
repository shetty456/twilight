import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui/ui.dart';

import '../../app.dart';
import '../../config/providers.dart';
import '../../data/origin_repository.dart';
import '../../stories/models/story_models.dart';
import '../listener/listener_library.dart';
import 'story_artwork.dart';

class EpisodePage extends ConsumerStatefulWidget {
  const EpisodePage({
    super.key,
    required this.episode,
    required this.series,
    this.audioPlayer,
  });
  final StoryEpisode episode;
  final StorySeries series;
  final AudioPlayer? audioPlayer;

  @override
  ConsumerState<EpisodePage> createState() => _EpisodePageState();
}

class _EpisodePageState extends ConsumerState<EpisodePage>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _player;
  late final ListenerLibraryController _library;
  OriginStoriesRepository? _repository;
  late final AnimationController _disc;
  late StoryEpisode _episode = widget.episode;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration> _durationSubscription;
  late final StreamSubscription<PlayerState> _stateSubscription;
  late final StreamSubscription<void> _completeSubscription;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _busy = false;
  bool _ready = false;
  bool _preparing = true;
  int _loadSerial = 0;
  DateTime? _preparedAt;
  int _lastLocalSave = 0;
  bool _completed = false;
  String? _error;
  bool _offlineError = false;

  @override
  void initState() {
    super.initState();
    _player = widget.audioPlayer ?? AudioPlayer();
    _library = ref.read(listenerLibraryProvider.notifier);
    _disc = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
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
      if (!mounted) return;
      final playing = state == PlayerState.playing;
      setState(() => _playing = playing);
      if (playing && !_disc.isAnimating) _disc.repeat();
      if (!playing && _disc.isAnimating) _disc.stop();
    });
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      if (mounted) unawaited(_onComplete());
    });
    unawaited(_prepare());
  }

  Future<void> _saveLocal() => _completed
      ? Future.value()
      : _library.recordListening(
          series: widget.series,
          episode: _episode,
          position: _position,
          duration: _duration,
        );

  @override
  void dispose() {
    if (_position.inSeconds > 0 && !_completed) unawaited(_saveLocal());
    if (_position.inSeconds > 0 && _repository != null) {
      unawaited(
        _repository!
            .saveProgress(_episode.id, _position.inMilliseconds / 1000)
            .catchError((Object _) {}),
      );
    }
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _stateSubscription.cancel();
    _completeSubscription.cancel();
    _disc.dispose();
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy || !_ready) return;
    setState(() {
      _busy = true;
      _error = null;
      _offlineError = false;
    });
    try {
      if (_playing) {
        await _player.pause();
        await _saveLocal();
        await _repository!.saveProgress(
          _episode.id,
          _position.inMilliseconds / 1000,
        );
      } else {
        // Origin signs links for one hour. Refresh before a stale source plays.
        if (_preparedAt != null &&
            DateTime.now().difference(_preparedAt!) >=
                const Duration(minutes: 55)) {
          await _prepare(autoplay: true);
          return;
        }
        _completed = false;
        if (_duration > Duration.zero && _position >= _duration) {
          await _player.seek(Duration.zero);
        }
        await _player.resume();
        await _saveLocal();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _offlineError =
              error is NetworkException &&
              error.message == 'No internet connection';
          _error = _offlineError
              ? 'No internet connection'
              : 'Audio could not start. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _prepare({bool autoplay = false}) async {
    final serial = ++_loadSerial;
    final episode = _episode;
    final resumeAt = _position > Duration.zero
        ? _position
        : Duration(
            milliseconds:
                ((ref
                                .read(listenerLibraryProvider)
                                .valueOrNull
                                ?.recent
                                .where((item) => item.episode.id == episode.id)
                                .firstOrNull
                                ?.positionSeconds ??
                            0) *
                        1000)
                    .round(),
          );
    setState(() {
      _preparing = true;
      _ready = false;
      _busy = false;
      _error = null;
      _offlineError = false;
    });
    try {
      await _player.stop();
      if (!mounted || serial != _loadSerial) return;
      final repository = ref.read(storiesRepositoryProvider);
      _repository ??= repository;
      final media = await repository.media(episode.id);
      if (!mounted || serial != _loadSerial) return;
      if (media.audioUrl == null || media.audioUrl!.isEmpty) {
        throw StateError('Audio is being prepared for this episode.');
      }
      await _player.setSource(UrlSource(media.audioUrl!));
      if (!mounted || serial != _loadSerial) return;
      final duration = await _player.getDuration();
      final canResume =
          resumeAt > Duration.zero && (duration == null || resumeAt < duration);
      if (canResume) {
        await _player.seek(resumeAt);
      }
      if (!mounted || serial != _loadSerial) return;
      setState(() {
        _position = canResume ? resumeAt : Duration.zero;
        _duration = duration ?? Duration.zero;
        _lastLocalSave = _position.inSeconds;
        _ready = true;
        _preparing = false;
        _preparedAt = DateTime.now();
      });
      if (autoplay) await _toggle();
    } catch (error) {
      if (!mounted || serial != _loadSerial) return;
      setState(() {
        _preparing = false;
        _offlineError =
            error is NetworkException &&
            error.message == 'No internet connection';
        _error = error is StateError
            ? error.message.toString()
            : _offlineError
            ? 'No internet connection'
            : 'Audio could not load. Please try again.';
      });
    }
  }

  Future<void> _selectEpisode(
    StoryEpisode episode, {
    bool autoplay = false,
  }) async {
    if (episode.id == _episode.id) return;
    final previous = _episode;
    final position = _position;
    if (!_completed && position > Duration.zero) {
      unawaited(_saveLocal());
      unawaited(
        _repository!
            .saveProgress(previous.id, position.inMilliseconds / 1000)
            .catchError((Object _) {}),
      );
    }
    if (!mounted) return;
    setState(() {
      _episode = episode;
      _completed = false;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
    await _prepare(autoplay: autoplay);
  }

  Future<void> _onComplete() async {
    final completed = _episode;
    _completed = true;
    try {
      await _library.removeRecent(completed.id);
    } catch (_) {
      // Continue the playlist even if the recent list cannot be updated.
    }
    if (!mounted || completed.id != _episode.id) return;
    List<StoryEpisode> episodes;
    try {
      episodes = await ref.read(episodesProvider(widget.series.id).future);
    } catch (_) {
      return;
    }
    if (!mounted || completed.id != _episode.id) return;
    final index = episodes.indexWhere((item) => item.id == completed.id);
    if (index >= 0 && index + 1 < episodes.length) {
      await _selectEpisode(episodes[index + 1], autoplay: true);
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
    final episodes = ref.watch(episodesProvider(widget.series.id)).valueOrNull;
    final index = episodes?.indexWhere((item) => item.id == _episode.id) ?? -1;
    final previous = index > 0 ? episodes![index - 1] : null;
    final next = index >= 0 && index + 1 < (episodes?.length ?? 0)
        ? episodes![index + 1]
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
                              !_preparing &&
                                  !_busy &&
                                  episodes?.isNotEmpty == true
                              ? () => _showPlaylist(episodes!)
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
                        onChanged: _ready && !_busy && _duration > Duration.zero
                            ? (value) => _player.seek(
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
                        onRetry: _ready ? _toggle : _prepare,
                      )
                    else if (_error != null)
                      SizedBox(
                        height: 40,
                        child: TextButton(
                          onPressed: _ready ? _toggle : _prepare,
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
