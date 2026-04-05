import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/post_controller.dart';
import '../../providers/app_provider.dart';
import '../post_details_page.dart';
import '../profile_page.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/post_media_widget.dart';
import '../../widgets/terminal_dialog.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';

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
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.04), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
                _buildDynamicContent(parts, context),
                if (parts['code'] != null) ...[
                  const SizedBox(height: 16),
                  _buildCodeManifest(context, parts['code']!),
                ],
                if (post.images.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  PostMediaWidget(images: post.images, postId: post.id),
                ],
                const SizedBox(height: 24),
                _buildActionRow(post, isLiked, currentUser, authController,
                    postController, locale, context),
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

  Widget _buildDynamicContent(
      Map<String, String?> parts, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parts['title'] != null) ...[
          Text(
            parts['title']!,
            style: AppLocalization.digitalFont(
              context,
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (parts['body'] != null && parts['body']!.isNotEmpty) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: MarkdownBody(
              data: parts['body']!,
              onTapLink: (text, href, title) {
                if (href != null) {
                  launchUrl(Uri.parse(href),
                      mode: LaunchMode.externalApplication);
                }
              },
              styleSheet: MarkdownStyleSheet(
                p: AppLocalization.digitalFont(
                  context,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.6,
                ),
                strong: const TextStyle(
                    color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
                a: const TextStyle(
                    color: Color(0xFF00E5FF),
                    decoration: TextDecoration.underline),
                listBullet:
                    TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              ),
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
              border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF0D0D0D),
              backgroundImage: post.authorProfileImage.isNotEmpty
                  ? NetworkImage(post.authorProfileImage)
                  : null,
              child: post.authorProfileImage.isEmpty
                  ? Text(post.authorInitials,
                      style: AppLocalization.digitalFont(context,
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800))
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
                style: AppLocalization.digitalFont(
                  context,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'COMMITTED ${_timeAgo(post.createdAt, locale).toUpperCase()} • ${post.authorPosition.toUpperCase()}',
                style: AppLocalization.digitalFont(
                  context,
                  color: Colors.white.withValues(alpha: 0.35),
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
          color: Colors.white.withValues(alpha: 0.4), size: 20),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) async {
        if (currentUser == null) return;

        if (val == 'delete' && isMe) {
          showDialog(
            context: context,
            builder: (context) => TerminalDialog(
              headerTag: locale.translate('LOG_DELETE'),
              title: locale.translate('PURGE_MANIFEST'),
              body: locale.translate('PURGE_MANIFEST_CONFIRM'),
              confirmLabel: locale.translate('CONFIRM_ACTION'),
              cancelLabel: locale.translate('CANCEL_ACTION'),
              isDestructive: true,
              onConfirm: () async {
                Navigator.pop(context);
                await postController.deletePost(post.id);
              },
            ),
          );
        } else if (val == 'repost') {
          showDialog(
            context: context,
            builder: (context) => TerminalDialog(
              headerTag: locale.translate('REPOST_SEQUENCE'),
              title: locale.translate('REPOST'),
              body: locale.translate('REPOST_CONFIRM'),
              confirmLabel: locale.translate('CONFIRM_ACTION'),
              cancelLabel: locale.translate('CANCEL_ACTION'),
              onConfirm: () async {
                Navigator.pop(context);
                await postController.repostPost(
                    post,
                    currentUser.uid,
                    currentUser.name,
                    currentUser.profileImage,
                    currentUser.position);
                if (context.mounted) {
                  AppWidgets.showSnackBar(
                      context, locale.translate('repost_success'),
                      type: SnackBarType.success);
                }
              },
            ),
          );
        } else if (val == 'block' && !isMe) {
          showDialog(
            context: context,
            builder: (context) => TerminalDialog(
              headerTag: locale.translate('BLOCK_NODE'),
              title: locale.translate('TERMINATE_NODE'),
              body: locale.translate('BLOCK_USER_CONFIRM'),
              confirmLabel: locale.translate('CONFIRM_ACTION'),
              cancelLabel: locale.translate('CANCEL_ACTION'),
              isDestructive: true,
              onConfirm: () async {
                Navigator.pop(context);
                await authController.blockUser(post.authorId);
                if (context.mounted) {
                  AppWidgets.showSnackBar(
                      context, locale.translate('block_success'),
                      type: SnackBarType.error);
                }
              },
            ),
          );
        } else if (val == 'report' && !isMe) {
          AppWidgets.showSnackBar(context, locale.translate('report_success'),
              type: SnackBarType.warning);
        } else if (val == 'delete' && isMe) {
          showDialog(
            context: context,
            builder: (context) => TerminalDialog(
              headerTag: locale.translate('PURGE_NODE'),
              title: locale.translate('PURGE_NODE'),
              body: locale.translate('delete_post_confirm'),
              confirmLabel: locale.translate('CONFIRM_ACTION'),
              cancelLabel: locale.translate('CANCEL_ACTION'),
              isDestructive: true,
              onConfirm: () async {
                Navigator.pop(context);
                await postController.deletePost(post.id);
                if (context.mounted) {
                  AppWidgets.showSnackBar(
                      context, locale.translate('post_purged'),
                      type: SnackBarType.error);
                }
              },
            ),
          );
        }
      },
      itemBuilder: (_) => [
        if (isMe)
          _buildMenuItem(context, 'delete', Icons.delete_outline_rounded,
              locale.translate('PURGE_NODE'), Colors.redAccent)
        else ...[
          _buildMenuItem(context, 'repost', Icons.repeat_rounded,
              locale.translate('REPOST'), const Color(0xFF00E5FF)),
          _buildMenuItem(context, 'block', Icons.block_rounded,
              locale.translate('TERMINATE_NODE'), Colors.redAccent),
          _buildMenuItem(context, 'report', Icons.emergency_share_outlined,
              locale.translate('REPORT_ANOMALY'), Colors.orangeAccent),
        ]
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(BuildContext context, String value,
      IconData icon, String text, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(text,
              style: AppLocalization.digitalFont(context,
                  color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCodeManifest(BuildContext context, String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFF5F56), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFF27C93F), shape: BoxShape.circle)),
              const Spacer(),
              Text('CODE_MANIFEST',
                  style: AppLocalization.digitalFont(context,
                      color: Colors.white.withValues(alpha: 0.1),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          SelectableText(
            code,
            maxLines: 6,
            style: GoogleFonts.sourceCodePro(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
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
      AuthController authController,
      PostController postController,
      AppLocalization locale,
      BuildContext context) {
    final isSaved =
        currentUser != null && currentUser.savedPosts.contains(post.id);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildInteractionIcon(
          context,
          isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          '${post.likes.length}',
          isLiked ? Colors.redAccent : Colors.white.withValues(alpha: 0.4),
          () {
            if (currentUser != null) {
              postController.togglePostLike(post.id, currentUser.uid, !isLiked);
              if (!isLiked) {
                AppWidgets.showSnackBar(
                    context, locale.translate('action_synced'),
                    type: SnackBarType.success);
              }
            } else {
              _showGuestLoginPrompt(context, locale);
            }
          },
        ),
        const SizedBox(width: 24),
        _buildInteractionIcon(
          context,
          Icons.chat_bubble_outline_rounded,
          '${post.commentCount}',
          Colors.white.withValues(alpha: 0.4),
          () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PostDetailsPage(post: post))),
        ),
        if (currentUser?.uid != post.authorId) ...[
          const SizedBox(width: 24),
          _buildInteractionIcon(
            context,
            Icons.repeat_rounded,
            '',
            const Color(0xFF00E5FF).withValues(alpha: 0.6),
            () {
              if (currentUser == null) {
                _showGuestLoginPrompt(context, locale);
                return;
              }
              showDialog(
                context: context,
                builder: (context) => TerminalDialog(
                  headerTag: 'REPOST_SEQUENCE',
                  title: locale.translate('REPOST'),
                  body: locale.translate('REPOST_CONFIRM'),
                  confirmLabel: locale.translate('CONFIRM_ACTION'),
                  cancelLabel: locale.translate('CANCEL_ACTION'),
                  onConfirm: () async {
                    Navigator.pop(context);
                    await postController.repostPost(
                      post,
                      currentUser.uid,
                      currentUser.name,
                      currentUser.profileImage,
                      currentUser.position,
                    );
                    if (context.mounted) {
                      AppWidgets.showSnackBar(
                          context, locale.translate('repost_success'),
                          type: SnackBarType.success);
                    }
                  },
                ),
              );
            },
          ),
        ],
        const Spacer(),
        _buildInteractionIcon(
          context,
          isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          '',
          isSaved
              ? const Color(0xFF00E5FF)
              : Colors.white.withValues(alpha: 0.4),
          () async {
            if (currentUser != null) {
              await postController.toggleSavedPost(
                  currentUser.uid, post.id, !isSaved);
              await authController.refreshUser();
              if (context.mounted) {
                AppWidgets.showSnackBar(
                    context, locale.translate('action_synced'),
                    type: SnackBarType.success);
              }
            } else {
              _showGuestLoginPrompt(context, locale);
            }
          },
        ),
      ],
    );
  }

  Widget _buildInteractionIcon(BuildContext context, IconData icon,
      String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(icon, key: ValueKey(icon), color: color, size: 20),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                label,
                key: ValueKey(label),
                style: AppLocalization.digitalFont(
                  context,
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showGuestLoginPrompt(BuildContext context, AppLocalization locale) {
    showDialog(
      context: context,
      builder: (context) => TerminalDialog(
        headerTag: 'AUTH_REQUIRED',
        title: locale.translate('LOGIN_REQUIRED_TITLE'),
        body: locale.translate('LOGIN_REQUIRED_BODY'),
        confirmLabel: locale.translate('EXECUTE_LOGIN'),
        cancelLabel: locale.translate('CANCEL_ACTION'),
        onConfirm: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
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
