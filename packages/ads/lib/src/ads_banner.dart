import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_mob_service.dart';

/// A fixed-size banner that owns and disposes its ad.
/// Mount it after [AdMobService.initialize] succeeds.
class AdsBanner extends StatefulWidget {
  const AdsBanner({required this.service, super.key});

  final AdMobService service;

  @override
  State<AdsBanner> createState() => _AdsBannerState();
}

class _AdsBannerState extends State<AdsBanner> {
  BannerAd? _ad;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!widget.service.isReady || !await widget.service.canRequestAds()) {
      return;
    }
    final generation = _generation;
    final id = widget.service.unitIds.banner;
    if (id.isEmpty) {
      debugPrint('AdMob banner: provide a banner ad unit ID.');
      return;
    }
    final ad = BannerAd(
      adUnitId: id,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || generation != _generation) {
            ad.dispose();
            return;
          }
          setState(() => _ad = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdMob banner: $error');
          ad.dispose();
        },
      ),
    );
    if (!mounted || generation != _generation) {
      unawaited(ad.dispose());
      return;
    }
    await ad.load();
  }

  @override
  void didUpdateWidget(covariant AdsBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      _generation++;
      _ad?.dispose();
      _ad = null;
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _generation++;
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
