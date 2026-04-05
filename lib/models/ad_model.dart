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
  final bool adMobActiveAndroid;
  final bool adMobActiveIOS;
  final bool bannerAdsActiveAndroid;
  final bool bannerAdsActiveIOS;
  final bool interstitialAdsActiveAndroid;
  final bool interstitialAdsActiveIOS;
  final bool splashCustomAdActive;
  final bool homeCustomAdActive;
  final bool anonymousCommunityActive;

  AdSettingsModel({
    this.adMobActiveAndroid = false,
    this.adMobActiveIOS = false,
    this.bannerAdsActiveAndroid = false,
    this.bannerAdsActiveIOS = false,
    this.interstitialAdsActiveAndroid = false,
    this.interstitialAdsActiveIOS = false,
    this.splashCustomAdActive = true,
    this.homeCustomAdActive = true,
    this.anonymousCommunityActive = false,
  });

  factory AdSettingsModel.fromMap(Map<String, dynamic> data) {
    return AdSettingsModel(
      adMobActiveAndroid: data['adMobActiveAndroid'] ?? data['adMobActive'] ?? false,
      adMobActiveIOS: data['adMobActiveIOS'] ?? data['adMobActive'] ?? false,
      bannerAdsActiveAndroid: data['bannerAdsActiveAndroid'] ?? data['bannerAdsActive'] ?? false,
      bannerAdsActiveIOS: data['bannerAdsActiveIOS'] ?? data['bannerAdsActive'] ?? false,
      interstitialAdsActiveAndroid: data['interstitialAdsActiveAndroid'] ?? data['interstitialAdsActive'] ?? false,
      interstitialAdsActiveIOS: data['interstitialAdsActiveIOS'] ?? data['interstitialAdsActive'] ?? false,
      splashCustomAdActive: data['splashCustomAdActive'] ?? true,
      homeCustomAdActive: data['homeCustomAdActive'] ?? true,
      anonymousCommunityActive: data['anonymousCommunityActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adMobActiveAndroid': adMobActiveAndroid,
      'adMobActiveIOS': adMobActiveIOS,
      'bannerAdsActiveAndroid': bannerAdsActiveAndroid,
      'bannerAdsActiveIOS': bannerAdsActiveIOS,
      'interstitialAdsActiveAndroid': interstitialAdsActiveAndroid,
      'interstitialAdsActiveIOS': interstitialAdsActiveIOS,
      'splashCustomAdActive': splashCustomAdActive,
      'homeCustomAdActive': homeCustomAdActive,
      'anonymousCommunityActive': anonymousCommunityActive,
    };
  }

  AdSettingsModel copyWith({
    bool? adMobActiveAndroid,
    bool? adMobActiveIOS,
    bool? bannerAdsActiveAndroid,
    bool? bannerAdsActiveIOS,
    bool? interstitialAdsActiveAndroid,
    bool? interstitialAdsActiveIOS,
    bool? splashCustomAdActive,
    bool? homeCustomAdActive,
    bool? anonymousCommunityActive,
  }) {
    return AdSettingsModel(
      adMobActiveAndroid: adMobActiveAndroid ?? this.adMobActiveAndroid,
      adMobActiveIOS: adMobActiveIOS ?? this.adMobActiveIOS,
      bannerAdsActiveAndroid: bannerAdsActiveAndroid ?? this.bannerAdsActiveAndroid,
      bannerAdsActiveIOS: bannerAdsActiveIOS ?? this.bannerAdsActiveIOS,
      interstitialAdsActiveAndroid: interstitialAdsActiveAndroid ?? this.interstitialAdsActiveAndroid,
      interstitialAdsActiveIOS: interstitialAdsActiveIOS ?? this.interstitialAdsActiveIOS,
      splashCustomAdActive: splashCustomAdActive ?? this.splashCustomAdActive,
      homeCustomAdActive: homeCustomAdActive ?? this.homeCustomAdActive,
      anonymousCommunityActive: anonymousCommunityActive ?? this.anonymousCommunityActive,
    );
  }
}
