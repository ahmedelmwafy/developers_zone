import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  void _loadAd() {
    final adSettings = Provider.of<AppProvider>(context).adSettings;
    
    bool isAdMobEnabled = false;
    bool isBannerEnabled = false;

    if (Platform.isAndroid) {
      isAdMobEnabled = adSettings.adMobActiveAndroid;
      isBannerEnabled = adSettings.bannerAdsActiveAndroid;
    } else if (Platform.isIOS) {
      isAdMobEnabled = adSettings.adMobActiveIOS;
      isBannerEnabled = adSettings.bannerAdsActiveIOS;
    }

    if (!isAdMobEnabled || !isBannerEnabled) {
      if (_bannerAd != null) {
        _bannerAd!.dispose();
        _bannerAd = null;
        setState(() => _isLoaded = false);
      }
      return;
    }

    if (_bannerAd != null) return; // Already loading or loaded

    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
          _bannerAd = null;
          setState(() => _isLoaded = false);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: AdWidget(
        ad: _bannerAd!,
        key: ObjectKey(_bannerAd!),
      ),
    );
  }
}
