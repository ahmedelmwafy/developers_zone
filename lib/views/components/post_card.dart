import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/post_controller.dart';
import '../../providers/app_provider.dart';
import '../post_details_page.dart';
import '../profile_page.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  const PostCard({required this.post, super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final postController = Provider.of<PostController>(context);
    final locale = AppLocalization.of(context)!;
    final currentUser = authController.currentUser;
    final isMe = currentUser?.uid == post.authorId;
    final isLiked = currentUser != null && post.likes.contains(currentUser.uid);

    // Dynamic Manifest Parsing
    final parts = _parseManifest(post.text);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PostDetailsPage(post: post))),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAuthorHeader(context, post, isMe, currentUser,
                    authController, postController, locale),
                const SizedBox(height: 16),
                _buildDynamicContent(parts),
                if (parts['code'] != null) ...[
                  const SizedBox(height: 16),
                  _buildCodeManifest(parts['code']!),
                ],
                if (post.images.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildPostMedia(post.images.first),
                ],
                const SizedBox(height: 24),
                _buildActionRow(post, isLiked, currentUser, postController,
                    locale, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, String?> _parseManifest(String text) {
    String? title;
    String? body = text;
    String? code;

    // Detect Title
    if (text.startsWith('# ')) {
      final lines = text.split('\n');
      title = lines.first.replaceFirst('# ', '').trim();
      body = lines.skip(1).join('\n').trim();
    }

    // Detect Code Block
    final codeMatch = RegExp(r'```(?:\w+)?\n([\s\S]*?)```').firstMatch(body);
    if (codeMatch != null) {
      code = codeMatch.group(1)?.trim();
      body = body.replaceFirst(codeMatch.group(0)!, '').trim();
    }

    return {'title': title, 'body': body, 'code': code};
  }

  Widget _buildDynamicContent(Map<String, String?> parts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parts['title'] != null) ...[
          Text(
            parts['title']!,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (parts['body'] != null && parts['body']!.isNotEmpty) ...[
          Text(
            parts['body']!,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAuthorHeader(
      BuildContext context,
      PostModel post,
      bool isMe,
      dynamic currentUser,
      AuthController authController,
      PostController postController,
      AppLocalization locale) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ProfilePage(userId: post.authorId))),
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4)),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF0D0D0D),
              backgroundImage: post.authorProfileImage.isNotEmpty
                  ? NetworkImage(post.authorProfileImage)
                  : null,
              child: post.authorProfileImage.isEmpty
                  ? const Icon(Icons.person, size: 18, color: Colors.white24)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'COMMITTED ${_timeAgo(post.createdAt, locale).toUpperCase()} • ${post.authorPosition.toUpperCase()}',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        _buildMenuButton(context, post, isMe, currentUser, authController,
            postController, locale),
      ],
    );
  }

  Widget _buildMenuButton(
      BuildContext context,
      PostModel post,
      bool isMe,
      dynamic currentUser,
      AuthController authController,
      PostController postController,
      AppLocalization locale) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded,
          color: Colors.white.withOpacity(0.4), size: 20),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) async {
        if (val == 'delete' && isMe) {
          await postController.deletePost(post.id);
        } else if (val == 'block' && !isMe) {
          authController.blockUser(post.authorId);
        }
      },
      itemBuilder: (_) => isMe
          ? [
              _buildMenuItem('delete', Icons.delete_outline_rounded,
                  locale.translate('delete'), Colors.redAccent),
            ]
          : [
              _buildMenuItem('block', Icons.block_rounded,
                  locale.translate('block'), Colors.redAccent),
            ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      String value, IconData icon, String text, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(text, style: GoogleFonts.inter(color: color, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPostMedia(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Image.network(
          url,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 220,
              color: Colors.white.withOpacity(0.02),
              child: const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF00E5FF), strokeWidth: 2)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCodeManifest(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
              const Spacer(),
              Text('CODE_MANIFEST', style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.1), fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            code,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.sourceCodePro(
              color: const Color(0xFF00E5FF).withOpacity(0.8),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
      PostModel post,
      bool isLiked,
      dynamic currentUser,
      PostController postController,
      AppLocalization locale,
      BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildInteractionIcon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              '${post.likes.length}',
              isLiked ? Colors.redAccent : Colors.white.withOpacity(0.4),
              () => currentUser == null
                  ? null
                  : postController.togglePostLike(
                      post.id, currentUser.uid, !isLiked),
            ),
            const SizedBox(width: 20),
            _buildInteractionIcon(
              Icons.chat_bubble_outline_rounded,
              '${post.commentCount}',
              Colors.white.withOpacity(0.4),
              () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PostDetailsPage(post: post))),
            ),
          ],
        ),
        Icon(Icons.bookmark_outline_rounded,
            color: Colors.white.withOpacity(0.4), size: 20),
      ],
    );
  }

  Widget _buildInteractionIcon(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt, AppLocalization locale) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) return '${dt.day}/${dt.month}/${dt.year}';
    if (diff.inDays > 0) return '${diff.inDays}D AGO';
    if (diff.inHours > 0) return '${diff.inHours}H AGO';
    if (diff.inMinutes > 0) return '${diff.inMinutes}M AGO';
    return 'JUST NOW';
  }
}
