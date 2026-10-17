import 'package:auth/auth.dart';
import 'package:dio/dio.dart';
import 'package:network/network.dart';

import '../stories/models/story_models.dart';

class OriginPhoneAuthRepository {
  const OriginPhoneAuthRepository(this._client, this._tokens);

  final DioClient _client;
  final AuthTokenStore _tokens;

  Future<String?> requestCode(String phone) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        'auth/otp/phone/request/',
        data: {'phone': phone},
        options: Options(extra: {JwtRefreshInterceptor.skipAuthKey: true}),
      );
      final code = response.data?['dev_otp'] ?? response.data?['otp'];
      return code is String && RegExp(r'^\d{4}$').hasMatch(code) ? code : null;
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<void> verifyCode(String phone, String code) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        'auth/otp/phone/verify/',
        data: {'phone': phone, 'otp': code},
        options: Options(extra: {JwtRefreshInterceptor.skipAuthKey: true}),
      );
      final data = response.data;
      final access = data?['access'];
      final refresh = data?['refresh'];
      if (access is! String || refresh is! String) {
        throw const FormatException('The server did not return a session.');
      }
      await _tokens.write(AuthTokens(access: access, refresh: refresh));
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<bool> hasSession() async => await _tokens.read() != null;

  Future<void> signOut() => _tokens.clear();
}

class OriginStoriesRepository {
  const OriginStoriesRepository(this._client);
  final DioClient _client;

  Future<List<StorySeries>> series() async {
    try {
      final response = await _client.dio.get<dynamic>('stories/series/');
      return _items(response.data)
          .map((item) => StorySeries.fromJson(item))
          .where((item) => item.status == 'active')
          .toList();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<List<StoryEpisode>> episodes(String seriesId) async {
    try {
      final response = await _client.dio.get<dynamic>(
        'stories/series/$seriesId/episodes/',
      );
      final entries = _items(response.data)
          .map((item) => StoryEpisode.fromJson(item))
          .where((item) => item.status == 'active')
          .toList();
      entries.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
      return entries;
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<EpisodeMedia> media(String episodeId) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        'stories/episodes/$episodeId/media/',
      );
      return EpisodeMedia.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<void> saveProgress(String episodeId, double seconds) async {
    try {
      await _client.dio.post<dynamic>(
        'stories/playback-progress/',
        data: {'episode_id': episodeId, 'progress_seconds': seconds},
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  List<Map<String, dynamic>> _items(dynamic payload) {
    final items = payload is List
        ? payload
        : payload is Map<String, dynamic> && payload['results'] is List
            ? payload['results'] as List<dynamic>
            : throw const FormatException('Unexpected stories response.');
    return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }
}
