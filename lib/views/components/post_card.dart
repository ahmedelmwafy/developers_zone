import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/post_controller.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../post_details_page.dart';
import '../profile_page.dart';
import '../create_post_screen.dart';

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

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PostDetailsPage(post: post))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ProfilePage(userId: post.authorId))),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.cardLight,
                        backgroundImage: post.authorProfileImage.isNotEmpty
                            ? NetworkImage(post.authorProfileImage)
                            : null,
                        child: post.authorProfileImage.isEmpty
                            ? const Icon(Icons.person,
                                size: 22, color: AppColors.textSecondary)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name + position + time
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  ProfilePage(userId: post.authorId))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  post.authorName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (post.isAuthorVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified,
                                    color: AppColors.accent, size: 14),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  post.authorPosition,
                                  style: const TextStyle(
                                    color: AppColors.primaryLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _timeAgo(post.createdAt, locale),
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // More options / own post menu
                  if (!isMe && currentUser != null)
                    _PostMenu(post: post, authController: authController, locale: locale)
                  else if (isMe)
                    _OwnPostMenu(post: post, postController: postController, locale: locale),
                ],
              ),
            ),

            // ── Post text ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                post.text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  height: 1.6,
                  fontSize: 14,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Images ────────────────────────────────────────────────
            if (post.images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Image.network(
                        post.images.first,
                        width: double.infinity,
                        height: post.images.length == 1 ? null : 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 160,
                            color: AppColors.cardLight,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: AppColors.cardLight,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: AppColors.textMuted, size: 32),
                          ),
                        ),
                      ),
                      if (post.images.length > 1)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '+${post.images.length - 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // ── Divider + Stats ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  // Like avatars / count
                  _LikeCountRow(likes: post.likes),
                  const Spacer(),
                  Text(
                    post.commentCount == 1
                        ? locale.translate('comment_count')
                        : locale.translate('comments_count').replaceFirst('{}', post.commentCount.toString()),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),

            // ── Thin divider ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              height: 0.5,
              color: Colors.white.withValues(alpha: 0.07),
            ),

            // ── Action bar ────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  _ActionBtn(
                    icon: isLiked
                        ? FontAwesomeIcons.solidHeart
                        : FontAwesomeIcons.heart,
                    label: isLiked ? locale.translate('liked_label') : locale.translate('like_label'),
                    color: isLiked ? Colors.redAccent : AppColors.textMuted,
                    onTap: currentUser == null
                        ? null
                        : () => postController.togglePostLike(
                            post.id, currentUser.uid, !isLiked),
                  ),
                  _ActionBtn(
                    icon: FontAwesomeIcons.commentDots,
                    label: locale.translate('comment_label'),
                    color: AppColors.textMuted,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PostDetailsPage(post: post))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt, AppLocalization locale) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 7) return '${dt.day}/${dt.month}/${dt.year}';
    if (diff.inDays > 0) {
      return locale.translate('days_ago').replaceFirst('{}', diff.inDays.toString());
    }
    if (diff.inHours > 0) {
      return locale.translate('hours_ago').replaceFirst('{}', diff.inHours.toString());
    }
    if (diff.inMinutes > 0) {
      return locale.translate('minutes_ago').replaceFirst('{}', diff.inMinutes.toString());
    }
    return locale.translate('just_now');
  }
}

// ── Like Count Row ────────────────────────────────────────────────────────────

class _LikeCountRow extends StatelessWidget {
  final List<String> likes;
  const _LikeCountRow({required this.likes});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    if (likes.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite,
              color: Colors.redAccent, size: 11),
        ),
        const SizedBox(width: 6),
        Text(
          likes.length == 1
              ? locale.translate('like_count')
              : locale.translate('likes_count').replaceFirst('{}', likes.length.toString()),
          style: const TextStyle(
              color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Other-user post menu ──────────────────────────────────────────────────────

class _PostMenu extends StatelessWidget {
  final PostModel post;
  final AuthController authController;
  final AppLocalization locale;

  const _PostMenu({
    required this.post,
    required this.authController,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_horiz, color: AppColors.textMuted, size: 20),
      color: AppColors.cardLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (val) {
        if (val == 'block') authController.blockUser(post.authorId);
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'block',
          child: Row(
            children: [
              const Icon(Icons.block, color: AppColors.error, size: 16),
              const SizedBox(width: 8),
              Text(locale.translate('block'),
                  style: const TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Own-post menu ─────────────────────────────────────────────────────────────

class _OwnPostMenu extends StatelessWidget {
  final PostModel post;
  final PostController postController;
  final AppLocalization locale;

  const _OwnPostMenu({
    required this.post,
    required this.postController,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.more_horiz, color: AppColors.textMuted, size: 20),
      color: AppColors.cardLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (val) async {
        if (val == 'edit') {
           Navigator.of(context).push(MaterialPageRoute(
               builder: (_) => CreatePostScreen(postToEdit: post)));
        } else if (val == 'delete') {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: Text(locale.translate('delete_post_title'),
                  style: const TextStyle(color: AppColors.textPrimary)),
              content: Text(
                locale.translate('delete_post_confirm'),
                style:
                    const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(locale.translate('cancel'),
                      style: const TextStyle(color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(locale.translate('delete'),
                      style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
          if (confirm == true && context.mounted) {
            await postController.deletePost(post.id);
            AppWidgets.showSnackBar(context, locale.translate('post_deleted'),
                type: SnackBarType.success);
          }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined,
                  color: AppColors.textPrimary, size: 16),
              const SizedBox(width: 8),
              Text(locale.translate('edit'),
                  style: const TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 16),
              const SizedBox(width: 8),
              Text(locale.translate('delete_post'),
                  style: const TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }
}
