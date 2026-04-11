import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/post_controller.dart';
import '../controllers/admin_controller.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import 'chat_detail_screen.dart';
import 'network_page.dart';
import 'admin_dashboard_page.dart';
import 'edit_profile_page.dart';
import 'login_screen.dart';
import '../providers/app_provider.dart';
import '../widgets/terminal_dialog.dart';
import '../widgets/shimmer_component.dart';

import '../services/notification_service.dart';
import '../models/notification_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/post_media_widget.dart';
import '../widgets/page_entry_animation.dart';
import '../widgets/app_cached_image.dart';
import '../theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({this.userId, super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController =
          Provider.of<AuthController>(context, listen: false);
      final myUser = authController.currentUser;
      if (widget.userId != null &&
          widget.userId != myUser?.uid &&
          myUser != null) {
        _recordView(myUser);
      }
    });
  }

  Future<void> _recordView(UserModel myUser) async {
    final firestore = FirestoreService();
    await firestore.recordProfileView(myUser.uid, widget.userId!);

    // Get target user for notification
    final viewedUser = await firestore.getUser(widget.userId!);
    if (viewedUser != null && viewedUser.pushNotifications) {
      if (!mounted) return;
      final locale = AppLocalization.of(context)!;
      await NotificationService.sendNotification(
        targetToken: viewedUser.fcmToken,
        targetUid: viewedUser.uid,
        title: locale.translate('profile_view_title'),
        body: locale
            .translate('profile_view_body')
            .replaceFirst('{}', myUser.name),
        type: NotificationType.profileView,
        relatedId: myUser.uid,
      );
      if (mounted) {
        AppWidgets.showToast(
            context, locale.translate('profile_visit_synced'),
            type: SnackBarType.success);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final myUser = authController.currentUser;
    final locale = AppLocalization.of(context)!;

    if (widget.userId == null || widget.userId == myUser?.uid) {
      if (myUser == null) {
        return _GuestProfileUI(locale: locale);
      }
      return _ProfileView(user: myUser, isOwnProfile: true);
    }

    if (myUser == null) {
      return _GuestProfileUI(locale: locale);
    }

    return StreamBuilder<UserModel?>(
      stream: FirestoreService().streamUser(widget.userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Scaffold(
              backgroundColor: const Color(0xFF0D0D0D),
              body: Center(child: ShimmerComponent.listShimmer(count: 3)));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
              backgroundColor: const Color(0xFF0D0D0D),
              body: Center(
                  child: Text(
                      AppLocalization.of(context)!.translate('user_not_found'),
                      style: const TextStyle(color: Colors.white24))));
        }
        return _ProfileView(user: snapshot.data!, isOwnProfile: false);
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  final UserModel user;
  final bool isOwnProfile;
  const _ProfileView({required this.user, required this.isOwnProfile});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final locale = AppLocalization.of(context)!;
    final isFollowing = auth.currentUser?.following.contains(user.uid) ?? false;

    if (isOwnProfile) {
      return Scaffold(
        backgroundColor: const Color(0xFF060606),
        body: PageEntryAnimation(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAccountManagement(context, auth, locale),
                const SizedBox(height: 24),
                _buildNetworkHubPanel(context, auth, locale),
                if (auth.currentUser?.isAdmin ?? false) ...[
                  const SizedBox(height: 24),
                  _buildPrivilegedAccess(context, auth, locale),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF00E5FF), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalization.of(context)!.translate('profile_caps'),
          style: AppLocalization.digitalFont(context,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: PageEntryAnimation(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildIdentityHeader(context, isFollowing),
              const SizedBox(height: 48),
              _buildStatsHeader(context),
              const SizedBox(height: 40),
              _buildNodalMetadata(context, locale),
              const SizedBox(height: 40),
              _buildActionButtons(context, isFollowing, auth),
              if (auth.currentUser?.isAdmin ?? false) ...[
                const SizedBox(height: 32),
                _buildAdminActionPanel(context, locale),
              ],
              const SizedBox(height: 48),
              _buildActivityFeed(Provider.of<PostController>(context),
                  auth.currentUser?.isAdmin ?? false),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodalMetadata(BuildContext context, AppLocalization locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale.translate('NODE_METADATA'),
          style: AppLocalization.digitalFont(context,
              color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
          ),
          child: Column(
            children: [
              _buildMetadataRow(
                context,
                locale.translate('location').toUpperCase(),
                user.city.isNotEmpty && user.country.isNotEmpty
                    ? '${user.city.toUpperCase()}, ${user.country.toUpperCase()}'
                    : locale.translate('UNKNOWN_HUB'),
                Icons.location_on_outlined,
              ),
              if (user.company.isNotEmpty)
                _buildMetadataRow(
                  context,
                  locale.translate('company').toUpperCase(),
                  user.company.toUpperCase(),
                  Icons.business_center_outlined,
                ),
              _buildMetadataDivider(),
              _buildMetadataRow(
                context,
                locale.translate('birth_date').toUpperCase(),
                user.birthDate != null
                    ? '${user.age} ${locale.translate('YEAR_CYCLE')}'
                    : locale.translate('UNDEFINED_GENESIS'),
                Icons.history_toggle_off_rounded,
              ),
              _buildMetadataRow(
                context,
                locale.translate('gender').toUpperCase(),
                user.gender?.toUpperCase() ??
                    locale.translate('UNKNOWN_VARIANT'),
                Icons.fingerprint_rounded,
              ),
              if (user.socialLinks != null && user.socialLinks!.isNotEmpty) ...[
                _buildMetadataDivider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (user.socialLinks!['github']?.isNotEmpty == true)
                      _buildSocialChip(context, 'GITHUB', Icons.code_rounded,
                          user.socialLinks!['github']!),
                    if (user.socialLinks!['linkedin']?.isNotEmpty == true)
                      _buildSocialChip(context, 'LINKEDIN', Icons.link_rounded,
                          user.socialLinks!['linkedin']!),
                    if (user.socialLinks!['portfolio']?.isNotEmpty == true)
                      _buildSocialChip(
                          context,
                          'PORTFOLIO',
                          Icons.language_rounded,
                          user.socialLinks!['portfolio']!),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(
      BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white24, size: 16),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppLocalization.digitalFont(context,
                    color: Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1),
              ),
            ],
          ),
          Text(
            value,
            style: AppLocalization.digitalFont(context,
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataDivider() => Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: Colors.white.withValues(alpha: 0.03));

  Widget _buildSocialChip(
      BuildContext context, String label, IconData icon, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF00E5FF), size: 14),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppLocalization.digitalFont(context,
                  color: const Color(0xFF00E5FF),
                  fontSize: 9,
                  fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityHeader(BuildContext context, bool isFollowing) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                    width: 3),
              ),
              child: AppCachedImage(
                imageUrl: user.profileImage,
                width: 140,
                height: 140,
                borderRadius: 28,
                errorWidget: Center(
                  child: Text(user.initials,
                      style: AppLocalization.digitalFont(context,
                          color: Colors.white.withValues(alpha: 0.1),
                          fontSize: 48,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ),
            Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFF0D0D0D), width: 4),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.name,
              style: AppLocalization.digitalFont(context,
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            if (user.isVerified)
              const Icon(Icons.verified_rounded,
                  color: Color(0xFF00E5FF), size: 20),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${user.position.toUpperCase()}${user.company.isNotEmpty ? ' @ ${user.company.toUpperCase()}' : ''}',
          style: AppLocalization.digitalFont(context,
              color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            user.bio,
            textAlign: TextAlign.center,
            style: AppLocalization.digitalFont(context,
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(BuildContext context) {
    final postController = Provider.of<PostController>(context);

    return StreamBuilder<List<PostModel>>(
      stream: postController.getUserPosts(user.uid),
      builder: (context, snapshot) {
        final posts = snapshot.data ?? [];
        final totalLikes =
            posts.fold<int>(0, (sum, post) => sum + post.likes.length);
        final totalPosts = posts.length;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn(
                  context,
                  user.following.length.toString(),
                  AppLocalization.of(context)!
                      .translate('following')
                      .toUpperCase(),
                  NetworkTab.following),
              _buildDivider(),
              _buildStatColumn(
                  context,
                  user.followers.length.toString(),
                  AppLocalization.of(context)!
                      .translate('followers')
                      .toUpperCase(),
                  NetworkTab.followers),
              _buildDivider(),
              _buildStatColumn(
                  context,
                  totalPosts.toString(),
                  AppLocalization.of(context)!
                      .translate('commits')
                      .toUpperCase(),
                  null),
              _buildDivider(),
              _buildStatColumn(
                  context,
                  totalLikes.toString(),
                  AppLocalization.of(context)!.translate('likes').toUpperCase(),
                  null),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(
      BuildContext context, String value, String label, NetworkTab? tab) {
    return GestureDetector(
      onTap: tab != null
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => NetworkPage(
                        initialTab: tab,
                        targetUserId: user.uid,
                        isSingleMode: true,
                      )))
          : null,
      child: Column(
        children: [
          Text(value,
              style: AppLocalization.digitalFont(context,
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label,
              style: AppLocalization.digitalFont(context,
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(
      width: 1, height: 32, color: Colors.white.withValues(alpha: 0.05));

  Widget _buildActionButtons(
      BuildContext context, bool isFollowing, AuthController auth) {
    final locale = AppLocalization.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMainButton(
                context,
                label: isFollowing
                    ? AppLocalization.of(context)!
                        .translate('unfollow')
                        .toUpperCase()
                    : AppLocalization.of(context)!
                        .translate('follow')
                        .toUpperCase(),
                isActive: isFollowing,
                onTap: () async {
                  if (isFollowing) {
                    await FirestoreService()
                        .unfollowUser(auth.currentUser!.uid, user.uid);
                  } else {
                    await FirestoreService()
                        .followUser(auth.currentUser!.uid, user.uid);
                  }
                  if (context.mounted) {
                    AppWidgets.showToast(context, locale.translate('action_synced'),
                        type: SnackBarType.success);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMainButton(
                context,
                label: AppLocalization.of(context)!.translate('message_caps'),
                onTap: () async {
                  final chatId = await FirestoreService()
                      .getOrCreateChat(auth.currentUser!.uid, user.uid);
                  if (!context.mounted) return;
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                              chatId: chatId, otherUserId: user.uid)));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => TerminalDialog(
                headerTag: 'NETWORK_ISOLATION',
                title: locale.translate('TERMINATE_NODE'),
                body: locale
                    .translate('TERMINATE_CONFIRM')
                    .replaceFirst('{}', user.name),
                confirmLabel: locale.translate('CONFIRM_ACTION'),
                cancelLabel: locale.translate('CANCEL_ACTION'),
                isDestructive: true,
                onConfirm: () async {
                  await auth.blockUser(user.uid);
                  if (context.mounted) {
                    AppWidgets.showToast(context, locale.translate('block_success'),
                        type: SnackBarType.error);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }
                },
              ),
            );
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Icon(Icons.block_rounded,
                color: Colors.redAccent, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminActionPanel(BuildContext context, AppLocalization locale) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_rounded,
                  color: Colors.redAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                locale.translate('PRIVILEGED_ACCESS'),
                style: AppLocalization.digitalFont(context,
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAdminActionTile(
            context,
            icon: Icons.gavel_rounded,
            label: user.isBanned
                ? locale.translate('unban_user')
                : locale.translate('ban_user'),
            color: Colors.redAccent,
            onTap: () =>
                _toggleAdminAction(context, 'isBanned', !user.isBanned),
          ),
          _buildAdminActionDivider(),
          _buildAdminActionTile(
            context,
            icon: Icons.verified_user_rounded,
            label: user.isVerified
                ? locale.translate('unverify')
                : locale.translate('verify'),
            color: const Color(0xFF00E5FF),
            onTap: () =>
                _toggleAdminAction(context, 'isVerified', !user.isVerified),
          ),
          _buildAdminActionDivider(),
          _buildAdminActionTile(
            context,
            icon: Icons.check_circle_rounded,
            label: user.isApproved
                ? locale.translate('unapprove')
                : locale.translate('approve'),
            color: Colors.greenAccent,
            onTap: () =>
                _toggleAdminAction(context, 'isApproved', !user.isApproved),
          ),
          _buildAdminActionDivider(),
          _buildAdminActionTile(
            context,
            icon: Icons.admin_panel_settings_rounded,
            label: user.isAdmin
                ? locale.translate('revoke_admin')
                : locale.translate('make_admin'),
            color: Colors.amberAccent,
            onTap: () => _toggleAdminAction(context, 'isAdmin', !user.isAdmin),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionTile(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Text(
              label.toUpperCase(),
              style: AppLocalization.digitalFont(context,
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.1), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionDivider() => Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.white.withValues(alpha: 0.02));

  void _toggleAdminAction(BuildContext context, String field, bool value) {
    final admin = Provider.of<AdminController>(context, listen: false);
    final locale = AppLocalization.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => TerminalDialog(
        headerTag: 'MANIFEST_OVERRIDE',
        title: locale.translate('CONFIRM_ACTION'),
        body: 'Sync $field manifestation to $value for node ${user.name}?',
        confirmLabel: 'EXECUTE',
        cancelLabel: 'ABORT',
        isDestructive: field == 'isBanned',
        onConfirm: () async {
          if (field == 'isBanned') {
            await admin.banUser(user.uid, value);
          } else if (field == 'isVerified') {
            await admin.verifyUser(user.uid, value);
          } else if (field == 'isApproved') {
            await admin.approveUser(user.uid, value);
          } else if (field == 'isAdmin') {
            await admin.toggleAdmin(user.uid, value);
          }

          if (context.mounted) {
            AppWidgets.showToast(context, locale.translate('action_synced'),
                type: SnackBarType.success);
            Navigator.pop(ctx);
          }
        },
      ),
    );
  }

  Widget _buildAccountManagement(
      BuildContext context, AuthController auth, AppLocalization locale) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                locale.translate('ACCOUNT_MANAGEMENT'),
                style: AppLocalization.digitalFont(context,
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Color(0xFF00E5FF), shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            locale.translate('ACCOUNT_MANAGEMENT_SUB'),
            style: AppLocalization.digitalFont(context,
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                height: 1.4),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfilePage())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded,
                      color: Colors.black, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      locale.translate('edit_profile'),
                      style: AppLocalization.digitalFont(context,
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 15),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.black, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            locale.translate('NOTIFICATION_LOGS').toUpperCase(),
            style: AppLocalization.digitalFont(context,
                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          _buildTopicToggle(
            context,
            auth: auth,
            topic: 'posts',
            label: locale.translate('POSTS_TOPIC'),
            icon: Icons.rss_feed_rounded,
          ),
          const SizedBox(height: 12),
          _buildTopicToggle(
            context,
            auth: auth,
            topic: 'all',
            label: locale.translate('ALL_TOPIC'),
            icon: Icons.broadcast_on_personal_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTopicToggle(
    BuildContext context, {
    required AuthController auth,
    required String topic,
    required String label,
    required IconData icon,
  }) {
    final isSubscribed = auth.currentUser?.subscribedTopics.contains(topic) ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSubscribed ? const Color(0xFF00E5FF).withValues(alpha: 0.1) : Colors.transparent),
      ),
      child: Row(
        children: [
          Icon(icon, color: isSubscribed ? const Color(0xFF00E5FF) : Colors.white24, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: AppLocalization.digitalFont(context,
                  color: isSubscribed ? Colors.white : Colors.white24,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
          ),
          Switch(
            value: isSubscribed,
            onChanged: (val) => auth.toggleTopicSubscription(topic, val),
            activeThumbColor: const Color(0xFF00E5FF),
            activeTrackColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }




  Widget _buildNetworkHubPanel(
      BuildContext context, AuthController auth, AppLocalization locale) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locale.translate('NETWORK_HUB'),
            style: AppLocalization.digitalFont(context,
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          _buildNetworkRefTile(
            context,
            icon: Icons.people_rounded,
            label: locale.translate('tab_following'),
            value: user.following.length.toString(),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NetworkPage(
                        initialTab: NetworkTab.following,
                        targetUserId: user.uid,
                        isSingleMode: true))),
          ),
          const SizedBox(height: 2),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.02)),
          _buildNetworkRefTile(
            context,
            icon: Icons.person_add_rounded,
            label: locale.translate('tab_followers'),
            value: user.followers.length.toString(),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NetworkPage(
                        initialTab: NetworkTab.followers,
                        targetUserId: user.uid,
                        isSingleMode: true))),
          ),
          const SizedBox(height: 32),
          Text(
            locale.translate('LAST_SYNC').replaceFirst('{}',
                '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}'),
            style: AppLocalization.digitalFont(context,
                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkRefTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF00E5FF), size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppLocalization.digitalFont(context,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
            const Spacer(),
            Text(
              value,
              style: AppLocalization.digitalFont(context,
                  color: const Color(0xFF00E5FF),
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivilegedAccess(
      BuildContext context, AuthController auth, AppLocalization locale) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A141A),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.1)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.admin_panel_settings_rounded,
                size: 140, color: Colors.white.withValues(alpha: 0.02)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: Color(0xFF00E5FF), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      locale.translate('PRIVILEGED_ACCESS'),
                      style: AppLocalization.digitalFont(context,
                          color: const Color(0xFF00E5FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  locale.translate('admin_dashboard_title'),
                  style: AppLocalization.digitalFont(context,
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminDashboardPage())),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              const Color(0xFF00E5FF).withValues(alpha: 0.1)),
                    ),
                    child: Center(
                      child: Text(
                        locale.translate('INITIALIZE_TERMINAL'),
                        style: AppLocalization.digitalFont(context,
                            color: const Color(0xFF00E5FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton(BuildContext context,
      {required String label,
      bool isActive = false,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isActive ? Colors.transparent : const Color(0xFFB2FEFA),
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: Colors.white.withValues(alpha: 0.1))
              : null,
          gradient: isActive
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFB2FEFA), Color(0xFF0ED2F7)]),
        ),
        child: Center(
          child: Text(
            label,
            style: AppLocalization.digitalFont(context,
                color: isActive ? Colors.white : Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityFeed(PostController postController, bool isAdmin) {
    return StreamBuilder<List<PostModel>>(
      stream: postController.getUserPosts(user.uid),
      builder: (context, snapshot) {
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                AppLocalization.of(context)!.translate('no_posts_yet'),
                style: AppLocalization.digitalFont(context,
                    color: Colors.white10,
                    fontSize: 14,
                    fontWeight: FontWeight.w800),
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final parts = _parseManifest(post.text);
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildCommitCard(
                context,
                postId: post.id,
                status:
                    AppLocalization.of(context)!.translate('committed_caps'),
                time: _timeAgo(post.createdAt, context),
                content: parts['body'] ?? post.text,
                code: parts['code'],
                images: post.images,
                likes: post.likes.length,
                comments: post.commentCount,
                isAdmin: isAdmin,
              ),
            );
          },
        );
      },
    );
  }

  Map<String, String?> _parseManifest(String text) {
    String? body = text;
    String? code;
    final codeMatch = RegExp(r'```(?:\w+)?\n([\s\S]*?)```').firstMatch(text);
    if (codeMatch != null) {
      code = codeMatch.group(1)?.trim();
      body = text.replaceFirst(codeMatch.group(0)!, '').trim();
    }
    return {'body': body, 'code': code};
  }

  String _timeAgo(DateTime dt, BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) {
      return locale
          .translate('d_ago')
          .replaceFirst('{}', diff.inDays.toString());
    }
    if (diff.inHours > 0) {
      return locale
          .translate('h_ago')
          .replaceFirst('{}', diff.inHours.toString());
    }
    if (diff.inMinutes > 0) {
      return locale
          .translate('m_ago')
          .replaceFirst('{}', diff.inMinutes.toString());
    }
    return locale.translate('just_now');
  }

  Widget _buildCommitCard(BuildContext context,
      {required String postId,
      required String status,
      required String time,
      required String content,
      String? code,
      List<String> images = const [],
      int likes = 0,
      int comments = 0,
      bool isAdmin = false}) {
    final locale = AppLocalization.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSmallAvatar(user),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(user.name,
                            style: AppLocalization.digitalFont(context,
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                                color: Color(0xFF00E5FF),
                                shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(status,
                            style: AppLocalization.digitalFont(context,
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                      ],
                    ),
                    Text(time,
                        style: AppLocalization.digitalFont(context,
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (isAdmin)
                IconButton(
                  onPressed: () => _deletePost(context, postId, locale),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 20),
                  tooltip: locale.translate('PURGE_MANIFEST'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          MarkdownBody(
            data: content,
            onTapLink: (text, href, title) {
              if (href != null) {
                launchUrl(Uri.parse(href),
                    mode: LaunchMode.externalApplication);
              }
            },
            styleSheet: MarkdownStyleSheet(
              p: AppLocalization.digitalFont(
                context,
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.6,
              ),
              strong: const TextStyle(
                  color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
              a: const TextStyle(
                  color: Color(0xFF00E5FF),
                  decoration: TextDecoration.underline),
            ),
          ),
          if (code != null) ...[
            const SizedBox(height: 20),
            _buildCodeBlock(code),
          ],
          if (images.isNotEmpty) ...[
            const SizedBox(height: 20),
            PostMediaWidget(images: images, postId: postId, height: 220),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              _buildInteraction(
                  context, Icons.favorite_rounded, likes.toString()),
              const SizedBox(width: 24),
              _buildInteraction(
                  context, Icons.chat_bubble_rounded, comments.toString()),
              const Spacer(),
              Icon(Icons.share_rounded,
                  color: Colors.white.withValues(alpha: 0.2), size: 18),
            ],
          ),
        ],
      ),
    );
  }

  void _deletePost(
      BuildContext context, String postId, AppLocalization locale) {
    showDialog(
      context: context,
      builder: (ctx) => TerminalDialog(
        headerTag: 'PURGE_PROTOCOL',
        title: locale.translate('PURGE_MANIFEST'),
        body: locale.translate('PURGE_MANIFEST_CONFIRM'),
        confirmLabel: 'PURGE',
        cancelLabel: 'ABORT',
        isDestructive: true,
        onConfirm: () async {
          await Provider.of<AdminController>(context, listen: false)
              .deletePost(postId);
          if (context.mounted) {
            AppWidgets.showToast(context, locale.translate('post_purged'),
                type: SnackBarType.error);
            Navigator.pop(ctx);
          }
        },
      ),
    );
  }

  Widget _buildSmallAvatar(UserModel user) {
    return AppCachedImage(
      imageUrl: user.profileImage,
      width: 32,
      height: 32,
      isCircle: true,
      errorWidget: const Icon(Icons.person, color: Colors.white24, size: 16),
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFF5F56), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFF27C93F), shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 16),
          SelectableText(
            code,
            style: GoogleFonts.sourceCodePro(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                fontSize: 11,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInteraction(BuildContext context, IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.2), size: 18),
        const SizedBox(width: 8),
        Text(count,
            style: AppLocalization.digitalFont(context,
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _GuestProfileUI extends StatelessWidget {
  final AppLocalization locale;
  const _GuestProfileUI({required this.locale});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.account_circle_outlined,
                    color: Color(0xFF00E5FF), size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                locale.translate('LOGIN_REQUIRED_TITLE'),
                textAlign: TextAlign.center,
                style: AppLocalization.digitalFont(context, 
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                locale.translate('LOGIN_REQUIRED_BODY'),
                textAlign: TextAlign.center,
                style: AppLocalization.digitalFont(context, 
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      child: Center(
                        child: Text(
                          locale.translate('EXECUTE_LOGIN'),
                          style: AppLocalization.digitalFont(
                            context,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
