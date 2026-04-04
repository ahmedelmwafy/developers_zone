
class AdModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? targetUrl;
  final bool active;
  final String type; // splash, home

  AdModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.targetUrl,
    this.active = true,
    required this.type,
  });

  factory AdModel.fromMap(Map<String, dynamic> data, String docId) {
    return AdModel(
      id: docId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      targetUrl: data['targetUrl'],
      active: data['active'] ?? true,
      type: data['type'] ?? 'home',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'targetUrl': targetUrl,
      'active': active,
      'type': type,
    };
  }
}

class AdSettingsModel {
  final bool adMobActive;
  final bool bannerAdsActive;
  final bool interstitialAdsActive;
  final bool splashCustomAdActive;
  final bool homeCustomAdActive;

  AdSettingsModel({
    this.adMobActive = false,
    this.bannerAdsActive = false,
    this.interstitialAdsActive = false,
    this.splashCustomAdActive = false,
    this.homeCustomAdActive = false,
  });

  factory AdSettingsModel.fromMap(Map<String, dynamic> data) {
    return AdSettingsModel(
      adMobActive: data['adMobActive'] ?? false,
      bannerAdsActive: data['bannerAdsActive'] ?? false,
      interstitialAdsActive: data['interstitialAdsActive'] ?? false,
      splashCustomAdActive: data['splashCustomAdActive'] ?? false,
      homeCustomAdActive: data['homeCustomAdActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adMobActive': adMobActive,
      'bannerAdsActive': bannerAdsActive,
      'interstitialAdsActive': interstitialAdsActive,
      'splashCustomAdActive': splashCustomAdActive,
      'homeCustomAdActive': homeCustomAdActive,
    };
  }

  AdSettingsModel copyWith({
    bool? adMobActive,
    bool? bannerAdsActive,
    bool? interstitialAdsActive,
    bool? splashCustomAdActive,
    bool? homeCustomAdActive,
  }) {
    return AdSettingsModel(
      adMobActive: adMobActive ?? this.adMobActive,
      bannerAdsActive: bannerAdsActive ?? this.bannerAdsActive,
      interstitialAdsActive: interstitialAdsActive ?? this.interstitialAdsActive,
      splashCustomAdActive: splashCustomAdActive ?? this.splashCustomAdActive,
      homeCustomAdActive: homeCustomAdActive ?? this.homeCustomAdActive,
    );
  }
}
