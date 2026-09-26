import 'package:flutter/foundation.dart';

/// Unit IDs belong to one platform and one AdMob application.
class AdUnitIds {
  const AdUnitIds({
    this.banner = '',
    this.interstitial = '',
    this.rewarded = '',
  });

  final String banner;
  final String interstitial;
  final String rewarded;
}

/// App-owned ad unit IDs. Google sample units are selected in test mode.
class AdMobConfig {
  const AdMobConfig({
    required this.android,
    required this.ios,
    this.useTestAds = true,
  });

  final AdUnitIds android;
  final AdUnitIds ios;
  final bool useTestAds;

  static const AdUnitIds androidTestIds = AdUnitIds(
    banner: 'ca-app-pub-3940256099942544/6300978111',
    interstitial: 'ca-app-pub-3940256099942544/1033173712',
    rewarded: 'ca-app-pub-3940256099942544/5224354917',
  );

  static const AdUnitIds iosTestIds = AdUnitIds(
    banner: 'ca-app-pub-3940256099942544/2934735716',
    interstitial: 'ca-app-pub-3940256099942544/4411468910',
    rewarded: 'ca-app-pub-3940256099942544/1712485313',
  );

  /// Throws for unsupported platforms.
  AdUnitIds idsFor(TargetPlatform platform) {
    final AdUnitIds ids;
    switch (platform) {
      case TargetPlatform.android:
        ids = useTestAds ? androidTestIds : android;
      case TargetPlatform.iOS:
        ids = useTestAds ? iosTestIds : ios;
      default:
        throw UnsupportedError('AdMob supports Android and iOS only.');
    }
    return ids;
  }
}
