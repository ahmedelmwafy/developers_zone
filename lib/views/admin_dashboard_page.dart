import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/admin_controller.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'ad_management_page.dart';
import 'profile_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final adminController = Provider.of<AdminController>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // SliverAppBar header
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A0E30), AppColors.background],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 80,
                              spreadRadius: 30)
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.admin_panel_settings,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(locale.translate('admin'),
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(locale.translate('manage_users_content'),
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 16,
                    child: _ActionChip(
                      icon: Icons.campaign_outlined,
                      label: locale.translate('ads'),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const AdManagementPage())),
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                  color: Colors.white.withValues(alpha: 0.06), height: 1),
            ),
          ),
          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: AppWidgets.fieldDecoration(locale.translate('search_users_hint'),
                    prefixIcon: Icons.search),
              ),
            ),
          ),
          // User list
          StreamBuilder<List<UserModel>>(
            stream: adminController.getAllUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(locale.translate('no_users_found'),
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ),
                );
              }

              final users = snapshot.data!
                  .where((u) =>
                      _search.isEmpty ||
                      u.name.toLowerCase().contains(_search) ||
                      u.email.toLowerCase().contains(_search))
                  .toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      // Stats row
                      final total = snapshot.data!.length;
                      final approved =
                          snapshot.data!.where((u) => u.isApproved).length;
                      final banned =
                          snapshot.data!.where((u) => u.isBanned).length;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            _StatPill(
                                label: locale.translate('total'),
                                value: total.toString(),
                                color: AppColors.primary),
                            const SizedBox(width: 8),
                            _StatPill(
                                label: locale.translate('approved'),
                                value: approved.toString(),
                                color: AppColors.success),
                            const SizedBox(width: 8),
                            _StatPill(
                                label: locale.translate('banned'),
                                value: banned.toString(),
                                color: AppColors.error),
                          ],
                        ),
                      );
                    }
                    final user = users[index - 1];
                    return _UserTile(
                        user: user,
                        adminController: adminController,
                        locale: locale);
                  },
                  childCount: users.length + 1,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final AdminController adminController;
  final AppLocalization locale;

  const _UserTile(
      {required this.user,
      required this.adminController,
      required this.locale});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.isBanned
              ? AppColors.error.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar - Navigate to Profile
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage(userId: user.uid))),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                          user.isVerified ? AppColors.primaryGradient : null,
                      color: user.isVerified ? null : AppColors.cardLight,
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.cardLight,
                      backgroundImage: user.profileImage.isNotEmpty
                          ? NetworkImage(user.profileImage)
                          : null,
                      child: user.profileImage.isEmpty
                          ? const Icon(Icons.person,
                              color: AppColors.textSecondary, size: 22)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage(userId: user.uid))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(user.name,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (user.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified,
                                  color: AppColors.accent, size: 14),
                            ],
                            if (user.isAdmin) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(locale.translate('admin'),
                                    style: const TextStyle(
                                        color: AppColors.warning,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(user.email,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (user.isBanned
                            ? AppColors.error
                            : user.isApproved
                                ? AppColors.success
                                : AppColors.warning)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.isBanned
                        ? locale.translate('banned')
                        : user.isApproved
                            ? locale.translate('active')
                            : locale.translate('pending'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: user.isBanned
                          ? AppColors.error
                          : user.isApproved
                              ? AppColors.success
                              : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            // Action row
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _AdminAction(
                    icon: user.isVerified
                        ? Icons.verified
                        : Icons.verified_outlined,
                    label: user.isVerified ? locale.translate('unverify') : locale.translate('verify'),
                    color: AppColors.accent,
                    onTap: () =>
                        adminController.verifyUser(user.uid, !user.isVerified),
                  ),
                  _Vline(),
                  _AdminAction(
                    icon: user.isApproved
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    label: user.isApproved ? locale.translate('unapprove') : locale.translate('approve'),
                    color: AppColors.success,
                    onTap: () =>
                        adminController.approveUser(user.uid, !user.isApproved),
                  ),
                  _Vline(),
                  _AdminAction(
                    icon: user.isAdmin
                        ? Icons.admin_panel_settings
                        : Icons.admin_panel_settings_outlined,
                    label: user.isAdmin ? locale.translate('revoke') : locale.translate('admin'),
                    color: AppColors.warning,
                    onTap: () =>
                        adminController.toggleAdmin(user.uid, !user.isAdmin),
                  ),
                  _Vline(),
                  _AdminAction(
                    icon: user.isBanned ? Icons.lock_open : Icons.block,
                    label: user.isBanned ? locale.translate('unban') : locale.translate('ban'),
                    color: AppColors.error,
                    onTap: () =>
                        adminController.banUser(user.uid, !user.isBanned),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AdminAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _Vline extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 30, color: Colors.white.withValues(alpha: 0.08));
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 18)),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 12)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
