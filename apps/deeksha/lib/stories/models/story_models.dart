// Freezed copies constructor annotations onto generated fields.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'story_models.freezed.dart';
part 'story_models.g.dart';

@freezed
class StorySeries with _$StorySeries {
  const factory StorySeries({
    required String id,
    required String title,
    String? description,
    String? source,
    String? thumbnail,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    @Default('active') String status,
  }) = _StorySeries;

  factory StorySeries.fromJson(Map<String, dynamic> json) =>
      _$StorySeriesFromJson(json);
}

@freezed
class StoryEpisode with _$StoryEpisode {
  const factory StoryEpisode({
    required String id,
    required String title,
    @JsonKey(name: 'series_id') required String seriesId,
    @JsonKey(name: 'episode_number') required int episodeNumber,
    @Default('') String script,
    @JsonKey(name: 'episode_summary') String? episodeSummary,
    @JsonKey(name: 'audio_key') String? audioKey,
    @JsonKey(name: 'audio_duration') int? audioDuration,
    @Default('active') String status,
  }) = _StoryEpisode;

  factory StoryEpisode.fromJson(Map<String, dynamic> json) =>
      _$StoryEpisodeFromJson(json);
}

@freezed
class EpisodeMedia with _$EpisodeMedia {
  const factory EpisodeMedia({
    @JsonKey(name: 'episode_id') required String episodeId,
    @JsonKey(name: 'audio_url') String? audioUrl,
    @JsonKey(name: 'expires_in') int? expiresIn,
  }) = _EpisodeMedia;

  factory EpisodeMedia.fromJson(Map<String, dynamic> json) =>
      _$EpisodeMediaFromJson(json);
}
