import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../providers/app_provider.dart';
import 'splash_screen.dart';
import 'admin_dashboard_page.dart';
import 'network_page.dart';
import 'edit_profile_page.dart';
import 'saved_posts_page.dart';
import 'legal_screens.dart';
import '../widgets/terminal_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final user = auth.currentUser;
    final locale = AppLocalization.of(context)!;

    if (user == null) {
      return const Scaffold(
          backgroundColor: Color(0xFF0D0D0D),
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFF00E5FF))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(locale),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    _buildHeroHeader(locale),
                    const SizedBox(height: 40),
                    if (user.isAdmin) ...[
                      _SectionTitle(
                          icon: Icons.admin_panel_settings_outlined,
                          title: locale
                              .translate('MANAGEMENT_PROTOCOLS')
                              .toUpperCase()),
                      _buildAdminCard(context, locale),
                      const SizedBox(height: 48),
                    ],
                    _SectionTitle(
                        icon: Icons.person_outline_rounded,
                        title: locale
                            .translate('ACCOUNT_MANAGEMENT')
                            .toUpperCase()),
                    _buildNavCard(
                      icon: Icons.edit_note_rounded,
                      title: locale.translate('edit_profile'),
                      subtitle: locale.translate('edit_profile_sub'),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfilePage())),
                    ),
                    const SizedBox(height: 16),
                    _buildNavCard(
                      icon: Icons.bookmark_rounded,
                      title: locale.translate('SAVED_MANIFESTS_CAPS'),
                      subtitle: locale
                          .translate('no_saved_posts')
                          .replaceFirst('No ', 'View your '),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SavedPostsPage())),
                    ),
                    const SizedBox(height: 48),
                    _SectionTitle(
                        icon: Icons.shield_outlined,
                        title: locale.translate('SECURITY_LOGS').toUpperCase()),
                    _buildSecurityCard(locale),
                    const SizedBox(height: 48),
                    _SectionTitle(
                        icon: Icons.tune_rounded,
                        title:
                            locale.translate('ZONE_PREFERENCES').toUpperCase()),
                    _buildPreferencesCard(locale),
                    const SizedBox(height: 48),
                    _SectionTitle(
                        icon: Icons.gavel_rounded,
                        title: locale.translate('legal').toUpperCase()),
                    _buildLegalCard(locale),
                    const SizedBox(height: 60),
                    _buildLogoutButton(auth, locale),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalization locale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Color(0xFF00E5FF)),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.person_search_rounded,
                      color: Color(0xFF00E5FF), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'DEVELOPERS ZONE',
                    style: AppLocalization.digitalFont(
                      context,
                      color: const Color(0xFF00E5FF),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.help_outline_rounded,
              color: Colors.white.withOpacity(0.3), size: 24),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(AppLocalization locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFF00E5FF), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                locale.translate('CORE_CONFIG'),
                style: AppLocalization.digitalFont(
                  context,
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          locale.translate('settings'),
          style: AppLocalization.digitalFont(
            context,
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          locale.translate('ACCOUNT_MANAGEMENT_SUB'),
          style: AppLocalization.digitalFont(
            context,
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildNavCard(
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF00E5FF), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppLocalization.digitalFont(context,
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: AppLocalization.digitalFont(context,
                          color: Colors.white.withOpacity(0.4), fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.2), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, AppLocalization locale) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2979FF).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2979FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.print_rounded,
                      color: Color(0xFF2979FF), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(locale.translate('admin_dashboard_title'),
                          style: AppLocalization.digitalFont(context,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text(locale.translate('admin_dashboard_sub'),
                          style: AppLocalization.digitalFont(context,
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _OutlineButton(
            label: locale.translate('INITIALIZE_TERMINAL'),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminDashboardPage())),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(AppLocalization locale) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _SecurityItem(
            title: locale.translate('blocked_users'),
            subtitle: locale.translate('blocked_users_sub'),
            trailing: _OutlineButton(
              label: locale.translate('VIEW_LIST').toUpperCase(),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NetworkPage(
                            initialTab: NetworkTab.blocked,
                            isSingleMode: true,
                          ))),
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.03), height: 1),
          _SecurityItem(
            title: locale.translate('change_password'),
            subtitle: locale.translate('change_password_sub'),
            trailing: _OutlineButton(
              label: locale.translate('edit').toUpperCase(),
              onPressed: _showChangePasswordDialog,
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.03), height: 1),
          _SecurityItem(
            title: locale.translate('delete_account'),
            subtitle: locale.translate('delete_account_sub'),
            trailing: _OutlineButton(
              label: locale.translate('delete').toUpperCase(),
              onPressed: _showDeleteAccountConfirm,
              isDanger: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(AppLocalization locale) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildLanguageSwitcher(locale),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitcher(AppLocalization locale) {
    final appProvider = Provider.of<AppProvider>(context);
    final isAr = appProvider.locale.languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(locale.translate('language'),
                  style: AppLocalization.digitalFont(context,
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              Text(locale.translate('INTERFACE_LANGUAGE'),
                  style: AppLocalization.digitalFont(context,
                      color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _LangBtn(
                  label: locale.translate('EN'),
                  isActive: !isAr,
                  onTap: () => appProvider.setLocale(const Locale('en')),
                ),
                const SizedBox(width: 8),
                _LangBtn(
                  label: locale.translate('AR'),
                  isActive: isAr,
                  onTap: () => appProvider.setLocale(const Locale('ar')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(AuthController auth, AppLocalization locale) {
    return GestureDetector(
      onTap: () => _showLogoutConfirmation(auth),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              locale.translate('logout').toUpperCase(),
              style: AppLocalization.digitalFont(
                context,
                color: Colors.redAccent,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              locale.translate('DISCONNECT_NODE_SESSION'),
              style: AppLocalization.digitalFont(
                context,
                color: Colors.red.withOpacity(0.3),
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(AuthController auth) {
    final locale = AppLocalization.of(context)!;
    showDialog(
      context: context,
      builder: (context) => TerminalDialog(
        headerTag: locale.translate('ENCRYPTED_LOGOUT_PROTOCOL'),
        title: locale.translate('TERMINATE_SESSION'),
        body: locale.translate('logout_confirm_body'),
        confirmLabel: locale.translate('disconnect_cap'),
        cancelLabel: locale.translate('cancel'),
        onConfirm: () async {
          await auth.logout();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SplashScreen()),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  // Rest of the UI helpers...
  Widget _buildLegalCard(AppLocalization locale) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
            child: _SecurityItem(
              title: locale.translate('privacy_policy'),
              subtitle: locale.translate('DATA_PROTECTION_SUB'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white24, size: 14),
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.03), height: 1),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TermsConditionsScreen())),
            child: _SecurityItem(
              title: locale.translate('terms_conditions'),
              subtitle: locale.translate('USAGE_AGREEMENT_SUB'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white24, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final controller = TextEditingController();
    final locale = AppLocalization.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: Text(locale.translate('change_password'),
            style: AppLocalization.digitalFont(context, color: Colors.white)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: locale.translate('new_password'),
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(locale.translate('cancel'))),
          TextButton(
              onPressed: () async {
                if (controller.text.trim().length < 6) return;
                await Provider.of<AuthController>(context, listen: false)
                    .updatePassword(controller.text.trim());
                Navigator.pop(context);
              },
              child: Text(locale.translate('update_button'))),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirm() {
    final locale = AppLocalization.of(context)!;
    showDialog(
      context: context,
      builder: (context) => TerminalDialog(
        headerTag: locale.translate('DESTRUCTION_PROTOCOL'),
        title: locale.translate('delete_account'),
        body: locale.translate('delete_account_confirm'),
        confirmLabel: locale.translate('delete'),
        cancelLabel: locale.translate('cancel'),
        isDestructive: true,
        onConfirm: () async {
          await Provider.of<AuthController>(context, listen: false)
              .deleteAccount();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SplashScreen()),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00E5FF), size: 16),
          const SizedBox(width: 12),
          Text(title,
              style: AppLocalization.digitalFont(context,
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _SecurityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SecurityItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppLocalization.digitalFont(context,
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: AppLocalization.digitalFont(context,
                        color: Colors.white.withOpacity(0.3), fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDanger;

  const _OutlineButton({
    required this.label,
    required this.onPressed,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
            color: isDanger
                ? Colors.redAccent.withOpacity(0.3)
                : const Color(0xFF00E5FF).withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: AppLocalization.digitalFont(
          context,
          color: isDanger ? Colors.redAccent : const Color(0xFF00E5FF),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LangBtn({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00E5FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppLocalization.digitalFont(
            context,
            color: isActive ? Colors.black : Colors.white38,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
