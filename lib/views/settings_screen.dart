import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'edit_profile_screen.dart';
import 'legal_screens.dart';
import 'profile_page.dart';
import 'splash_screen.dart';
import 'admin_dashboard_page.dart';
import 'blocked_users_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = authController.currentUser;
    final locale = AppLocalization.of(context)!;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(locale),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  _ProfileHeaderCard(
                    user: user,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (user.isAdmin) ...[
                    _SettingsSection(title: locale.translate('administrative'), items: [
                      _SettingsTile(
                        icon: Icons.admin_panel_settings_outlined,
                        iconColor: AppColors.accent,
                        title: locale.translate('admin'),
                        subtitle: locale.translate('admin_dashboard_sub'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
                        ),
                      ),
                    ]),
                  ],

                  _SettingsSection(title: locale.translate('account'), items: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      iconColor: AppColors.primary,
                      title: locale.translate('edit_profile'),
                      subtitle: locale.translate('edit_profile_sub'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.vpn_key_outlined,
                      iconColor: AppColors.accent,
                      title: locale.translate('change_password'),
                      subtitle: locale.translate('change_password_sub'),
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    _SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      iconColor: AppColors.warning,
                      title: locale.translate('notifications'),
                      subtitle: locale.translate('notifications_sub'),
                      onTap: () => _showNotificationSettings(context, authController),
                    ),
                    _SettingsTile(
                      icon: Icons.block_outlined,
                      iconColor: AppColors.error,
                      title: locale.translate('blocked_users'),
                      subtitle: locale.translate('blocked_users_sub'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BlockedUsersPage()),
                      ),
                    ),
                  ]),

                  _SettingsSection(title: locale.translate('preferences'), items: [
                    _SettingsTile(
                      icon: Icons.translate_rounded,
                      iconColor: AppColors.accentSecondary,
                      title: locale.translate('language'),
                      subtitle: Provider.of<AppProvider>(context).locale.languageCode == 'ar' ? 'العربية' : 'English',
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                      onTap: () {
                        final p = Provider.of<AppProvider>(context, listen: false);
                        p.setLocale(p.locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar'));
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const SplashScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ]),

                  _SettingsSection(title: locale.translate('legal'), items: [
                    _SettingsTile(
                      icon: Icons.description_outlined,
                      iconColor: AppColors.textSecondary,
                      title: locale.translate('privacy_policy'),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                    ),
                    _SettingsTile(
                      icon: Icons.policy_outlined,
                      iconColor: AppColors.textSecondary,
                      title: locale.translate('terms_conditions'),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsConditionsScreen())),
                    ),
                  ]),

                  _SettingsSection(title: locale.translate('danger_zone'), isDanger: true, items: [
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      iconColor: AppColors.error,
                      title: locale.translate('logout'),
                      titleColor: AppColors.error,
                      onTap: () => _confirmLogout(context, authController, locale),
                    ),
                    _SettingsTile(
                      icon: Icons.person_remove_outlined,
                      iconColor: AppColors.error,
                      title: locale.translate('delete_account'),
                      subtitle: locale.translate('delete_account_sub'),
                      titleColor: AppColors.error,
                      onTap: () => _confirmDelete(context, authController, locale),
                    ),
                  ]),

                  const SizedBox(height: 32),
                  const _VersionInfo(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(AppLocalization locale) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: AppColors.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        centerTitle: false,
        title: Text(
          locale.translate('settings'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final locale = AppLocalization.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(_).viewInsets.bottom + 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Text(locale.translate('change_password'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(locale.translate('strengthen_security'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            TextField(controller: passwordController, obscureText: true, decoration: AppWidgets.fieldDecoration(locale.translate('current_password'), prefixIcon: Icons.lock_outline)),
            const SizedBox(height: 16),
            TextField(controller: newPasswordController, obscureText: true, decoration: AppWidgets.fieldDecoration(locale.translate('new_password'), prefixIcon: Icons.password_rounded)),
            const SizedBox(height: 16),
            TextField(controller: confirmPasswordController, obscureText: true, decoration: AppWidgets.fieldDecoration(locale.translate('confirm_new_password'), prefixIcon: Icons.verified_user_outlined)),
            const SizedBox(height: 32),
            AppWidgets.gradientButton(label: locale.translate('update_credentials'), onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings(BuildContext context, AuthController auth) {
    final locale = AppLocalization.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          final user = auth.currentUser!;
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 24),
                Text(locale.translate('notification_preferences'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildSwitchTile(
                    locale.translate('email_updates'), 
                    locale.translate('email_updates_sub'), 
                    user.emailUpdates,
                    (v) async {
                      final updated = user.copyWith(emailUpdates: v);
                      await auth.updateProfile(updated);
                      setModalState(() {});
                    }
                ),
                _buildSwitchTile(
                    locale.translate('push_notifications_title'), 
                    locale.translate('push_notifications_sub'), 
                    user.pushNotifications,
                    (v) async {
                      final updated = user.copyWith(pushNotifications: v);
                      await auth.updateProfile(updated);
                      setModalState(() {});
                    }
                ),
                _buildSwitchTile(
                    locale.translate('collabs'), 
                    locale.translate('collabs_sub'), 
                    user.collabsNotifications,
                    (v) async {
                      final updated = user.copyWith(collabsNotifications: v);
                      await auth.updateProfile(updated);
                      setModalState(() {});
                    }
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value, 
            onChanged: onChanged, 
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthController auth, AppLocalization locale) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.fromLTRB(32, 12, 32, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 32),
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 40)),
            const SizedBox(height: 24),
            Text(locale.translate('logout'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(locale.translate('logout_confirm'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text(locale.translate('cancel')))),
                const SizedBox(width: 16),
                Expanded(child: ElevatedButton(onPressed: () async {
                  Navigator.pop(context);
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const SplashScreen()),
                      (route) => false,
                    );
                  }
                }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text(locale.translate('logout')))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AuthController auth, AppLocalization locale) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(locale.translate('delete_account'), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
        content: Text(locale.translate('delete_account_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(locale.translate('cancel'), style: const TextStyle(color: AppColors.textMuted))),
          TextButton(onPressed: () async {
            Navigator.pop(context);
            await auth.deleteAccount();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (route) => false,
              );
            }
          }, child: Text(locale.translate('confirm_deletion'), style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _ProfileHeaderCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
              child: CircleAvatar(
                radius: 35,
                backgroundImage: user.profileImage.isNotEmpty ? NetworkImage(user.profileImage) : null,
                child: user.profileImage.isEmpty ? const Icon(Icons.person, size: 35, color: AppColors.textMuted) : null,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.position.isNotEmpty ? user.position : locale.translate('dev_enthusiast'),
                    style: const TextStyle(color: AppColors.primaryLight, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsTile> items;
  final bool isDanger;
  const _SettingsSection({required this.title, required this.items, this.isDanger = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: isDanger ? AppColors.error : AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: List.generate(
              items.length,
              (i) => Column(
                children: [
                  items[i],
                  if (i < items.length - 1)
                    Divider(height: 1, indent: 64, color: Colors.white.withValues(alpha: 0.05)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.iconColor, required this.title, this.subtitle, this.trailing, this.titleColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))
          : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    );
  }
}

class _VersionInfo extends StatelessWidget {
  const _VersionInfo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_outlined, size: 14, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'Developers Zone Premium v1.0.1',
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Made with ❤️ for Developers',
            style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
