import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart';
import '../../config/providers.dart';
import '../../stories/models/story_models.dart';

class EpisodePage extends ConsumerStatefulWidget {
  const EpisodePage({super.key, required this.episode, required this.seriesTitle});
  final StoryEpisode episode;
  final String seriesTitle;

  @override
  ConsumerState<EpisodePage> createState() => _EpisodePageState();
}

class _EpisodePageState extends ConsumerState<EpisodePage> {
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration> _durationSubscription;
  late final StreamSubscription<PlayerState> _stateSubscription;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _busy = false;
  String? _loadedUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _positionSubscription = _player.onPositionChanged.listen((position) {
      if (mounted) setState(() => _position = position);
    });
    _durationSubscription = _player.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playing = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    if (_position.inSeconds > 0) {
      unawaited(ref.read(storiesRepositoryProvider).saveProgress(
        widget.episode.id, _position.inMilliseconds / 1000,
      ).catchError((Object _) {}));
    }
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _stateSubscription.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle(String url) async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      if (_playing) {
        await _player.pause();
        await ref.read(storiesRepositoryProvider).saveProgress(
          widget.episode.id, _position.inMilliseconds / 1000,
        );
      } else if (_loadedUrl == url) {
        await _player.resume();
      } else {
        await _player.play(UrlSource(url));
        _loadedUrl = url;
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Audio could not start. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
        ? episode.episodeSummary! : episode.script;
    return Scaffold(
      appBar: AppBar(title: Text(widget.seriesTitle,
        maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
        children: [
          Container(
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6F536F), Color(0xFFAD7C91), Color(0xFFE4B6A3)],
              ),
            ),
            child: const Icon(Icons.graphic_eq_rounded,
              size: 110, color: Color(0x88FFF5EB)),
          ),
          const SizedBox(height: 28),
          Text('EPISODE ${episode.episodeNumber}',
            style: const TextStyle(color: VelaColors.plum,
              fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 7),
          Text(episode.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: VelaColors.ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(24)),
            child: media.when(
              data: (value) {
                final url = value.audioUrl;
                if (url == null || url.isEmpty) {
                  return const Row(children: [
                    Icon(Icons.menu_book_outlined, color: VelaColors.plum),
                    SizedBox(width: 12),
                    Expanded(child: Text('Audio is being prepared. You can read this episode below.')),
                  ]);
                }
                final maximum = _duration.inMilliseconds > 0
                    ? _duration.inMilliseconds.toDouble() : 1.0;
                return Column(children: [
                  Row(children: [
                    IconButton.filled(
                      onPressed: _busy ? null : () => _toggle(url),
                      iconSize: 30,
                      icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_playing ? 'Listening now' : 'Ready to listen',
                      style: const TextStyle(fontWeight: FontWeight.w700,
                        color: VelaColors.ink))),
                  ]),
                  Slider(
                    value: _position.inMilliseconds.toDouble().clamp(0, maximum),
                    max: maximum,
                    onChanged: (value) => _player.seek(Duration(milliseconds: value.round())),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text(_time(_position)), Text(_time(_duration))]),
                  if (_error != null) Text(_error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ]);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Row(children: [
                const Expanded(child: Text('Audio is unavailable right now.')),
                TextButton(onPressed: () => ref.invalidate(episodeMediaProvider(episode.id)),
                  child: const Text('Retry')),
              ]),
            ),
          ),
          const SizedBox(height: 30),
          const Text('The story', style: TextStyle(fontSize: 21,
            fontWeight: FontWeight.w700, color: VelaColors.ink)),
          const SizedBox(height: 12),
          Text(text.isEmpty ? 'Story text will be available soon.' : text,
            style: const TextStyle(fontSize: 16, height: 1.65,
              color: VelaColors.ink)),
        ],
      ),
    );
  }
}
