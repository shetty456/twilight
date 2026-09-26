# AdMob in a product app

`packages/ads` provides Google Mobile Ads setup, UMP consent handling, a banner widget, and one cached interstitial and rewarded ad. Apps choose their own ad placements and own their AdMob app IDs and ad unit IDs. The package is opt-in; the template app does not initialize the Ads SDK.

The workspace is pinned to Flutter 3.35.6, so this package uses `google_mobile_ads` 7.x. The current 8.x and 9.x releases require a newer Dart SDK. Recheck the plugin requirements when upgrading Flutter.

## 1. Create the AdMob entries

In AdMob, register each Android and iOS app separately. Create only the ad units the product will use. Keep the **app ID** (`~` separator) and **ad unit IDs** (`/` separator) distinct. Use the matching platform's IDs.

## 2. Add the package

In `apps/<product>/pubspec.yaml`:

```yaml
dependencies:
  ads:
    path: ../../packages/ads
```

Run `fvm flutter pub get` from the repository root.

## 3. Add native app IDs

Add this inside `<application>` in `apps/<product>/android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY" />
```

Add this inside `<dict>` in `apps/<product>/ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
```

These IDs are required even while using test ad units. For an app that has not yet been registered, Google's sample **app IDs** are Android `ca-app-pub-3940256099942544~3347511713` and iOS `ca-app-pub-3940256099942544~1458002511`. Replace them before release. If you use build flavors, set each flavor's native app ID to the corresponding AdMob app; see [flavors.md](flavors.md).

For iOS, check the plugin's current minimum deployment target and Google's [iOS setup](https://developers.google.com/admob/flutter/quick-start) when integrating. If the product requests tracking permission, configure its `NSUserTrackingUsageDescription` and ATT flow in the app. Follow Google's current iOS instructions for SKAdNetwork IDs. These platform declarations belong to the app.

## 4. Configure and start the service

Create one service for the app. Empty strings are allowed for formats the app does not use. Supply real IDs for every format that the release app does use. This example uses Google sample ad units in debug/profile and live IDs in release:

```dart
import 'package:ads/ads.dart';
import 'package:flutter/foundation.dart';

final ads = AdMobService(
  AdMobConfig(
    useTestAds: !kReleaseMode,
    android: const AdUnitIds(
      banner: 'YOUR_ANDROID_BANNER_UNIT_ID',
      interstitial: 'YOUR_ANDROID_INTERSTITIAL_UNIT_ID',
      rewarded: 'YOUR_ANDROID_REWARDED_UNIT_ID',
    ),
    ios: const AdUnitIds(
      banner: 'YOUR_IOS_BANNER_UNIT_ID',
      interstitial: 'YOUR_IOS_INTERSTITIAL_UNIT_ID',
      rewarded: 'YOUR_IOS_REWARDED_UNIT_ID',
    ),
  ),
);
```

Call `await ads.initialize()` once per app launch **after the first Flutter frame**, for example from a root widget's `initState` using `WidgetsBinding.instance.addPostFrameCallback`. This allows a required consent form to appear over the app UI. The returned `bool` says whether ads can currently be requested. Render `AdsBanner` or preload full-screen ads only when it is `true`. `initialize()` checks UMP consent before initializing the Ads SDK; it can be called again if consent was unavailable earlier. On web/desktop it returns `false`.

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final ready = await ads.initialize();
    if (!mounted) return;
    setState(() => adsReady = ready);
  });
}
```

In AdMob **Privacy & messaging**, create the message types needed for this product. UMP checks for updates every launch. When `await ads.privacyOptionsRequired` is `true`, add a visible settings action that calls `await ads.showPrivacyOptions()`. After privacy options change, check `await ads.canRequestAds()` before requesting more ads. If a product needs a different consent manager, adapt this package's consent flow before using live ads.

## 5. Place ads

Banner, in a screen that renders only after `adsReady`:

```dart
if (adsReady) AdsBanner(service: ads)
```

The banner uses Google's fixed 320×50 size. It frees its ad when removed from the widget tree. Place it in a layout with enough room, ideally within a `SafeArea`.

Interstitial, at a natural break such as the end of a level:

```dart
await ads.loadInterstitial(); // preload before the break
final shown = await ads.showInterstitial(); // false when no ad is ready
await ads.loadInterstitial(); // prepare the next one
```

Rewarded, only after the user explicitly chooses to watch:

```dart
await ads.loadRewarded();
final shown = await ads.showRewarded(
  onEarnedReward: (reward) {
    // Grant reward.amount of reward.type here, exactly once.
  },
);
await ads.loadRewarded();
```

`shown` means a preloaded ad was handed to the SDK; it does not confirm completion. Loading is asynchronous, so `show...()` can return `false` while a load is still in progress. Grant a reward only from `onEarnedReward`. Both full-screen formats are single-use and must be preloaded again after showing. Call `ads.dispose()` when the app-owned service is no longer needed.

## Before release

1. Use each platform's real AdMob **app ID** in its native file and real **ad unit IDs** in `AdMobConfig`.
2. Confirm `useTestAds` is `false` in release. Use Google's sample units or registered test devices during development; never exercise live ads while testing.
3. Configure and verify the product's privacy messages and any required privacy options entry point. Check the app's privacy policy, store disclosures, and child-directed settings for its audience.
4. Test consent, banner load/failure, full-screen close/failure, and reward callbacks on Android and iOS devices. AdMob ads require a native device or emulator; they do not run on Flutter web or desktop.

References: [Flutter quick start](https://developers.google.com/admob/flutter/quick-start), [UMP setup](https://developers.google.com/admob/flutter/privacy), [test ads](https://developers.google.com/admob/flutter/test-ads), [banner](https://developers.google.com/admob/flutter/banner), [interstitial](https://developers.google.com/admob/flutter/interstitial), [rewarded](https://developers.google.com/admob/flutter/rewarded).
