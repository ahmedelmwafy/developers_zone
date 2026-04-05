import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/admin_controller.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'ad_management_page.dart';
import 'post_details_page.dart';
import '../models/post_model.dart';
import '../models/ad_model.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

enum AdminTab { moderation, ads, admob, metrics, system }

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  AdminTab _currentTab = AdminTab.moderation;
  String _userSearch = '';

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: _buildCurrentTab(locale),
      ),
      bottomNavigationBar: _buildBottomNav(locale),
    );
  }

  Widget _buildCurrentTab(AppLocalization locale) {
    switch (_currentTab) {
      case AdminTab.moderation:
        return _ModerationView(
          onSearchChanged: (v) => setState(() => _userSearch = v),
          searchQuery: _userSearch,
        );
      case AdminTab.ads:
        return const _AdsView();
      case AdminTab.admob:
        return const _AdMobView();
      case AdminTab.metrics:
        return _MetricsView(locale: locale);
      case AdminTab.system:
        return _BroadcastView(locale: locale);
    }
  }

  Widget _buildBottomNav(AppLocalization locale) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavButton(
            icon: Icons.security_rounded,
            label: locale.translate('moderation_tab'),
            isSelected: _currentTab == AdminTab.moderation,
            onTap: () => setState(() => _currentTab = AdminTab.moderation),
          ),
          _NavButton(
            icon: Icons.ads_click_rounded,
            label: locale.translate('ads_tab'),
            isSelected: _currentTab == AdminTab.ads,
            onTap: () => setState(() => _currentTab = AdminTab.ads),
          ),
          _NavButton(
            icon: Icons.settings_input_component_rounded,
            label: 'ADMOB',
            isSelected: _currentTab == AdminTab.admob,
            onTap: () => setState(() => _currentTab = AdminTab.admob),
          ),
          _NavButton(
            icon: Icons.bar_chart_rounded,
            label: locale.translate('metrics_tab'),
            isSelected: _currentTab == AdminTab.metrics,
            onTap: () => setState(() => _currentTab = AdminTab.metrics),
          ),
          _NavButton(
            icon: Icons.cell_tower_rounded,
            label: locale.translate('system_tab'),
            isSelected: _currentTab == AdminTab.system,
            onTap: () => setState(() => _currentTab = AdminTab.system),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.2);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppLocalization.digitalFont(
                context,
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum UserFilter { all, approved, pending, verified, banned, locked, admins }

class _ModerationView extends StatefulWidget {
  final Function(String) onSearchChanged;
  final String searchQuery;

  const _ModerationView(
      {required this.onSearchChanged, required this.searchQuery});

  @override
  State<_ModerationView> createState() => _ModerationViewState();
}

class _ModerationViewState extends State<_ModerationView> {
  UserFilter _currentFilter = UserFilter.all;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final adminController = Provider.of<AdminController>(context);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.translate('TERMINAL_ACCESS'),
                    style: AppLocalization.digitalFont(context,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(locale.translate('reported_content'),
                    style: AppLocalization.digitalFont(context,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28)),
                const SizedBox(height: 24),
                StreamBuilder<List<ReportModel>>(
                  stream: adminController.getReports(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.security_rounded,
                                color: Colors.red, size: 32),
                            const SizedBox(height: 12),
                            Text('PERMISSION_DENIED',
                                style: AppLocalization.digitalFont(context,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(
                                'Ensure "reports" collection exists & rules are updated.',
                                textAlign: TextAlign.center,
                                style: AppLocalization.digitalFont(context,
                                    color: Colors.white24, fontSize: 12)),
                          ],
                        ),
                      );
                    }
                    final reports = snapshot.data ?? [];
                    if (reports.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20)),
                        child: Center(
                          child: Text(locale.translate('all_clear'),
                              style: AppLocalization.digitalFont(context,
                                  color: Colors.white24,
                                  fontWeight: FontWeight.w700)),
                        ),
                      );
                    }
                    return Column(
                      children: reports
                          .map((report) => _ReportCard(
                              report: report,
                              adminController: adminController,
                              locale: locale))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 48),
                Text(locale.translate('user_management'),
                    style: AppLocalization.digitalFont(context,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28)),
                const SizedBox(height: 24),
                TextField(
                  onChanged: widget.onSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    hintText: locale.translate('search_users_hint'),
                    hintStyle:
                        AppLocalization.digitalFont(context,
                            color: Colors.white24, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white24, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                _buildFilterBar(locale),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        StreamBuilder<List<UserModel>>(
          stream: adminController.getAllUsers(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('USER_STREAM_PERMISSION_ERR',
                        style: AppLocalization.digitalFont(context, 
                            color: Colors.red.withValues(alpha: 0.3),
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              );
            }
            final users = (snapshot.data ?? [])
                .where((u) =>
                    widget.searchQuery.isEmpty ||
                    u.name
                        .toLowerCase()
                        .contains(widget.searchQuery.toLowerCase()) ||
                    u.email
                        .toLowerCase()
                        .contains(widget.searchQuery.toLowerCase()))
                .where((u) {
              switch (_currentFilter) {
                case UserFilter.all:
                  return true;
                case UserFilter.approved:
                  return u.isApproved;
                case UserFilter.pending:
                  return !u.isApproved;
                case UserFilter.verified:
                  return u.isVerified;
                case UserFilter.banned:
                  return u.isBanned;
                case UserFilter.locked:
                  return u.isLocked;
                case UserFilter.admins:
                  return u.isAdmin;
              }
            }).toList();

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _DetailedUserCard(
                      user: users[index],
                      adminController: adminController,
                      locale: locale),
                  childCount: users.length,
                ),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildFilterBar(AppLocalization locale) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: UserFilter.values.map((f) {
          final isSelected = _currentFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _currentFilter = f),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Text(
                locale.translate('filter_${f.name}').toUpperCase(),
                style: AppLocalization.digitalFont(
                  context,
                  color: isSelected ? Colors.black : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final AdminController adminController;
  final AppLocalization locale;

  const _ReportCard(
      {required this.report,
      required this.adminController,
      required this.locale});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PostModel?>(
      future: adminController.getPost(report.postId),
      builder: (context, snapshot) {
        final post = snapshot.data;
        final isDeleted =
            snapshot.connectionState == ConnectionState.done && post == null;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(report.id.substring(0, 8).toUpperCase(),
                        style: AppLocalization.digitalFont(context, 
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.w900)),
                  ),
                  const Spacer(),
                  Text(locale.translate('just_now'),
                      style: AppLocalization.digitalFont(context, 
                          color: Colors.white24,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text:
                            '${locale.translate('reason_text').replaceFirst('{}', '')} ',
                        style: AppLocalization.digitalFont(context, 
                            color: Colors.red.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    TextSpan(
                        text: report.reason,
                        style: AppLocalization.digitalFont(context, 
                            color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(
                    backgroundColor: Colors.white10,
                    color: Colors.red,
                    minHeight: 1)
              else if (isDeleted)
                Text('POST_MANIFEST_TERMINATED',
                    style: AppLocalization.digitalFont(context, 
                        color: Colors.white10,
                        fontSize: 12,
                        fontWeight: FontWeight.w900))
              else if (post != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    post.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppLocalization.digitalFont(context, color: Colors.white60, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      label: locale.translate('view_post'),
                      color: isDeleted
                          ? Colors.white10
                          : Colors.white.withValues(alpha: 0.05),
                      onTap: isDeleted || post == null
                          ? null
                          : () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => PostDetailsPage(post: post))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionBtn(
                      label: locale.translate('delete_content'),
                      color: Colors.red.withValues(alpha: 0.8),
                      textColor: Colors.white,
                      onTap: () => adminController.deletePost(report.postId),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => adminController.dismissReports(report.postId),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white24, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailedUserCard extends StatelessWidget {
  final UserModel user;
  final AdminController adminController;
  final AppLocalization locale;

  const _DetailedUserCard(
      {required this.user,
      required this.adminController,
      required this.locale});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: user.isAdmin
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.transparent),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: user.profileImage.isNotEmpty
                    ? NetworkImage(user.profileImage)
                    : null,
                child: user.profileImage.isEmpty
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: AppLocalization.digitalFont(context, 
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (user.isVerified)
                          const Icon(Icons.verified_rounded,
                              color: AppColors.primary, size: 16),
                      ],
                    ),
                    Text(user.email,
                        style: AppLocalization.digitalFont(context, 
                            color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              _UserStatusBadge(user: user, locale: locale),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _ModerationToggle(
                label: locale.translate('verify'),
                isActive: user.isVerified,
                onChanged: (val) => adminController.verifyUser(user.uid, val),
              ),
              _ModerationToggle(
                label: locale.translate('approve'),
                isActive: user.isApproved,
                onChanged: (val) => adminController.approveUser(user.uid, val),
              ),
              _ModerationToggle(
                label: locale.translate('lock_user'),
                isActive: user.isLocked,
                color: Colors.orange,
                onChanged: (val) => adminController.toggleUserPermission(
                    user.uid, 'isLocked', val),
              ),
              _ModerationToggle(
                label: locale.translate('restrict_post'),
                isActive: !user.canPost,
                color: Colors.red,
                onChanged: (val) => adminController.toggleUserPermission(
                    user.uid, 'canPost', !val),
              ),
              _ModerationToggle(
                label: locale.translate('restrict_comment'),
                isActive: !user.canComment,
                color: Colors.red,
                onChanged: (val) => adminController.toggleUserPermission(
                    user.uid, 'canComment', !val),
              ),
              _ModerationToggle(
                label: locale.translate('make_admin'),
                isActive: user.isAdmin,
                onChanged: (val) => adminController.toggleUserPermission(
                    user.uid, 'isAdmin', val),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModerationToggle extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? color;
  final ValueChanged<bool> onChanged;

  const _ModerationToggle({
    required this.label,
    required this.isActive,
    this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: () => onChanged(!isActive),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isActive
                  ? activeColor.withValues(alpha: 0.3)
                  : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: AppLocalization.digitalFont(context, 
                    color: isActive ? activeColor : Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.w800)),
            const SizedBox(width: 4),
            Icon(isActive ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isActive ? activeColor : Colors.white24, size: 12),
          ],
        ),
      ),
    );
  }
}

class _UserStatusBadge extends StatelessWidget {
  final UserModel user;
  final AppLocalization locale;
  const _UserStatusBadge({required this.user, required this.locale});

  @override
  Widget build(BuildContext context) {
    String text = user.isBanned
        ? locale.translate('banned')
        : user.isApproved
            ? locale.translate('approved_label')
            : locale.translate('pending');
    Color color = user.isBanned
        ? Colors.red
        : user.isApproved
            ? AppColors.primary
            : Colors.white24;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(text.toUpperCase(),
          style: AppLocalization.digitalFont(context, 
              color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}

class _MetricsView extends StatelessWidget {
  final AppLocalization locale;
  const _MetricsView({required this.locale});

  @override
  Widget build(BuildContext context) {
    final adminController = Provider.of<AdminController>(context);

    return FutureBuilder<Map<String, int>>(
      future: adminController.getAnalytics(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'users': 0, 'posts': 0, 'reports': 0};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(locale.translate('analytics_overview'),
                  style: AppLocalization.digitalFont(context,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(locale.translate('system_analytics'),
                  style: AppLocalization.digitalFont(context,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 28)),
              const SizedBox(height: 32),
              _MetricCard(
                  label: locale.translate('active_users'),
                  value: stats['users'].toString(),
                  icon: Icons.people_rounded,
                  color: AppColors.primary),
              const SizedBox(height: 16),
              _MetricCard(
                  label: locale.translate('total_posts'),
                  value: stats['posts'].toString(),
                  icon: Icons.article_rounded,
                  color: Colors.blue),
              const SizedBox(height: 16),
              _MetricCard(
                  label: locale.translate('reports_count'),
                  value: stats['reports'].toString(),
                  icon: Icons.report_rounded,
                  color: Colors.red),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: AppLocalization.digitalFont(context, 
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900)),
              Text(label,
                  style: AppLocalization.digitalFont(context, 
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.trending_up_rounded, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}

class _BroadcastView extends StatefulWidget {
  final AppLocalization locale;
  const _BroadcastView({required this.locale});

  @override
  State<_BroadcastView> createState() => _BroadcastViewState();
}

class _BroadcastViewState extends State<_BroadcastView> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    final adminController = Provider.of<AdminController>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMMUNICATION_HUB',
              style: AppLocalization.digitalFont(context, 
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(widget.locale.translate('broadcast_notification'),
              style: AppLocalization.digitalFont(context, 
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28)),
          const SizedBox(height: 32),
          _buildInput(
              widget.locale.translate('broadcast_title'), _titleController),
          const SizedBox(height: 24),
          _buildInput(
              widget.locale.translate('broadcast_body'), _bodyController,
              maxLines: 5),
          const SizedBox(height: 40),
          _ActionBtn(
            label: widget.locale.translate('send_broadcast'),
            color: AppColors.primary,
            textColor: Colors.black,
            onTap: _isSending
                ? null
                : () async {
                    if (_titleController.text.isEmpty ||
                        _bodyController.text.isEmpty) return;
                    setState(() => _isSending = true);
                    await adminController.sendBroadcast(
                        _titleController.text, _bodyController.text);
                    setState(() {
                      _isSending = false;
                      _titleController.clear();
                      _bodyController.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text(widget.locale.translate('action_applied'))));
                  },
            isLoading: _isSending,
          ),
          const SizedBox(height: 60),
          Text('SYSTEM_CONTROL',
              style: AppLocalization.digitalFont(context, 
                  color: Colors.white24,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 2)),
          const SizedBox(height: 16),
          _SystemActionRow(
            label: widget.locale.translate('seed_dummy_data'),
            icon: Icons.storage_rounded,
            onTap: () => adminController.seedDummyData(),
          ),
          const Divider(color: Colors.white10, height: 32),
          _SystemActionRow(
            label: widget.locale.translate('clear_dummy_data'),
            icon: Icons.delete_sweep_rounded,
            isDestructive: true,
            onTap: () => adminController.clearDummyData(),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppLocalization.digitalFont(context, 
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

class _SystemActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SystemActionRow(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon,
              color: isDestructive ? Colors.red : Colors.white24, size: 20),
          const SizedBox(width: 16),
          Text(label,
              style: AppLocalization.digitalFont(context, 
                  color: isDestructive ? Colors.red : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, color: Colors.white10),
        ],
      ),
    );
  }
}

class _AdsView extends StatelessWidget {
  const _AdsView();

  @override
  Widget build(BuildContext context) {
    return const AdManagementPage();
  }
}

class _AdMobView extends StatelessWidget {
  const _AdMobView();

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final adminController = Provider.of<AdminController>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SYSTEM_CONTROL',
              style: AppLocalization.digitalFont(context, 
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(locale.translate('admob_control'),
              style: AppLocalization.digitalFont(context, 
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28)),
          const SizedBox(height: 32),
          StreamBuilder<AdSettingsModel>(
            stream: adminController.getAdSettings(),
            builder: (context, snapshot) {
              final settings = snapshot.data ?? AdSettingsModel();

              return Column(
                children: [
                  _PlatformCard(
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
                  const SizedBox(height: 16),
                  _PlatformCard(
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
                  const SizedBox(height: 16),
                  _PlatformCard(
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
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  final String title;
  final bool androidValue;
  final bool iosValue;
  final ValueChanged<bool> onAndroidChanged;
  final ValueChanged<bool> onIosChanged;

  const _PlatformCard({
    required this.title,
    required this.androidValue,
    required this.iosValue,
    required this.onAndroidChanged,
    required this.onIosChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(title,
              style: AppLocalization.digitalFont(context, 
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _ToggleTile(
            label: 'Android System',
            icon: Icons.android_rounded,
            value: androidValue,
            onChanged: onAndroidChanged,
          ),
          const SizedBox(height: 12),
          _ToggleTile(
            label: 'iOS Framework',
            icon: Icons.apple_rounded,
            value: iosValue,
            onChanged: onIosChanged,
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.label,
    required this.icon,
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
            Icon(icon, color: Colors.white24, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: AppLocalization.digitalFont(context, 
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionBtn(
      {required this.label,
      required this.color,
      this.textColor = Colors.white,
      this.onTap,
      this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
              : Text(label.toUpperCase(),
                  style: AppLocalization.digitalFont(context, 
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
        ),
      ),
    );
  }
}
