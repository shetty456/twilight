import 'package:ads/ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const liveAndroid = AdUnitIds(banner: 'android-banner');
  const liveIos = AdUnitIds(banner: 'ios-banner');

  test('uses Google sample units for both platforms in test mode', () {
    const config = AdMobConfig(android: liveAndroid, ios: liveIos);

    expect(
      config.idsFor(TargetPlatform.android).banner,
      AdMobConfig.androidTestIds.banner,
    );
    expect(
      config.idsFor(TargetPlatform.iOS).rewarded,
      AdMobConfig.iosTestIds.rewarded,
    );
  });

  test('uses product units in live mode and rejects unsupported platforms', () {
    const config = AdMobConfig(
      android: liveAndroid,
      ios: liveIos,
      useTestAds: false,
    );

    expect(config.idsFor(TargetPlatform.android).banner, 'android-banner');
    expect(config.idsFor(TargetPlatform.iOS).banner, 'ios-banner');
    expect(() => config.idsFor(TargetPlatform.macOS), throwsUnsupportedError);
  });
}
