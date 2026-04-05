import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/ad_model.dart';
import '../controllers/admin_controller.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../services/imgbb_service.dart';

class AdManagementPage extends StatelessWidget {
  const AdManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final adminController = Provider.of<AdminController>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppWidgets.appBar(
        locale.translate('ads'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _showAddAdDialog(context),
              icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
              label: Text(locale.translate('new_ad'),
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AdModel>>(
        stream: adminController.getAds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        color: AppColors.cardLight, shape: BoxShape.circle),
                    child: const Icon(Icons.campaign_outlined,
                        size: 36, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  Text(locale.translate('no_ads_yet'),
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(locale.translate('tap_new_ad_hint'),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            );
          }

          final ads = snapshot.data!;
          final homeAds = ads.where((a) => a.type == 'home').toList();
          final splashAds = ads.where((a) => a.type == 'splash').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _GlobalAdSettings(adminController: adminController),
              const SizedBox(height: 24),
              if (homeAds.isNotEmpty) ...[
                AppWidgets.sectionTitle(locale.translate('home_ads')),
                ...homeAds.map(
                    (ad) => _AdCard(ad: ad, adminController: adminController)),
                const SizedBox(height: 8),
              ],
              if (splashAds.isNotEmpty) ...[
                AppWidgets.sectionTitle(locale.translate('splash_ads')),
                ...splashAds.map(
                    (ad) => _AdCard(ad: ad, adminController: adminController)),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showAddAdDialog(BuildContext context) {
    final titleController = TextEditingController();
    final imageUrlController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetUrlController = TextEditingController();
    String selectedType = 'home';
    final adminController =
        Provider.of<AdminController>(context, listen: false);
    final locale = AppLocalization.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        File? selectedImage;
        bool isUploading = false;

        return StatefulBuilder(
          builder: (context, setModalState) => Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(locale.translate('create_new_ad'),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(locale.translate('add_ad_desc'),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: AppWidgets.fieldDecoration(
                      locale.translate('ad_title'),
                      prefixIcon: Icons.title),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: isUploading
                      ? null
                      : () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setModalState(
                                () => selectedImage = File(pickedFile.path));
                          }
                        },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: selectedImage != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(selectedImage!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () =>
                                      setModalState(() => selectedImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined,
                                  color: AppColors.primary, size: 32),
                              const SizedBox(height: 8),
                              Text(locale.translate('DROP_IMAGE_PAYLOAD'),
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: imageUrlController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: AppWidgets.fieldDecoration(
                      locale.translate('image_url'),
                      prefixIcon: Icons.link_rounded),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: AppWidgets.fieldDecoration(
                      locale.translate('ad_description'),
                      prefixIcon: Icons.description_outlined),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: targetUrlController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: AppWidgets.fieldDecoration(
                      locale.translate('target_url_optional'),
                      prefixIcon: Icons.link_rounded),
                ),
                const SizedBox(height: 14),
                Text(locale.translate('ad_type'),
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: ['home', 'splash'].map((type) {
                    final isSelected = selectedType == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedType = type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin:
                              EdgeInsets.only(right: type == 'home' ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient:
                                isSelected ? AppColors.primaryGradient : null,
                            color: isSelected ? null : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Center(
                            child: Text(
                              type == 'home'
                                  ? locale.translate('home_ad')
                                  : locale.translate('splash_ad'),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                AppWidgets.gradientButton(
                  label: isUploading
                      ? locale.translate('purging_repo')
                      : locale.translate('initialize_campaign'),
                  icon: isUploading ? null : Icons.rocket_launch_outlined,
                  isLoading: isUploading,
                  onPressed: isUploading
                      ? null
                      : () async {
                          String finalUrl = imageUrlController.text.trim();
                          if (selectedImage != null) {
                            setModalState(() => isUploading = true);
                            try {
                              final uploadUrl = await ImgBBService.uploadImage(
                                  selectedImage!);
                              if (uploadUrl != null) finalUrl = uploadUrl;
                            } finally {
                              setModalState(() => isUploading = false);
                            }
                          }
                          if (finalUrl.isEmpty) {
                            AppWidgets.showSnackBar(
                                context, locale.translate('fill_all_fields'));
                            return;
                          }
                          adminController.addAd(AdModel(
                            id: '',
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            imageUrl: finalUrl,
                            targetUrl: targetUrlController.text.trim(),
                            type: selectedType,
                          ));
                          Navigator.pop(context);
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdCard extends StatelessWidget {
  final AdModel ad;
  final AdminController adminController;
  const _AdCard({required this.ad, required this.adminController});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ad.active
              ? AppColors.success.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
            child: SizedBox(
              width: 90,
              height: 80,
              child: Image.network(
                ad.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.cardLight,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: AppColors.textMuted, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    ad.title.isNotEmpty
                        ? ad.title
                        : AppLocalization.of(context)!.translate('untitled_ad'),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(ad.type,
                      style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color:
                            ad.active ? AppColors.success : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      ad.active
                          ? AppLocalization.of(context)!.translate('active')
                          : AppLocalization.of(context)!.translate('inactive'),
                      style: TextStyle(
                          color: ad.active
                              ? AppColors.success
                              : AppColors.textMuted,
                          fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: ad.active,
                  onChanged: (val) => adminController.updateAd(
                    ad.copyWithActive(val),
                  ),
                  activeThumbColor: AppColors.success,
                  inactiveThumbColor: AppColors.textMuted,
                  inactiveTrackColor: AppColors.cardLight,
                ),
              ),
              InkWell(
                onTap: () => _confirmDelete(context),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
            AppLocalization.of(context)!.translate('delete_ad_confirm_title'),
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        content: Text(
            AppLocalization.of(context)!
                .translate('delete_ad_confirm_content')
                .replaceFirst('{}', ad.title),
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalization.of(context)!.translate('cancel'),
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              adminController.deleteAd(ad.id);
              Navigator.pop(context);
            },
            child: Text(AppLocalization.of(context)!.translate('delete'),
                style: const TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _GlobalAdSettings extends StatelessWidget {
  final AdminController adminController;
  const _GlobalAdSettings({required this.adminController});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;

    return StreamBuilder<AdSettingsModel>(
      stream: adminController.getAdSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data ?? AdSettingsModel();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.translate('global_ad_settings'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              
              // ADMOB MASTER SWITCHES
              _PlatformToggleGroup(
                title: locale.translate('admob_enabled'),
                androidValue: settings.adMobActiveAndroid,
                iosValue: settings.adMobActiveIOS,
                onAndroidChanged: (v) => adminController.updateAdSettings(
                  settings.copyWith(adMobActiveAndroid: v),
                ),
                onIosChanged: (v) => adminController.updateAdSettings(
                  settings.copyWith(adMobActiveIOS: v),
                ),
              ),
              const Divider(color: Colors.white10, height: 32),
              
              // BANNER SWITCHES
              _PlatformToggleGroup(
                title: locale.translate('banner_ads'),
                androidValue: settings.bannerAdsActiveAndroid,
                iosValue: settings.bannerAdsActiveIOS,
                onAndroidChanged: (v) => adminController.updateAdSettings(
                  settings.copyWith(bannerAdsActiveAndroid: v),
                ),
                onIosChanged: (v) => adminController.updateAdSettings(
                  settings.copyWith(bannerAdsActiveIOS: v),
                ),
              ),
              const Divider(color: Colors.white10, height: 32),
              
              // INTERSTITIAL SWITCHES
              _PlatformToggleGroup(
                title: locale.translate('interstitial_ads'),
                androidValue: settings.interstitialAdsActiveAndroid,
                iosValue: settings.interstitialAdsActiveIOS,
                onAndroidChanged: (v) => adminController.updateAdSettings(
                  settings.copyWith(interstitialAdsActiveAndroid: v),
                ),
                onIosChanged: (v) => adminController.updateAdSettings(
                  settings.copyWith(interstitialAdsActiveIOS: v),
                ),
              ),
              const Divider(color: Colors.white10, height: 32),
              
              // CUSTOM ADS
              _ToggleRow(
                label: locale.translate('splash_custom_ads'),
                value: settings.splashCustomAdActive,
                onChanged: (val) => adminController.updateAdSettings(
                  settings.copyWith(splashCustomAdActive: val),
                ),
              ),
              _ToggleRow(
                label: locale.translate('home_custom_ads'),
                value: settings.homeCustomAdActive,
                onChanged: (val) => adminController.updateAdSettings(
                  settings.copyWith(homeCustomAdActive: val),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlatformToggleGroup extends StatelessWidget {
  final String title;
  final bool androidValue;
  final bool iosValue;
  final ValueChanged<bool> onAndroidChanged;
  final ValueChanged<bool> onIosChanged;

  const _PlatformToggleGroup({
    required this.title,
    required this.androidValue,
    required this.iosValue,
    required this.onAndroidChanged,
    required this.onIosChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, 
          style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _ToggleRow(
          label: 'Android',
          icon: Icons.android,
          value: androidValue,
          onChanged: onAndroidChanged,
        ),
        _ToggleRow(
          label: 'iOS',
          icon: Icons.apple,
          value: iosValue,
          onChanged: onIosChanged,
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}

extension on AdModel {
  AdModel copyWithActive(bool active) {
    return AdModel(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl,
      targetUrl: targetUrl,
      active: active,
      type: type,
    );
  }
}
