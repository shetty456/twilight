import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storage/storage.dart';

import '../../stories/models/story_models.dart';

final listenerLibraryProvider =
    StateNotifierProvider<
      ListenerLibraryController,
      AsyncValue<ListenerLibraryState>
    >((ref) {
      return ListenerLibraryController(SharedPreferencesStorage.create());
    });

class RecentListen {
  const RecentListen({
    required this.series,
    required this.episode,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.updatedAt,
  });

  final StorySeries series;
  final StoryEpisode episode;
  final double positionSeconds;
  final double durationSeconds;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'series': series.toJson(),
    'episode': episode.toJson(),
    'positionSeconds': positionSeconds,
    'durationSeconds': durationSeconds,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory RecentListen.fromJson(Map<String, dynamic> json) => RecentListen(
    series: StorySeries.fromJson(
      Map<String, dynamic>.from(json['series'] as Map),
    ),
    episode: StoryEpisode.fromJson(
      Map<String, dynamic>.from(json['episode'] as Map),
    ),
    positionSeconds: (json['positionSeconds'] as num).toDouble(),
    durationSeconds: (json['durationSeconds'] as num).toDouble(),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class ListenerLibraryState {
  const ListenerLibraryState({this.saved = const [], this.recent = const []});

  final List<StorySeries> saved;
  final List<RecentListen> recent;

  bool isSaved(String seriesId) => saved.any((item) => item.id == seriesId);

  Map<String, dynamic> toJson() => {
    'saved': saved.map((item) => item.toJson()).toList(),
    'recent': recent.map((item) => item.toJson()).toList(),
  };

  factory ListenerLibraryState.fromJson(Object? value) {
    final json = Map<String, dynamic>.from(value as Map);
    return ListenerLibraryState(
      saved: (json['saved'] as List? ?? const [])
          .map(
            (item) =>
                StorySeries.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      recent: (json['recent'] as List? ?? const [])
          .map(
            (item) =>
                RecentListen.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}

class ListenerLibraryController
    extends StateNotifier<AsyncValue<ListenerLibraryState>> {
  ListenerLibraryController(Future<StorageService> storage)
    : super(const AsyncLoading()) {
    _ready = _load(storage);
  }

  late final Future<void> _ready;
  Future<void> get ready => _ready;
  late TypedPreferences _preferences;
  Future<void> _pendingWrite = Future.value();

  Future<void> _load(Future<StorageService> storage) async {
    try {
      _preferences = TypedPreferences(
        await storage,
        namespace: 'vela_fm.listener',
      );
      final library = await _preferences.readJson(
        'library',
        ListenerLibraryState.fromJson,
      );
      if (mounted) state = AsyncData(library ?? const ListenerLibraryState());
    } catch (_) {
      if (mounted) state = const AsyncData(ListenerLibraryState());
    }
  }

  Future<void> _persist(ListenerLibraryState next) {
    _pendingWrite = _pendingWrite.then(
      (_) => _preferences.writeJson('library', next, (value) => value.toJson()),
    );
    return _pendingWrite;
  }

  Future<void> toggleSaved(StorySeries series) async {
    await _ready;
    final current = state.valueOrNull ?? const ListenerLibraryState();
    final saved = current.isSaved(series.id)
        ? current.saved.where((item) => item.id != series.id).toList()
        : [series, ...current.saved];
    final next = ListenerLibraryState(saved: saved, recent: current.recent);
    if (mounted) state = AsyncData(next);
    await _persist(next);
  }

  Future<void> recordListening({
    required StorySeries series,
    required StoryEpisode episode,
    required Duration position,
    required Duration duration,
  }) async {
    await _ready;
    final current = state.valueOrNull ?? const ListenerLibraryState();
    final recent = [
      RecentListen(
        series: series,
        episode: episode,
        positionSeconds: position.inMilliseconds / 1000,
        durationSeconds: duration.inMilliseconds / 1000,
        updatedAt: DateTime.now(),
      ),
      ...current.recent.where((item) => item.episode.id != episode.id),
    ].take(20).toList();
    final next = ListenerLibraryState(saved: current.saved, recent: recent);
    if (mounted) state = AsyncData(next);
    await _persist(next);
  }

  Future<void> removeRecent(String episodeId) async {
    await _ready;
    final current = state.valueOrNull ?? const ListenerLibraryState();
    final next = ListenerLibraryState(
      saved: current.saved,
      recent: current.recent
          .where((item) => item.episode.id != episodeId)
          .toList(),
    );
    if (mounted) state = AsyncData(next);
    await _persist(next);
  }

  Future<void> clear() async {
    await _ready;
    const next = ListenerLibraryState();
    if (mounted) state = const AsyncData(next);
    await _persist(next);
  }
}
