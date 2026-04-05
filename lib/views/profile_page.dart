import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../controllers/post_controller.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import 'chat_detail_screen.dart';
import 'network_page.dart';
import 'settings_screen.dart';
import 'admin_dashboard_page.dart';
import 'edit_profile_page.dart';
import '../providers/app_provider.dart';

import '../services/notification_service.dart';
import '../models/notification_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/post_media_widget.dart';

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final myUser = authController.currentUser;

    if (widget.userId == null || widget.userId == myUser?.uid) {
      if (myUser == null) {
        return const Scaffold(
            backgroundColor: Color(0xFF0D0D0D),
            body: Center(
                child: CircularProgressIndicator(color: Color(0xFF00E5FF))));
      }
      return _ProfileView(user: myUser, isOwnProfile: true);
    }

    return FutureBuilder<UserModel?>(
      future: FirestoreService().getUser(widget.userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              backgroundColor: Color(0xFF0D0D0D),
              body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00E5FF))));
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
        body: SingleChildScrollView(
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
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: const Color(0xFF00E5FF), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalization.of(context)!.translate('profile_caps'),
          style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildIdentityHeader(context, isFollowing),
            const SizedBox(height: 48),
            _buildStatsHeader(context),
            const SizedBox(height: 40),
            _buildNodalMetadata(locale),
            const SizedBox(height: 40),
            _buildActionButtons(context, isFollowing, auth),
            const SizedBox(height: 48),
            _buildActivityFeed(Provider.of<PostController>(context)),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildNodalMetadata(AppLocalization locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale.translate('NODE_METADATA'),
          style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFF00E5FF).withOpacity(0.4),
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
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Column(
            children: [
              _buildMetadataRow(
                locale.translate('location').toUpperCase(),
                user.city.isNotEmpty && user.country.isNotEmpty
                    ? '${user.city.toUpperCase()}, ${user.country.toUpperCase()}'
                    : locale.translate('UNKNOWN_HUB'),
                Icons.location_on_outlined,
              ),
              if (user.company.isNotEmpty)
                _buildMetadataRow(
                  locale.translate('company_label').toUpperCase(),
                  user.company.toUpperCase(),
                  Icons.business_rounded,
                ),
              _buildMetadataDivider(),
              _buildMetadataRow(
                locale.translate('birth_date').toUpperCase(),
                user.birthDate != null
                    ? '${user.age} ${locale.translate('YEAR_CYCLE')}'
                    : locale.translate('UNDEFINED_GENESIS'),
                Icons.history_toggle_off_rounded,
              ),
              _buildMetadataRow(
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
                      _buildSocialChip('GITHUB', Icons.code_rounded,
                          user.socialLinks!['github']!),
                    if (user.socialLinks!['linkedin']?.isNotEmpty == true)
                      _buildSocialChip('LINKEDIN', Icons.link_rounded,
                          user.socialLinks!['linkedin']!),
                    if (user.socialLinks!['portfolio']?.isNotEmpty == true)
                      _buildSocialChip('PORTFOLIO', Icons.language_rounded,
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

  Widget _buildMetadataRow(String label, String value, IconData icon) {
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
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataDivider() => Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: Colors.white.withOpacity(0.03));

  Widget _buildSocialChip(String label, IconData icon, String url) {
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
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF00E5FF), size: 14),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
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
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: const Color(0xFF00E5FF).withOpacity(0.5), width: 3),
            image: user.profileImage.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(user.profileImage), fit: BoxFit.cover)
                : null,
            color: Colors.white.withOpacity(0.05),
          ),
          child: Stack(
            children: [
              if (user.profileImage.isEmpty)
                Center(
                    child: Text(user.initials,
                        style: GoogleFonts.spaceGrotesk(
                            color: Colors.white.withOpacity(0.1),
                            fontSize: 48,
                            fontWeight: FontWeight.w800))),
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
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.name,
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.verified_rounded,
                color: Color(0xFF00E5FF), size: 20),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${user.position.toUpperCase()}${user.company.isNotEmpty ? ' @ ${user.company.toUpperCase()}' : ''}',
          style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFF00E5FF).withOpacity(0.6),
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
            style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.5),
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
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      Container(width: 1, height: 32, color: Colors.white.withOpacity(0.05));

  Widget _buildActionButtons(
      BuildContext context, bool isFollowing, AuthController auth) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMainButton(
                label: isFollowing
                    ? AppLocalization.of(context)!
                        .translate('following')
                        .toUpperCase()
                    : AppLocalization.of(context)!
                        .translate('follow')
                        .toUpperCase(),
                isActive: isFollowing,
                onTap: () {
                  if (isFollowing) {
                    FirestoreService()
                        .unfollowUser(auth.currentUser!.uid, user.uid);
                  } else {
                    FirestoreService()
                        .followUser(auth.currentUser!.uid, user.uid);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMainButton(
                label: AppLocalization.of(context)!.translate('message_caps'),
                onTap: () async {
                  final chatId = await FirestoreService()
                      .getOrCreateChat(auth.currentUser!.uid, user.uid);
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
          onTap: () {},
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: const Icon(Icons.block_rounded,
                color: Colors.white24, size: 20),
          ),
        ),
      ],
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
                style: GoogleFonts.spaceGrotesk(
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
            style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.5),
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
                      style: GoogleFonts.spaceGrotesk(
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
          const SizedBox(height: 12),
          _buildConfigActionTile(
            icon: Icons.visibility_rounded,
            title: locale.translate('PREVIEW_PUBLIC_PROFILE'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
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
                      locale.translate('PREVIEW_MODE'),
                      style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFF00E5FF).withOpacity(0.5),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 2),
                    ),
                    centerTitle: true,
                  ),
                  body: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        _buildIdentityHeader(context, false),
                        const SizedBox(height: 48),
                        _buildStatsHeader(context),
                        const SizedBox(height: 40),
                        _buildNodalMetadata(locale),
                        const SizedBox(height: 48),
                        _buildActivityFeed(
                            Provider.of<PostController>(context)),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildConfigActionTile(
            icon: Icons.history_rounded,
            title: locale.translate('change_password'),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: titleColor?.withOpacity(0.6) ?? Colors.white30,
                size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                  color: titleColor ?? Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
          ],
        ),
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
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          _buildNetworkRefTile(
            context,
            icon: Icons.people_rounded,
            label: locale.translate('tab_following'),
            value: '${(user.following.length / 1000).toStringAsFixed(1)}k',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NetworkPage(
                        initialTab: NetworkTab.following,
                        targetUserId: user.uid,
                        isSingleMode: true))),
          ),
          const SizedBox(height: 2),
          Container(height: 1, color: Colors.white.withOpacity(0.02)),
          const SizedBox(height: 2),
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
            locale.translate('LAST_SYNC').replaceFirst('{}', '14:32'),
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withOpacity(0.2),
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
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF00E5FF), size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
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
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.admin_panel_settings_rounded,
                size: 140, color: Colors.white.withOpacity(0.02)),
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
                      style: GoogleFonts.spaceGrotesk(
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
                  style: GoogleFonts.spaceGrotesk(
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
                      color: const Color(0xFF00E5FF).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF00E5FF).withOpacity(0.1)),
                    ),
                    child: Center(
                      child: Text(
                        locale.translate('INITIALIZE_TERMINAL'),
                        style: GoogleFonts.spaceGrotesk(
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


  Widget _buildMainButton(
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
              ? Border.all(color: Colors.white.withOpacity(0.1))
              : null,
          gradient: isActive
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFB2FEFA), Color(0xFF0ED2F7)]),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
                color: isActive ? Colors.white : Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityFeed(PostController postController) {
    return StreamBuilder<List<PostModel>>(
      stream: postController.getUserPosts(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                AppLocalization.of(context)!.translate('no_commit_history'),
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withOpacity(0.1),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2),
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
                status:
                    AppLocalization.of(context)!.translate('committed_caps'),
                time: _timeAgo(post.createdAt, context),
                content: parts['body'] ?? post.text,
                code: parts['code'],
                images: post.images,
                likes: post.likes.length,
                comments: post.commentCount,
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
    if (diff.inDays > 0)
      return locale
          .translate('d_ago')
          .replaceFirst('{}', diff.inDays.toString());
    if (diff.inHours > 0)
      return locale
          .translate('h_ago')
          .replaceFirst('{}', diff.inHours.toString());
    if (diff.inMinutes > 0)
      return locale
          .translate('m_ago')
          .replaceFirst('{}', diff.inMinutes.toString());
    return locale.translate('just_now');
  }

  Widget _buildCommitCard(
      {required String status,
      required String time,
      required String content,
      String? code,
      List<String> images = const [],
      int likes = 0,
      int comments = 0}) {
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
              _buildSmallAvatar(),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(user.name,
                          style: GoogleFonts.spaceGrotesk(
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
                          style: GoogleFonts.spaceGrotesk(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1)),
                    ],
                  ),
                  Text(time,
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withOpacity(0.2),
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                ],
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
              p: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.9),
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
            PostMediaWidget(images: images, height: 220),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              _buildInteraction(Icons.favorite_rounded, likes.toString()),
              const SizedBox(width: 24),
              _buildInteraction(Icons.chat_bubble_rounded, comments.toString()),
              const Spacer(),
              Icon(Icons.share_rounded,
                  color: Colors.white.withOpacity(0.2), size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: user.profileImage.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(user.profileImage), fit: BoxFit.cover)
            : null,
        color: Colors.white10,
      ),
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
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
                color: const Color(0xFF00E5FF).withOpacity(0.8),
                fontSize: 11,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  // Removed unused _buildImagePayload in favor of PostMediaWidget

  Widget _buildInteraction(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.2), size: 18),
        const SizedBox(width: 8),
        Text(count,
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}
