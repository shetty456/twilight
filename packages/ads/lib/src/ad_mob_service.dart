import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_mob_config.dart';

/// Owns consent, SDK setup, and one cached ad of each full-screen format.
class AdMobService {
  AdMobService(this.config);

  final AdMobConfig config;
  Future<bool>? _initialization;
  bool _ready = false;
  bool _interstitialLoading = false;
  bool _rewardedLoading = false;
  bool _disposed = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  bool get isReady => _ready;

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  AdUnitIds get unitIds => config.idsFor(defaultTargetPlatform);

  /// Call once per app launch, after Flutter bindings are initialized.
  /// Returns false when consent does not permit requesting ads.
  Future<bool> initialize() {
    if (_disposed) throw StateError('AdMobService has been disposed.');
    return _initialization ??= _initialize().then((ready) {
      if (!ready) _initialization = null;
      return ready;
    });
  }

  Future<bool> _initialize() async {
    if (!isSupported) return false;
    final consentUpdated = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) {
            debugPrint('AdMob consent form: ${error.message}');
          }
          consentUpdated.complete();
        });
      },
      (error) {
        debugPrint('AdMob consent update: ${error.message}');
        consentUpdated.complete();
      },
    );
    await consentUpdated.future;

    if (!await ConsentInformation.instance.canRequestAds()) return false;
    await MobileAds.instance.initialize();
    _ready = !_disposed;
    return _ready;
  }

  /// Recheck consent after a privacy choice changes.
  Future<bool> canRequestAds() async =>
      isSupported && await ConsentInformation.instance.canRequestAds();

  Future<bool> get privacyOptionsRequired async {
    if (!isSupported) return false;
    return await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
  }

  /// Call from an app-provided privacy settings action when required.
  Future<bool> showPrivacyOptions() async {
    if (!isSupported) return false;
    final result = Completer<bool>();
    unawaited(
      ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) {
          debugPrint('AdMob privacy options: ${error.message}');
        }
        result.complete(error == null);
      }),
    );
    return result.future;
  }

  /// Preload at a natural transition; call again after the ad is shown.
  Future<void> loadInterstitial() async {
    if (_disposed ||
        !_ready ||
        !await canRequestAds() ||
        _interstitialLoading ||
        _interstitial != null) {
      return;
    }
    final id = unitIds.interstitial;
    if (id.isEmpty) throw StateError('Provide an interstitial AdMob unit ID.');
    _interstitialLoading = true;
    try {
      await InterstitialAd.load(
        adUnitId: id,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialLoading = false;
            if (_disposed) {
              ad.dispose();
            } else {
              _interstitial = ad;
            }
          },
          onAdFailedToLoad: (error) {
            _interstitialLoading = false;
            debugPrint('AdMob interstitial: $error');
          },
        ),
      );
    } catch (_) {
      _interstitialLoading = false;
      rethrow;
    }
  }

  /// Returns true when show was requested for a preloaded ad.
  Future<bool> showInterstitial() async {
    if (_disposed || !_ready || !await canRequestAds()) return false;
    final ad = _interstitial;
    if (ad == null) return false;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdMob interstitial display: $error');
        ad.dispose();
      },
    );
    try {
      await ad.show();
    } catch (_) {
      await ad.dispose();
      rethrow;
    }
    return true;
  }

  Future<void> loadRewarded() async {
    if (_disposed ||
        !_ready ||
        !await canRequestAds() ||
        _rewardedLoading ||
        _rewarded != null) {
      return;
    }
    final id = unitIds.rewarded;
    if (id.isEmpty) throw StateError('Provide a rewarded AdMob unit ID.');
    _rewardedLoading = true;
    try {
      await RewardedAd.load(
        adUnitId: id,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedLoading = false;
            if (_disposed) {
              ad.dispose();
            } else {
              _rewarded = ad;
            }
          },
          onAdFailedToLoad: (error) {
            _rewardedLoading = false;
            debugPrint('AdMob rewarded: $error');
          },
        ),
      );
    } catch (_) {
      _rewardedLoading = false;
      rethrow;
    }
  }

  /// Grant rewards only inside [onEarnedReward], never from the return value.
  Future<bool> showRewarded({
    required void Function(RewardItem) onEarnedReward,
  }) async {
    if (_disposed || !_ready || !await canRequestAds()) return false;
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (ad) => ad.dispose(),
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdMob rewarded display: $error');
        ad.dispose();
      },
    );
    try {
      await ad.show(onUserEarnedReward: (_, reward) => onEarnedReward(reward));
    } catch (_) {
      await ad.dispose();
      rethrow;
    }
    return true;
  }

  void dispose() {
    _disposed = true;
    _ready = false;
    _interstitial?.dispose();
    _rewarded?.dispose();
    _interstitial = null;
    _rewarded = null;
  }
}
