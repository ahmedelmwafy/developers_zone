import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/admin_controller.dart';
import '../models/user_model.dart';
import '../models/ad_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'profile_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

enum AdminTab { moderation, ads, metrics, system }

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  AdminTab _currentTab = AdminTab.moderation;
  String _userSearch = '';

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: _buildCurrentTab(locale),
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
      case AdminTab.metrics:
      case AdminTab.system:
        return _PlaceholderView(title: _currentTab.name.toUpperCase());
    }
  }

  Widget _buildBottomNav(AppLocalization locale) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
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
            icon: Icons.bar_chart_rounded,
            label: locale.translate('metrics_tab'),
            isSelected: _currentTab == AdminTab.metrics,
            onTap: () => setState(() => _currentTab = AdminTab.metrics),
          ),
          _NavButton(
            icon: Icons.settings_input_component_rounded,
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
    final color = isSelected ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.2);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
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

class _ModerationView extends StatelessWidget {
  final Function(String) onSearchChanged;
  final String searchQuery;

  const _ModerationView({required this.onSearchChanged, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final adminController = Provider.of<AdminController>(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: const Color(0xFF0D0D0D),
          elevation: 0,
          expandedHeight: 140,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security_rounded, color: Color(0xFF00E5FF), size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'OBSIDIAN ADMIN',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        child: const Icon(Icons.person, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.translate('system_overview'),
                    style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Text(locale.translate('community_health'),
                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 24),
                StreamBuilder<List<UserModel>>(
                  stream: adminController.getAllUsers(),
                  builder: (context, snapshot) {
                    final total = snapshot.data?.length ?? 0;
                    return Row(
                      children: [
                        _StatSmallCard(value: total.toString(), label: locale.translate('total_users')),
                        const SizedBox(width: 12),
                        _StatSmallCard(value: '14', label: locale.translate('reported'), color: const Color(0xFFFF5252)),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 40),
                Text(locale.translate('verification_queues'),
                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _QueueSelector(label: locale.translate('pending_review'), count: '08', isSelected: true, icon: Icons.pending_actions_rounded),
                _QueueSelector(label: locale.translate('approved_label'), count: '', isSelected: false, icon: Icons.verified_rounded),
                _QueueSelector(label: locale.translate('reported_label'), count: '03', isSelected: false, icon: Icons.report_problem_rounded),
                const SizedBox(height: 40),
                _ModerationActivityPanel(locale: locale),
                const SizedBox(height: 40),
                TextField(
                  onChanged: onSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF161616),
                    hintText: locale.translate('search_developers_uid'),
                    hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        StreamBuilder<List<UserModel>>(
          stream: adminController.getAllUsers(),
          builder: (context, snapshot) {
            final users = (snapshot.data ?? [])
                .where((u) => searchQuery.isEmpty || u.name.toLowerCase().contains(searchQuery.toLowerCase()) || u.email.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _DetailedUserCard(user: users[index], adminController: adminController, locale: locale),
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
}

class _StatSmallCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatSmallCard({required this.value, required this.label, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.spaceGrotesk(color: color, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _QueueSelector extends StatelessWidget {
  final String label;
  final String count;
  final bool isSelected;
  final IconData icon;

  const _QueueSelector({required this.label, required this.count, required this.isSelected, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1A1A1A) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.4), size: 18),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.spaceGrotesk(color: isSelected ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.4), fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
          const Spacer(),
          if (count.isNotEmpty)
            Text(count, style: GoogleFonts.spaceGrotesk(color: isSelected ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.4), fontSize: 14, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ModerationActivityPanel extends StatelessWidget {
  final AppLocalization locale;
  const _ModerationActivityPanel({required this.locale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(locale.translate('moderation_activity'), style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _ActivityRow(title: "New user 'ByteMaster' joined", time: "2M AGO"),
          const SizedBox(height: 16),
          _ActivityRow(title: "Admin elevated 'Sarah_Dev'", time: "14M AGO"),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String title;
  final String time;

  const _ActivityRow({required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(time, style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailedUserCard extends StatelessWidget {
  final UserModel user;
  final AdminController adminController;
  final AppLocalization locale;

  const _DetailedUserCard({required this.user, required this.adminController, required this.locale});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: user.profileImage.isNotEmpty ? NetworkImage(user.profileImage) : null,
            child: user.profileImage.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(user.name, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              _UserStatusBadge(user: user, locale: locale),
            ],
          ),
          const SizedBox(height: 4),
          Text("${user.email} • UID: ${user.uid.substring(0, 8)}", style: GoogleFonts.inter(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Tag(label: 'Rust'),
              _Tag(label: 'WebAssembly'),
              _Tag(label: 'Tokyo'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               _ActionBtn(label: locale.translate('approve'), color: const Color(0xFF00E5FF), textColor: Colors.black, onTap: () => adminController.approveUser(user.uid, true)),
               const SizedBox(width: 12),
               _ActionBtn(label: locale.translate('verify'), color: Colors.white.withOpacity(0.05), onTap: () => adminController.verifyUser(user.uid, true)),
               const SizedBox(width: 12),
               _ActionBtn(label: locale.translate('ban'), color: Colors.white.withOpacity(0.05), textColor: const Color(0xFFFF5252), onTap: () => adminController.banUser(user.uid, true)),
            ],
          ),
        ],
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
    String text = user.isBanned ? locale.translate('banned') : user.isApproved ? locale.translate('approved_label') : locale.translate('pending');
    Color color = user.isBanned ? const Color(0xFFFF5252) : user.isApproved ? const Color(0xFF00E5FF) : Colors.white24;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text.toUpperCase(), style: GoogleFonts.spaceGrotesk(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionBtn({required this.label, required this.color, this.textColor = Colors.white, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Text(label, style: GoogleFonts.spaceGrotesk(color: textColor, fontSize: 13, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _AdsView extends StatelessWidget {
  const _AdsView();

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final adminController = Provider.of<AdminController>(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: const Color(0xFF0D0D0D),
          expandedHeight: 140,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DEVELOPER ZONE', style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  Text(locale.translate('ad_management_title'), style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(locale.translate('ad_management_desc'), style: GoogleFonts.inter(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: const BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(locale.translate('live_stats'), style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w800)),
                          Row(
                            children: [
                              Text('14', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                              const SizedBox(width: 12),
                              Text(locale.translate('active_ads'), style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.4), fontSize: 14, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(locale.translate('ready_to_scale'), style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Text(locale.translate('deploy_new_campaign'), style: GoogleFonts.inter(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewCampaignPage())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(color: const Color(0xFF00E5FF), borderRadius: BorderRadius.circular(12)),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add, color: Colors.black, size: 20),
                                const SizedBox(width: 8),
                                Text(locale.translate('add_new_campaign'), style: GoogleFonts.spaceGrotesk(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: _IconButton(icon: Icons.filter_list_rounded, label: locale.translate('filter_by_platform'))),
                    const SizedBox(width: 12),
                    Expanded(child: _IconButton(icon: Icons.analytics_outlined, label: locale.translate('view_reports'))),
                  ],
                ),
                const SizedBox(height: 48),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(locale.translate('active_pending_campaigns'), style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.4), fontSize: 14, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        StreamBuilder<List<AdModel>>(
          stream: adminController.getAds(),
          builder: (context, snapshot) {
            final ads = snapshot.data ?? [];
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _CampaignCard(ad: ads[index], adminController: adminController),
                  childCount: ads.length,
                ),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _IconButton({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final AdModel ad;
  final AdminController adminController;

  const _CampaignCard({required this.ad, required this.adminController});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.network(
              ad.imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.white.withOpacity(0.05), child: const Icon(Icons.image_outlined, color: Colors.white10)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(ad.title, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                      child: Text('ENTERPRISE', style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Target: DevOps Engineers • Region: Global", style: GoogleFonts.inter(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.visibility_outlined, color: Colors.white.withOpacity(0.2), size: 14),
                    const SizedBox(width: 4),
                    Text('12.4K', style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 16),
                    Icon(Icons.ads_click_rounded, color: Colors.white.withOpacity(0.2), size: 14),
                    const SizedBox(width: 4),
                    Text('842', style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ACTIVE STATUS', style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        Switch(
                          value: ad.active,
                          onChanged: (v) => adminController.updateAd(AdModel(id: ad.id, title: ad.title, description: ad.description, imageUrl: ad.imageUrl, targetUrl: ad.targetUrl, active: v, type: ad.type)),
                          activeTrackColor: const Color(0xFF00E5FF).withOpacity(0.2),
                          activeColor: const Color(0xFF00E5FF),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.more_vert, color: Colors.white.withOpacity(0.2)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NewCampaignPage extends StatefulWidget {
  const NewCampaignPage({super.key});

  @override
  State<NewCampaignPage> createState() => _NewCampaignPageState();
}

class _NewCampaignPageState extends State<NewCampaignPage> {
  final _idController = TextEditingController();
  final _endpointController = TextEditingController();
  final _metadataController = TextEditingController();
  bool _isActive = true;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final adminController = Provider.of<AdminController>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5FF)), onPressed: () => Navigator.pop(context)),
        title: Text(locale.translate('new_campaign'), style: GoogleFonts.spaceGrotesk(color: const Color(0xFF00E5FF), fontWeight: FontWeight.w800)),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF00EEFF), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('LIVE SERVER', style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(locale.translate('step_01_config'), style: GoogleFonts.spaceGrotesk(color: const Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            const SizedBox(height: 24),
            _buildField(locale.translate('campaign_identifier'), "Enter system designation...", _idController),
            const SizedBox(height: 24),
            _buildField(locale.translate('destination_endpoint'), "https://api.obsidian.io/v1/...", _endpointController),
            const SizedBox(height: 24),
            Text(locale.translate('campaign_metadata_string'), style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 12),
            TextField(
               controller: _metadataController,
               maxLines: 4,
               style: const TextStyle(color: Colors.white),
               decoration: InputDecoration(
                 hintText: locale.translate('brief_technical_summary'),
                 hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
                 filled: true,
                 fillColor: const Color(0xFF161616),
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
               ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.remove_red_eye_rounded, color: Color(0xFF00E5FF), size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(locale.translate('active_status'), style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                        Text(locale.translate('deploy_to_production'), style: GoogleFonts.inter(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeColor: const Color(0xFF00E5FF),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Text(locale.translate('step_02_visual'), style: GoogleFonts.spaceGrotesk(color: const Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            const SizedBox(height: 24),
            _buildAssetPicker(locale.translate('loc_en_banner'), "1920 x 1080 PX"),
            const SizedBox(height: 16),
            _buildAssetPicker(locale.translate('loc_ar_banner'), "RTL_ACTIVE", isRTL: true),
            const SizedBox(height: 32),
            Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(color: const Color(0xFF00E5FF).withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.1))),
               child: Text(locale.translate('banners_note'), style: GoogleFonts.inter(color: const Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(locale.translate('system_load_optimal'), style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ],
            ),
            Center(child: Text(locale.translate('ready_for_deployment'), style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.2), fontSize: 10, fontWeight: FontWeight.w600))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _OutlineBtn(label: locale.translate('save_draft'))),
                const SizedBox(width: 12),
                Expanded(child: _FilledBtn(label: locale.translate('initialize_campaign'), onTap: () {
                   adminController.addAd(AdModel(
                    id: '',
                    title: _idController.text.trim(),
                    description: _metadataController.text.trim(),
                    imageUrl: 'https://images.unsplash.com/photo-1633356122544-f134324a6cee?w=800', // Mock
                    targetUrl: _endpointController.text.trim(),
                    active: _isActive,
                    type: 'home',
                  ));
                   Navigator.pop(context);
                })),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF161616),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetPicker(String label, String info, {bool isRTL = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF161616), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w800)),
              const Spacer(),
              _InfoBadge(label: info, isAccent: isRTL),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, color: Colors.white.withOpacity(0.4), size: 32),
                const SizedBox(height: 12),
                Text(AppLocalization.of(context)!.translate('drop_localized_asset'), style: GoogleFonts.inter(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600)),
                Text(AppLocalization.of(context)!.translate('supports_svg_png'), style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.2), fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final bool isAccent;
  const _InfoBadge({required this.label, this.isAccent = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: isAccent ? const Color(0xFF00E5FF).withOpacity(0.1) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: GoogleFonts.spaceGrotesk(color: isAccent ? const Color(0xFF00E5FF) : Colors.white.withOpacity(0.2), fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  const _OutlineBtn({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Center(child: Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900))),
    );
  }
}

class _FilledBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilledBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: const Color(0xFF00E5FF), borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900))),
      ),
    );
  }
}

class _PlaceholderView extends StatelessWidget {
  final String title;
  const _PlaceholderView({required this.title});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(title, style: GoogleFonts.spaceGrotesk(color: Colors.white24, fontSize: 32, fontWeight: FontWeight.w900)),
    );
  }
}
