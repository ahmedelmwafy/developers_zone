import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/ad_model.dart';

class AdService {
  // AD UNIT IDs (Production)
  static const String androidBannerId = 'ca-app-pub-8083932237652497/5248840321';
  static const String androidInterstitialId = 'ca-app-pub-8083932237652497/5037816285';
  
  static const String iosBannerId = 'ca-app-pub-8083932237652497/4079228884';
  static const String iosInterstitialId = 'ca-app-pub-8083932237652497/9272574768';

  // TEST IDs (Fallbacks)
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  static String get bannerAdUnitId {
    if (kDebugMode) return testBannerId;
    if (Platform.isAndroid) return androidBannerId;
    if (Platform.isIOS) return iosBannerId;
    return testBannerId;
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) return testInterstitialId;
    if (Platform.isAndroid) return androidInterstitialId;
    if (Platform.isIOS) return iosInterstitialId;
    return testInterstitialId;
  }

  static InterstitialAd? _interstitialAd;
  static int _interstitialAdLoadAttempts = 0;
  static const int maxLoadAttempts = 3;

  static Future<void> loadInterstitialAd({AdSettingsModel? settings}) async {
    // Check platform-specific active status
    bool isAdMobEnabled = false;
    bool isInterstitialEnabled = false;

    if (settings != null) {
      if (Platform.isAndroid) {
        isAdMobEnabled = settings.adMobActiveAndroid;
        isInterstitialEnabled = settings.interstitialAdsActiveAndroid;
      } else if (Platform.isIOS) {
        isAdMobEnabled = settings.adMobActiveIOS;
        isInterstitialEnabled = settings.interstitialAdsActiveIOS;
      }
    }

    if (!isAdMobEnabled || !isInterstitialEnabled) {
       debugPrint('InterstitialAd skipped: Admin has disabled AdMob or Interstitials for this platform.');
       return;
    }

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAdLoadAttempts = 0;
          debugPrint('InterstitialAd loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          _interstitialAdLoadAttempts++;
          _interstitialAd = null;
          debugPrint('InterstitialAd failed to load: $error');
          if (_interstitialAdLoadAttempts <= maxLoadAttempts) {
            loadInterstitialAd(settings: settings);
          }
        },
      ),
    );
  }

  static void showInterstitialAd({AdSettingsModel? settings}) {
    bool isAdMobEnabled = true; // Default true if no settings provided, though usually we pass settings
    bool isInterstitialEnabled = true;

    if (settings != null) {
      if (Platform.isAndroid) {
        isAdMobEnabled = settings.adMobActiveAndroid;
        isInterstitialEnabled = settings.interstitialAdsActiveAndroid;
      } else if (Platform.isIOS) {
        isAdMobEnabled = settings.adMobActiveIOS;
        isInterstitialEnabled = settings.interstitialAdsActiveIOS;
      }
    }

    if (!isAdMobEnabled || !isInterstitialEnabled || _interstitialAd == null) {
      if (_interstitialAd == null && isAdMobEnabled && isInterstitialEnabled) {
        debugPrint('Warning: attempt to show interstitial before loaded.');
      }
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitialAd(settings: settings);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadInterstitialAd(settings: settings);
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }
}
