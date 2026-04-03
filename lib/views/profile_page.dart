import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'chat_detail_screen.dart';
import 'blocked_users_page.dart';
import 'edit_profile_screen.dart';
import 'users_list_page.dart';
import 'components/shimmer_loading.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({this.userId, super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final myUser = authController.currentUser;

    if (widget.userId == null || widget.userId == myUser?.uid) {
      if (myUser == null) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      }
      return _ProfileView(user: myUser, isOwnProfile: true, tabController: _tabController);
    }

    return FutureBuilder<UserModel?>(
      future: FirestoreService().getUser(widget.userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(backgroundColor: AppColors.background),
            body: Center(child: Text(AppLocalization.of(context)!.translate('user_not_found'), style: const TextStyle(color: AppColors.textMuted))),
          );
        }
        return _ProfileView(user: snapshot.data!, isOwnProfile: false, tabController: _tabController);
      },
    );
  }
}

class _ProfileView extends StatefulWidget {
  final UserModel user;
  final bool isOwnProfile;
  final TabController tabController;
  const _ProfileView({required this.user, required this.isOwnProfile, required this.tabController});

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  bool _isFollowLoading = false;

  // ── profile completeness helpers ──────────────────────────────────────
  static bool _isProfileComplete(UserModel u) =>
      u.name.isNotEmpty &&
      u.position.isNotEmpty &&
      u.bio.isNotEmpty &&
      u.city.isNotEmpty &&
      u.profileImage.isNotEmpty;

  static double _completionPercent(UserModel u) {
    int done = 0;
    if (u.name.isNotEmpty) done++;
    if (u.position.isNotEmpty) done++;
    if (u.bio.isNotEmpty) done++;
    if (u.city.isNotEmpty) done++;
    if (u.profileImage.isNotEmpty) done++;
    return done / 5;
  }

  void _showVerificationDialog(BuildContext context) {
    final u = widget.user;
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
        padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            // Animated icon
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
              child: const Center(child: Text('✅', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 16),
            Text(locale.translate('verification_title'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(locale.translate('verification_desc'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(locale.translate('verification_requirements'), style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    Text('${(_completionPercent(u) * 100).toInt()}%', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _completionPercent(u),
                    backgroundColor: AppColors.cardLight,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 16),
                _ReqRow(label: locale.translate('req_name'), done: u.name.isNotEmpty),
                _ReqRow(label: locale.translate('req_position'), done: u.position.isNotEmpty),
                _ReqRow(label: locale.translate('req_bio'), done: u.bio.isNotEmpty),
                _ReqRow(label: locale.translate('req_city'), done: u.city.isNotEmpty),
                _ReqRow(label: locale.translate('req_photo'), done: u.profileImage.isNotEmpty),
              ],
            ),
            const SizedBox(height: 28),
            if (!_isProfileComplete(u))
              AppWidgets.gradientButton(
                label: locale.translate('complete_profile'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                },
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Text(locale.translate('profile_under_review'), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final isFollowing = authController.isFollowing(widget.user.uid);
    final isBlocked = authController.isBlocked(widget.user.uid);
    // Check if this user follows me back
    final followsMe = widget.user.followers.contains(authController.currentUser?.uid ?? '');
    final locale = AppLocalization.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverHeader(context, authController, isFollowing, followsMe, isBlocked),
        ],
        body: Column(
          children: [
            // Stats row
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => UsersListPage(
                            title: locale.translate('following'),
                            userIds: widget.user.following))),
                    child: _StatItem(
                        count: widget.user.following.length, label: locale.translate('following')),
                  ),
                  Container(width: 1, height: 32, color: Colors.white12),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => UsersListPage(
                            title: locale.translate('followers'),
                            userIds: widget.user.followers))),
                    child: _StatItem(
                        count: widget.user.followers.length, label: locale.translate('followers')),
                  ),
                ],
              ),
            ),
            // Verification banner (own profile only, not yet verified)
            if (widget.isOwnProfile && !widget.user.isVerified)
              GestureDetector(
                onTap: () => _showVerificationDialog(context),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.accent.withValues(alpha: 0.1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      // Mini progress ring
                      SizedBox(
                        width: 36, height: 36,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: _completionPercent(widget.user),
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              strokeWidth: 3,
                            ),
                            Text('${(_completionPercent(widget.user) * 100).toInt()}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(locale.translate('verification_title'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(
                              _isProfileComplete(widget.user) ? locale.translate('complete_to_verify_tap') : locale.translate('complete_to_verify_hint'),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              ),
            // Tab bar
            Container(
              color: AppColors.background,
              child: TabBar(
                controller: widget.tabController,
                tabs: [Tab(text: AppLocalization.of(context)!.translate('about')), Tab(text: AppLocalization.of(context)!.translate('posts'))],
              ),
            ),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: widget.tabController,
                children: [
                  _buildAboutTab(context),
                  _buildPostsTab(context, authController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, AuthController authController, bool isFollowing, bool followsMe, bool isBlocked) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.background,
      actions: [
        if (widget.isOwnProfile) ...[
          IconButton(
            icon: const Icon(Icons.person_remove_outlined, size: 22),
            tooltip: AppLocalization.of(context)!.translate('blocked_users'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BlockedUsersPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 22),
            onPressed: () => Navigator.of(context).pushNamed('/edit-profile'),
          ),
        ] else ...[
          _buildOptionsMenu(context, authController),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _buildHeaderBackground(context, authController, isFollowing, followsMe, isBlocked),
      ),
    );
  }

  Widget _buildHeaderBackground(BuildContext context, AuthController authController, bool isFollowing, bool followsMe, bool isBlocked) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0B2E), Color(0xFF0A0A14)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Glow
          Positioned(
            top: -40,
            left: MediaQuery.of(context).size.width / 2 - 100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 100, spreadRadius: 30)],
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 12),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.cardLight,
                      backgroundImage: widget.user.profileImage.isNotEmpty ? NetworkImage(widget.user.profileImage) : null,
                      child: widget.user.profileImage.isEmpty ? const Icon(Icons.person, size: 46, color: AppColors.textSecondary) : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Name + verified
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.user.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      if (widget.user.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: AppColors.accent, size: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Position badge
                  if (widget.user.position.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(widget.user.position, style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 6),
                  // Location + joined
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.user.city.isNotEmpty) ...[
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text('${widget.user.city}  •  ', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(widget.user.joinedAgo, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Action buttons (only for other profiles)
                  if (!widget.isOwnProfile && !isBlocked)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Follow button
                        _FollowButton(
                          isFollowing: isFollowing,
                          followsMe: followsMe,
                          isLoading: _isFollowLoading,
                          onPressed: () async {
                            setState(() => _isFollowLoading = true);
                            if (isFollowing) {
                              await authController.unfollowUser(widget.user.uid);
                            } else {
                              await authController.followUser(widget.user.uid);
                            }
                            setState(() => _isFollowLoading = false);
                          },
                        ),
                        const SizedBox(width: 12),
                        // Message button
                        _ChatButton(otherUserId: widget.user.uid),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsMenu(BuildContext context, AuthController authController) {
    final isBlocked = authController.isBlocked(widget.user.uid);
    final locale = AppLocalization.of(context)!;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) async {
        if (value == 'block') {
          final confirm = await _confirmAction(
            context,
            title: isBlocked ? locale.translate('unblock_user') : locale.translate('block_user'),
            message: isBlocked
                ? locale.translate('unblock_confirm').replaceFirst('{name}', widget.user.name)
                : locale.translate('block_confirm').replaceFirst('{name}', widget.user.name),
            confirmLabel: isBlocked ? locale.translate('unblock') : locale.translate('block'),
          );
          if (confirm == true) {
            await authController.blockUser(widget.user.uid);
            if (context.mounted) Navigator.of(context).pop();
          }
        } else if (value == 'report') {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(locale.translate('report_submitted'))),
            );
          }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'block',
          child: Row(
            children: [
              Icon(isBlocked ? Icons.person_add_outlined : Icons.person_remove_outlined,
                  color: isBlocked ? AppColors.primary : AppColors.error, size: 18),
              const SizedBox(width: 10),
               Text(isBlocked ? locale.translate('unblock_user') : locale.translate('block_user'),
                  style: TextStyle(color: isBlocked ? AppColors.primary : AppColors.error, fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_outlined, color: AppColors.warning, size: 18),
              SizedBox(width: 10),
               Text(locale.translate('report'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool?> _confirmAction(BuildContext context, {required String title, required String message, required String confirmLabel}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.user.bio.isNotEmpty) ...[
          _SectionHeader(title: AppLocalization.of(context)!.translate('bio'), icon: Icons.person_outline),
          _InfoCard(child: Text(widget.user.bio, style: const TextStyle(color: AppColors.textPrimary, height: 1.6, fontSize: 14))),
          const SizedBox(height: 16),
        ],
        _SectionHeader(title: AppLocalization.of(context)!.translate('info'), icon: Icons.info_outline),
        _InfoCard(
          child: Column(
            children: [
              if (widget.user.city.isNotEmpty)
                _InfoRow(icon: Icons.location_on_outlined, label: AppLocalization.of(context)!.translate('location'), value: '${widget.user.city}, ${widget.user.country}'),
              _InfoRow(icon: Icons.calendar_today_outlined, label: AppLocalization.of(context)!.translate('member_since'), value: widget.user.joinedAgo),
              if (widget.user.gender != null)
                _InfoRow(icon: Icons.person_outline, label: AppLocalization.of(context)!.translate('gender'), value: widget.user.gender!),
            ],
          ),
        ),
        if (widget.user.socialLinks != null && widget.user.socialLinks!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(title: AppLocalization.of(context)!.translate('links'), icon: Icons.link_outlined),
          if (widget.user.socialLinks?['github']?.isNotEmpty == true)
            _SocialTile(icon: Icons.code, label: AppLocalization.of(context)!.translate('github'), url: widget.user.socialLinks!['github']!),
          if (widget.user.socialLinks?['linkedin']?.isNotEmpty == true)
            _SocialTile(icon: Icons.work_outline, label: AppLocalization.of(context)!.translate('linkedin'), url: widget.user.socialLinks!['linkedin']!),
        ],
      ],
    );
  }

  Widget _buildPostsTab(BuildContext context, AuthController authController) {
    return StreamBuilder(
      stream: FirestoreService().streamUserPosts(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: 3,
            itemBuilder: (_, __) => const PostShimmer(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.article_outlined, size: 56, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text(AppLocalization.of(context)!.translate('no_posts_yet'), style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => _SimplePostTile(post: snapshot.data![index]),
        );
      },
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool followsMe;
  final bool isLoading;
  final VoidCallback onPressed;
  const _FollowButton({required this.isFollowing, required this.followsMe, required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    String label;
    if (isFollowing) {
      label = locale.translate('following');
    } else if (followsMe) {
      label = locale.translate('follow_back');
    } else {
      label = locale.translate('follow');
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: isFollowing ? null : AppColors.primaryGradient,
        color: isFollowing ? AppColors.card : null,
        borderRadius: BorderRadius.circular(24),
        border: isFollowing ? Border.all(color: Colors.white24) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        followsMe && !isFollowing ? Icons.person_add_alt_1 : (isFollowing ? Icons.check : Icons.person_add_alt),
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  final String otherUserId;
  const _ChatButton({required this.otherUserId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            final authController = Provider.of<AuthController>(context, listen: false);
            final chatController = Provider.of<ChatController>(context, listen: false);
            final myUid = authController.currentUser!.uid;
            final chatId = await chatController.startOrGetChat(myUid, otherUserId);
            if (context.mounted) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatDetailScreen(chatId: chatId, otherUserId: otherUserId),
              ));
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(AppLocalization.of(context)!.translate('message'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  const _StatItem({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SocialTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  const _SocialTile({required this.icon, required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(url, style: const TextStyle(color: AppColors.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

// Simple post tile for the posts tab
class _SimplePostTile extends StatelessWidget {
  final PostModel post;
  const _SimplePostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post.text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('${post.likes.length}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(width: 12),
              Icon(Icons.comment_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('${post.commentCount}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const Spacer(),
              Text(
                _timeAgo(post.createdAt),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// A single requirement row for the verification dialog.
class _ReqRow extends StatelessWidget {
  final String label;
  final bool done;
  const _ReqRow({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: done ? AppColors.accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: done ? AppColors.accent : Colors.white24),
            ),
            child: Center(
              child: Icon(
                done ? Icons.check : Icons.close,
                size: 13,
                color: done ? AppColors.accent : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: done ? AppColors.textPrimary : AppColors.textMuted,
              fontSize: 14,
              fontWeight: done ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            done ? '✓' : '—',
            style: TextStyle(color: done ? AppColors.accent : AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
