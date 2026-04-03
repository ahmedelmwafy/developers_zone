import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/post_controller.dart';
import '../models/post_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'profile_page.dart';
import 'components/shimmer_loading.dart';

class PostDetailsPage extends StatefulWidget {
  final PostModel post;
  const PostDetailsPage({required this.post, super.key});

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty || _isSending) return;
    setState(() => _isSending = true);

    final authController = Provider.of<AuthController>(context, listen: false);
    final postController = Provider.of<PostController>(context, listen: false);
    final user = authController.currentUser!;

    final newComment = CommentModel(
      id: '',
      postId: widget.post.id,
      authorId: user.uid,
      authorName: user.name,
      authorProfileImage: user.profileImage,
      text: _commentController.text.trim(),
      createdAt: DateTime.now(),
    );

    await postController.addComment(newComment);
    _commentController.clear();
    _focusNode.unfocus();
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final postController = Provider.of<PostController>(context);
    final authController = Provider.of<AuthController>(context);
    final currentUser = authController.currentUser;
    final post = widget.post;
    final isLiked = currentUser != null && post.likes.contains(currentUser.uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppWidgets.appBar(locale.translate('post_details')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Post card ──────────────────────────────────────────
                  Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author row
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ProfilePage(userId: post.authorId))),
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppColors.primaryGradient),
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.cardLight,
                                    backgroundImage:
                                        post.authorProfileImage.isNotEmpty
                                            ? NetworkImage(
                                                post.authorProfileImage)
                                            : null,
                                    child: post.authorProfileImage.isEmpty
                                        ? const Icon(Icons.person,
                                            color: AppColors.textSecondary)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(post.authorName,
                                                style: const TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    fontSize: 15),
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ),
                                          if (post.isAuthorVerified) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.verified,
                                                color: AppColors.accent,
                                                size: 15),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(post.authorPosition,
                                            style: const TextStyle(
                                                color: AppColors.primaryLight,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500)),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _timeAgo(post.createdAt),
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Post text
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(post.text,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  height: 1.65)),
                        ),
                        // Images
                        if (post.images.isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(14, 14, 14, 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(post.images.first,
                                  fit: BoxFit.cover,
                                  width: double.infinity),
                            ),
                          ),
                        // Stats row
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(14, 14, 14, 0),
                          child: Row(
                            children: [
                              _StatChip(
                                  icon: Icons.favorite,
                                  count: post.likes.length,
                                  color: Colors.red),
                              const SizedBox(width: 12),
                              _StatChip(
                                  icon: Icons.chat_bubble_outline,
                                  count: post.commentCount,
                                  color: AppColors.textMuted),
                            ],
                          ),
                        ),
                        // Action bar
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Divider(height: 24),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          child: _ReactionButton(
                            icon: isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            label: isLiked ? locale.translate('liked_label') : locale.translate('like_label'),
                            color: isLiked ? Colors.red : AppColors.textSecondary,
                            onTap: currentUser == null
                                ? null
                                : () => postController.togglePostLike(
                                    post.id, currentUser.uid, !isLiked),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Comments section ───────────────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: AppWidgets.sectionTitle(
                        '${locale.translate('comments')} (${post.commentCount})'),
                  ),
                  StreamBuilder<List<CommentModel>>(
                    stream: postController.getPostComments(post.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: const [
                              UserTileShimmer(),
                              UserTileShimmer(),
                              UserTileShimmer(),
                            ],
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyComments(locale);
                      }
                      final comments = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: comments.length,
                        itemBuilder: (context, index) =>
                            _CommentCard(
                              comment: comments[index],
                              currentUserId: currentUser?.uid,
                              postId: post.id,
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Comment input bar ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.07))),
            ),
            padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 10,
                bottom: MediaQuery.of(context).padding.bottom + 10),
            child: Row(
              children: [
                // Current user avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.cardLight,
                  backgroundImage:
                      currentUser?.profileImage.isNotEmpty == true
                          ? NetworkImage(currentUser!.profileImage)
                          : null,
                  child: currentUser?.profileImage.isEmpty != false
                      ? const Icon(Icons.person,
                          size: 18, color: AppColors.textSecondary)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: locale.translate('add_comment_hint'),
                      hintStyle: const TextStyle(
                          color: AppColors.textMuted, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      fillColor: AppColors.cardLight,
                      filled: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedBuilder(
                  animation: _commentController,
                  builder: (context, _) {
                    final hasText =
                        _commentController.text.trim().isNotEmpty;
                    return GestureDetector(
                      onTap: hasText ? _addComment : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: hasText
                              ? AppColors.primaryGradient
                              : null,
                          color: hasText
                              ? null
                              : AppColors.cardLight,
                          shape: BoxShape.circle,
                        ),
                        child: _isSending
                            ? const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                ),
                              )
                            : Icon(Icons.send_rounded,
                                color: hasText
                                    ? Colors.white
                                    : AppColors.textMuted,
                                size: 18),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyComments(AppLocalization locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(locale.translate('no_comments'),
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
            const SizedBox(height: 6),
            Text(locale.translate('be_first_comment'),
                style:
                    const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final locale = AppLocalization.of(context)!;
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return locale.translate('days_ago').replaceFirst('{}', diff.inDays.toString());
    if (diff.inHours > 0) return locale.translate('hours_ago').replaceFirst('{}', diff.inHours.toString());
    if (diff.inMinutes > 0) return locale.translate('minutes_ago').replaceFirst('{}', diff.inMinutes.toString());
    return locale.translate('just_now');
  }
}

// ── Comment Card ─────────────────────────────────────────────────────────────

class _CommentCard extends StatelessWidget {
  final CommentModel comment;
  final String? currentUserId;
  final String postId;

  const _CommentCard({
    required this.comment,
    required this.currentUserId,
    required this.postId,
  });

  @override
  Widget build(BuildContext context) {
    final isOwn = currentUserId == comment.authorId;
    final locale = AppLocalization.of(context)!;

    return GestureDetector(
      onLongPress: isOwn
          ? () {
              HapticFeedback.mediumImpact();
              _showCommentOptions(context);
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      ProfilePage(userId: comment.authorId))),
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.cardLight,
                  backgroundImage: comment.authorProfileImage.isNotEmpty
                      ? NetworkImage(comment.authorProfileImage)
                      : null,
                  child: comment.authorProfileImage.isEmpty
                      ? const Icon(Icons.person,
                          size: 18, color: AppColors.textSecondary)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => ProfilePage(
                                      userId: comment.authorId))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.authorName,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                              Text(
                                _timeAgo(comment.createdAt, locale),
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isOwn)
                        GestureDetector(
                          onTap: () => _showCommentOptions(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.more_horiz,
                                color: AppColors.textMuted, size: 18),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    comment.text,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentOptions(BuildContext context) {
    final postController =
        Provider.of<PostController>(context, listen: false);
    final locale = AppLocalization.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 20),
              ),
              title: Text(locale.translate('delete_comment'),
                  style: const TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                await postController.deleteComment(postId, comment.id);
                if (context.mounted) {
                  AppWidgets.showSnackBar(context, locale.translate('comment_deleted'),
                      type: SnackBarType.success);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt, AppLocalization locale) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return locale.translate('days_ago').replaceFirst('{}', diff.inDays.toString());
    if (diff.inHours > 0) return locale.translate('hours_ago').replaceFirst('{}', diff.inHours.toString());
    if (diff.inMinutes > 0) return locale.translate('minutes_ago').replaceFirst('{}', diff.inMinutes.toString());
    return locale.translate('just_now');
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _StatChip(
      {required this.icon, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text('$count',
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ReactionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
