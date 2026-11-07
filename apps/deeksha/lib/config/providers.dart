import 'package:auth/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network/network.dart';
import 'package:storage/storage.dart';

import '../data/origin_repository.dart';
import '../data/origin_google_auth_repository.dart';
import '../stories/models/story_models.dart';
import 'product_config.dart';

final productNameProvider = Provider<String>((ref) => ProductConfig.appName);

final phoneAuthRepositoryProvider = Provider<OriginPhoneAuthRepository>((ref) {
  return OriginPhoneAuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(authTokenStoreProvider)!,
  );
});

final googleIdentityProvider = Provider<GoogleIdentityProvider>((ref) {
  return GoogleSignInIdentityProvider(
    serverClientId: ProductConfig.googleServerClientId,
    clientId:
        defaultTargetPlatform != TargetPlatform.iOS ||
            ProductConfig.googleIosClientId.isEmpty
        ? null
        : ProductConfig.googleIosClientId,
  );
});

final googleAuthRepositoryProvider = Provider<OriginGoogleAuthRepository>((
  ref,
) {
  return OriginGoogleAuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(authTokenStoreProvider)!,
    ref.watch(googleIdentityProvider),
  );
});

final storiesRepositoryProvider = Provider<OriginStoriesRepository>((ref) {
  return OriginStoriesRepository(ref.watch(dioClientProvider));
});

final sessionProvider =
    StateNotifierProvider<SessionController, AsyncValue<bool>>((ref) {
      return SessionController(
        ProductConfig.googleAuthEnabled
            ? ref.watch(googleAuthRepositoryProvider)
            : null,
        ref.watch(phoneAuthRepositoryProvider),
        ref,
      );
    });

final signedInProfileProvider = FutureProvider<SignedInProfile?>((ref) {
  return ref.watch(googleAuthRepositoryProvider).signedInProfile();
});

class SessionController extends StateNotifier<AsyncValue<bool>> {
  SessionController(this._repository, this._phoneRepository, this._ref)
    : super(const AsyncLoading()) {
    restore();
  }

  final OriginGoogleAuthRepository? _repository;
  final OriginPhoneAuthRepository _phoneRepository;
  final Ref _ref;

  void _refreshStories() {
    _ref.invalidate(seriesProvider);
    _ref.invalidate(episodesProvider);
    _ref.invalidate(episodeMediaProvider);
  }

  Future<void> restore() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      _repository?.hasSession ?? _phoneRepository.hasSession,
    );
  }

  Future<bool> signInWithGoogle() async {
    final completed = await _repository!.signIn();
    if (!completed) return false;
    _refreshStories();
    _ref.invalidate(signedInProfileProvider);
    state = const AsyncData(true);
    return true;
  }

  Future<void> verify(String phone, String code) async {
    await _phoneRepository.verifyCode(phone, code);
    _refreshStories();
    _ref.invalidate(signedInProfileProvider);
    state = const AsyncData(true);
  }

  Future<void> signOut() async {
    if (_repository case final google?) {
      await google.signOut();
    } else {
      await _phoneRepository.signOut();
    }
    _ref.invalidate(signedInProfileProvider);
    state = const AsyncData(false);
  }
}

final seriesProvider = FutureProvider<List<StorySeries>>((ref) {
  return ref.watch(storiesRepositoryProvider).series();
});

final episodesProvider = FutureProvider.family<List<StoryEpisode>, String>((
  ref,
  seriesId,
) {
  return ref.watch(storiesRepositoryProvider).episodes(seriesId);
});

final episodeMediaProvider = FutureProvider.family<EpisodeMedia, String>((
  ref,
  episodeId,
) {
  return ref.watch(storiesRepositoryProvider).media(episodeId);
});

List<Override> buildProviderOverrides() {
  final config = ProductConfig.api();
  return [
    apiConfigProvider.overrideWithValue(config),
    authTokenStoreProvider.overrideWithValue(
      SecureAuthTokenStore(key: ProductConfig.tokenKey(config)),
    ),
  ];
}
