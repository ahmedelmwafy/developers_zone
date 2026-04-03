import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ad_model.dart';
import '../controllers/admin_controller.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

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
              label: const Text('New Ad', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AdModel>>(
        stream: adminController.getAds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(color: AppColors.cardLight, shape: BoxShape.circle),
                    child: const Icon(Icons.campaign_outlined, size: 36, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  const Text('No ads yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Tap "+ New Ad" to create your first ad', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            );
          }

          final ads = snapshot.data!;
          // Group by type
          final homeAds = ads.where((a) => a.type == 'home').toList();
          final splashAds = ads.where((a) => a.type == 'splash').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (homeAds.isNotEmpty) ...[
                AppWidgets.sectionTitle('Home Ads'),
                ...homeAds.map((ad) => _AdCard(ad: ad, adminController: adminController)),
                const SizedBox(height: 8),
              ],
              if (splashAds.isNotEmpty) ...[
                AppWidgets.sectionTitle('Splash Ads'),
                ...splashAds.map((ad) => _AdCard(ad: ad, adminController: adminController)),
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
    final targetUrlController = TextEditingController();
    String selectedType = 'home';
    final adminController = Provider.of<AdminController>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              // Handle bar
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
              const Text('Create New Ad', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Add an ad to appear in the home feed or splash screen', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: AppWidgets.fieldDecoration('Ad Title', prefixIcon: Icons.title),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: imageUrlController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: AppWidgets.fieldDecoration('Image URL', prefixIcon: Icons.image_outlined),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: targetUrlController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: AppWidgets.fieldDecoration('Target URL (optional)', prefixIcon: Icons.link),
              ),
              const SizedBox(height: 14),
              const Text('Ad Type', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: ['home', 'splash'].map((type) {
                  final isSelected = selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: type == 'home' ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.primaryGradient : null,
                          color: isSelected ? null : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Center(
                          child: Text(
                            type[0].toUpperCase() + type.substring(1),
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                label: 'Create Ad',
                icon: Icons.rocket_launch_outlined,
                onPressed: () {
                  adminController.addAd(AdModel(
                    id: '',
                    title: titleController.text.trim(),
                    imageUrl: imageUrlController.text.trim(),
                    targetUrl: targetUrlController.text.trim(),
                    type: selectedType,
                  ));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
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
          color: ad.active ? AppColors.success.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
            child: SizedBox(
              width: 90,
              height: 80,
              child: Image.network(
                ad.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.cardLight,
                  child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ad.title.isNotEmpty ? ad.title : 'Untitled Ad', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(ad.type, style: const TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: ad.active ? AppColors.success : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      ad.active ? 'Active' : 'Inactive',
                      style: TextStyle(color: ad.active ? AppColors.success : AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: ad.active,
                  onChanged: (val) => adminController.updateAd(
                    AdModel(id: ad.id, title: ad.title, imageUrl: ad.imageUrl, targetUrl: ad.targetUrl, active: val, type: ad.type),
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
                  child: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
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
        title: const Text('Delete Ad', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete "${ad.title}"?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              adminController.deleteAd(ad.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
