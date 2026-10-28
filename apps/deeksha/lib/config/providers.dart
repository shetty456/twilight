import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network/network.dart';
import 'package:storage/storage.dart';

import '../data/origin_repository.dart';
import '../stories/models/story_models.dart';
import 'product_config.dart';

final productNameProvider = Provider<String>((ref) => ProductConfig.appName);

final phoneAuthRepositoryProvider = Provider<OriginPhoneAuthRepository>((ref) {
  return OriginPhoneAuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(authTokenStoreProvider)!,
  );
});

final storiesRepositoryProvider = Provider<OriginStoriesRepository>((ref) {
  return OriginStoriesRepository(ref.watch(dioClientProvider));
});

final sessionProvider =
    StateNotifierProvider<SessionController, AsyncValue<bool>>((ref) {
  return SessionController(ref.watch(phoneAuthRepositoryProvider), ref);
});

class SessionController extends StateNotifier<AsyncValue<bool>> {
  SessionController(this._repository, this._ref) : super(const AsyncLoading()) {
    restore();
  }

  final OriginPhoneAuthRepository _repository;
  final Ref _ref;

  void _refreshStories() {
    _ref.invalidate(seriesProvider);
    _ref.invalidate(episodesProvider);
    _ref.invalidate(episodeMediaProvider);
  }

  Future<void> restore() async {
    state = await AsyncValue.guard(_repository.hasSession);
  }

  Future<void> verify(String phone, String code) async {
    await _repository.verifyCode(phone, code);
    _refreshStories();
    state = const AsyncData(true);
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncData(false);
  }
}

final seriesProvider = FutureProvider<List<StorySeries>>((ref) {
  return ref.watch(storiesRepositoryProvider).series();
});

final episodesProvider =
    FutureProvider.family<List<StoryEpisode>, String>((ref, seriesId) {
  return ref.watch(storiesRepositoryProvider).episodes(seriesId);
});

final episodeMediaProvider =
    FutureProvider.family<EpisodeMedia, String>((ref, episodeId) {
  return ref.watch(storiesRepositoryProvider).media(episodeId);
});

List<Override> buildProviderOverrides() {
  final config = ProductConfig.api();
  return [
    apiConfigProvider.overrideWithValue(config),
    authTokenStoreProvider.overrideWithValue(SecureAuthTokenStore(
      key: ProductConfig.tokenKey(config),
    )),
  ];
}
