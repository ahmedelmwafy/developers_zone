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
import '../providers/app_provider.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({this.userId, super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final myUser = authController.currentUser;

    if (widget.userId == null || widget.userId == myUser?.uid) {
      if (myUser == null) {
        return const Scaffold(backgroundColor: Color(0xFF0D0D0D), body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))));
      }
      return _ProfileView(user: myUser, isOwnProfile: true);
    }

    return FutureBuilder<UserModel?>(
      future: FirestoreService().getUser(widget.userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Color(0xFF0D0D0D), body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(backgroundColor: const Color(0xFF0D0D0D), body: Center(child: Text(AppLocalization.of(context)!.translate('user_not_found'), style: const TextStyle(color: Colors.white24))));
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
    final isFollowing = auth.currentUser?.following.contains(user.uid) ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF00E5FF), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalization.of(context)!.translate('profile_caps'),
          style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.5),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
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
            _buildActionButtons(context, isFollowing, auth),
            const SizedBox(height: 48),
            _buildActivityFeed(Provider.of<PostController>(context)),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityHeader(BuildContext context, bool isFollowing) {
    return Column(
      children: [
        Container(
          width: 140, height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5), width: 3),
            image: user.profileImage.isNotEmpty ? DecorationImage(image: NetworkImage(user.profileImage), fit: BoxFit.cover) : null,
            color: Colors.white.withOpacity(0.05),
          ),
          child: Stack(
            children: [
              if (user.profileImage.isEmpty) const Center(child: Icon(Icons.person, color: Colors.white10, size: 60)),
              Positioned(
                bottom: 10, right: 10,
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0D0D0D), width: 4),
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
              style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.verified_rounded, color: Color(0xFF00E5FF), size: 20),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${user.position.toUpperCase()} @ OBSIDIANLABS',
          style: GoogleFonts.spaceGrotesk(color: const Color(0xFF00E5FF).withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            user.bio,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn(context, user.following.length.toString(), AppLocalization.of(context)!.translate('following').toUpperCase(), NetworkTab.following),
          _buildDivider(),
          _buildStatColumn(context, user.followers.length.toString(), AppLocalization.of(context)!.translate('followers').toUpperCase(), NetworkTab.followers),
          _buildDivider(),
          _buildStatColumn(context, '450', AppLocalization.of(context)!.translate('commits'), null),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label, NetworkTab? tab) {
    return GestureDetector(
      onTap: tab != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => NetworkPage(initialTab: tab))) : null,
      child: Column(
        children: [
          Text(value, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.3), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(width: 1, height: 32, color: Colors.white.withOpacity(0.05));

  Widget _buildActionButtons(BuildContext context, bool isFollowing, AuthController auth) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMainButton(
                label: isFollowing ? AppLocalization.of(context)!.translate('following').toUpperCase() : AppLocalization.of(context)!.translate('follow').toUpperCase(),
                isActive: isFollowing,
                onTap: () {
                   if (isFollowing) {
                     FirestoreService().unfollowUser(auth.currentUser!.uid, user.uid);
                   } else {
                     FirestoreService().followUser(auth.currentUser!.uid, user.uid);
                   }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMainButton(
                label: AppLocalization.of(context)!.translate('message_caps'),
                onTap: () async {
                   final chatId = await FirestoreService().getOrCreateChat(auth.currentUser!.uid, user.uid);
                   Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(chatId: chatId, otherUserId: user.uid)));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: const Icon(Icons.block_rounded, color: Colors.white24, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton({required String label, bool isActive = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isActive ? Colors.transparent : const Color(0xFFB2FEFA),
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
          gradient: isActive ? null : const LinearGradient(colors: [Color(0xFFB2FEFA), Color(0xFF0ED2F7)]),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(color: isActive ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
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
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                AppLocalization.of(context)!.translate('no_commit_history'),
                style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.1), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2),
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
                status: AppLocalization.of(context)!.translate('committed_caps'),
                time: _timeAgo(post.createdAt, context),
                content: parts['body'] ?? post.text,
                code: parts['code'],
                hasImage: post.images.isNotEmpty,
                imageUrl: post.images.isNotEmpty ? post.images.first : null,
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
    if (diff.inDays > 0) return locale.translate('d_ago').replaceFirst('{}', diff.inDays.toString());
    if (diff.inHours > 0) return locale.translate('h_ago').replaceFirst('{}', diff.inHours.toString());
    if (diff.inMinutes > 0) return locale.translate('m_ago').replaceFirst('{}', diff.inMinutes.toString());
    return locale.translate('just_now');
  }

  Widget _buildCommitCard({required String status, required String time, required String content, String? code, bool hasImage = false, String? imageUrl, int likes = 0, int comments = 0}) {
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
                      Text(user.name, style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(status, style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ],
                  ),
                  Text(time, style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.2), fontSize: 9, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(content, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.6)),
          if (code != null) ...[
            const SizedBox(height: 20),
            _buildCodeBlock(code),
          ],
          if (hasImage && imageUrl != null) ...[
            const SizedBox(height: 20),
            _buildImagePayload(imageUrl),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              _buildInteraction(Icons.favorite_rounded, likes.toString()),
              const SizedBox(width: 24),
              _buildInteraction(Icons.chat_bubble_rounded, comments.toString()),
              const Spacer(),
              Icon(Icons.share_rounded, color: Colors.white.withOpacity(0.2), size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallAvatar() {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: user.profileImage.isNotEmpty ? DecorationImage(image: NetworkImage(user.profileImage), fit: BoxFit.cover) : null,
        color: Colors.white10,
      ),
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0D0D0D), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.04))),
      child: Text(
        code,
        style: GoogleFonts.sourceCodePro(color: const Color(0xFF00E5FF).withOpacity(0.8), fontSize: 11, height: 1.5),
      ),
    );
  }

  Widget _buildImagePayload(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.white.withOpacity(0.05),
          child: Image.network(url, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildInteraction(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.2), size: 18),
        const SizedBox(width: 8),
        Text(count, style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
