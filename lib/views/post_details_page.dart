import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../controllers/post_controller.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import '../models/user_model.dart';
import 'profile_page.dart';
import '../providers/app_provider.dart';
import '../widgets/post_media_widget.dart';

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
  CommentModel? _replyingTo; // Added state for replies

  void setReply(CommentModel comment) {
    setState(() => _replyingTo = comment);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postController = Provider.of<PostController>(context);
    final authController = Provider.of<AuthController>(context);
    final locale = AppLocalization.of(context)!;
    final currentUser = authController.currentUser;
    final post = widget.post;
    final isLiked = currentUser != null && post.likes.contains(currentUser.uid);

    // Dynamic Manifest Parsing
    final parts = _parseManifest(post.text);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          '${locale.translate('MANIFEST_ENTRY')} // ${post.id.substring(0, 8).toUpperCase()}',
          style: AppLocalization.digitalFont(context, 
            color: const Color(0xFF00E5FF).withOpacity(0.4),
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        actions: [
          if (currentUser != null)
            IconButton(
              icon: Icon(
                currentUser.savedPosts.contains(post.id)
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: const Color(0xFF00E5FF),
                size: 20,
              ),
              onPressed: () {
                final isSaving = !currentUser.savedPosts.contains(post.id);
                postController.toggleSavedPost(currentUser.uid, post.id, isSaving);
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(parts),
                  const SizedBox(height: 32),
                  _buildAuthorCard(post),
                  const SizedBox(height: 48),
                  const SizedBox(height: 48),
                  _buildDetailedContent(post, parts),
                  const SizedBox(height: 48),
                  _buildActionBar(post, isLiked, currentUser, postController, authController),
                  const SizedBox(height: 48),
                  _buildCommentSection(post, postController),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Map<String, String?> _parseManifest(String text) {
    String? title;
    String? body = text;
    String? code;

    if (text.startsWith('# ')) {
      final lines = text.split('\n');
      title = lines.first.replaceFirst('# ', '').trim();
      body = lines.skip(1).join('\n').trim();
    }

    final codeMatch = RegExp(r'```(?:\w+)?\n([\s\S]*?)```').firstMatch(body);
    if (codeMatch != null) {
      code = codeMatch.group(1)?.trim();
      body = body.replaceFirst(codeMatch.group(0)!, '').trim();
    }

    return {'title': title, 'body': body, 'code': code};
  }

  Widget _buildHeader(Map<String, String?> parts) {
    final locale = AppLocalization.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale.translate('NODAL_MANIFEST_DECAP'),
          style: AppLocalization.digitalFont(context, color: Colors.white.withOpacity(0.15), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2),
        ),
        const SizedBox(height: 12),
        Text(
          parts['title'] ?? locale.translate('TRANSCRIPT_NODE'),
          style: AppLocalization.digitalFont(context, color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.25),
        ),
      ],
    );
  }

  Widget _buildAuthorCard(PostModel post) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF0D0D0D),
              backgroundImage: post.authorProfileImage.isNotEmpty ? NetworkImage(post.authorProfileImage) : null,
              child: post.authorProfileImage.isEmpty ? const Icon(Icons.person, size: 22, color: Colors.white24) : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.authorName, style: AppLocalization.digitalFont(context, color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                Text(post.authorPosition.toUpperCase(), style: AppLocalization.digitalFont(context, color: Colors.white.withOpacity(0.2), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfilePage(userId: post.authorId))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.15)),
              ),
              child: Text(AppLocalization.of(context)!.translate('VIEW_NODE'), style: AppLocalization.digitalFont(context, color: const Color(0xFF00E5FF).withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedContent(PostModel post, Map<String, String?> parts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.images.isNotEmpty) ...[
          const SizedBox(height: 16),
          PostMediaWidget(images: post.images, height: 350, borderRadius: 20),
          const SizedBox(height: 32),
        ],
        if (parts['body'] != null && parts['body']!.isNotEmpty)
          MarkdownBody(
            data: parts['body']!,
            onTapLink: (text, href, title) {
              if (href != null) launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
            },
            styleSheet: MarkdownStyleSheet(
              p: AppLocalization.digitalFont(context, color: Colors.white.withOpacity(0.7), fontSize: 17, height: 1.8),
              strong: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold),
              a: const TextStyle(color: Color(0xFF00E5FF), decoration: TextDecoration.underline),
              listBullet: TextStyle(color: Colors.white.withOpacity(0.3)),
            ),
          ),
        if (parts['code'] != null) ...[
          const SizedBox(height: 32),
          _buildCodeManifest(parts['code']!),
        ],
      ],
    );
  }

  Widget _buildCodeManifest(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, spreadRadius: -10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
              const Spacer(),
              Text(AppLocalization.of(context)!.translate('MAIN_TRANSCRIPT'), style: AppLocalization.digitalFont(context, color: Colors.white.withOpacity(0.15), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 24),
          SelectableText(
            code,
            style: GoogleFonts.sourceCodePro(
              color: const Color(0xFF00E5FF).withOpacity(0.8),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(PostModel post, bool isLiked, UserModel? currentUser, PostController postController, AuthController authController) {
    return Row(
      children: [
        _InteractionNode(
          icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          count: post.likes.length.toString(),
          color: isLiked ? Colors.redAccent : Colors.white.withOpacity(0.2),
          onTap: () {
            if (currentUser != null) {
              postController.togglePostLike(post.id, currentUser.uid, !isLiked);
            }
          },
        ),
        const SizedBox(width: 24),
        _InteractionNode(
          icon: Icons.chat_bubble_outline_rounded,
          count: post.commentCount.toString(),
          color: Colors.white.withOpacity(0.2),
          onTap: () {
            _focusNode.requestFocus();
          },
        ),
        const Spacer(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: IconButton(
            key: ValueKey(currentUser?.savedPosts.contains(post.id)),
            icon: Icon(
              currentUser?.savedPosts.contains(post.id) ?? false
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              color: currentUser?.savedPosts.contains(post.id) ?? false
                  ? const Color(0xFF00E5FF)
                  : Colors.white.withOpacity(0.2),
              size: 24,
            ),
            onPressed: currentUser == null
                ? null
                : () async {
                    final isSaving = !currentUser.savedPosts.contains(post.id);
                    await postController.toggleSavedPost(currentUser.uid, post.id, isSaving);
                    await authController.refreshUser();
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection(PostModel post, PostController postController) {
    final locale = AppLocalization.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale.translate('TRANSMISSION_THREAD'),
          style: AppLocalization.digitalFont(context, color: Colors.white.withOpacity(0.15), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2),
        ),
        const SizedBox(height: 24),
        StreamBuilder<List<CommentModel>>(
          stream: postController.getPostComments(post.id),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
            final comments = snapshot.data!;
            if (comments.isEmpty) return _buildEmptyState();
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) => _CommentNode(comment: comments[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final locale = AppLocalization.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(locale.translate('WAITING_FOR_UPLINK'), style: AppLocalization.digitalFont(context, color: Colors.white.withOpacity(0.05), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildCommentInput() {
    final locale = AppLocalization.of(context)!;
    final user = Provider.of<AuthController>(context, listen: false).currentUser;

    if (user != null && !user.canComment) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.03))),
        ),
        child: Center(
          child: Text(
            locale.translate('commenting_restricted'),
            style: AppLocalization.digitalFont(context, color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.05),
              border: Border(top: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.1))),
            ),
            child: Row(
              children: [
                const Icon(Icons.reply_rounded, color: Color(0xFF00E5FF), size: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${locale.translate('REPLYING_TO')} @${_replyingTo!.authorName}',
                    style: AppLocalization.digitalFont(context, color: const Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _replyingTo = null),
                  child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.3), size: 14),
                ),
              ],
            ),
          ),
        Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.03))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    cursorColor: const Color(0xFF00E5FF),
                    style: AppLocalization.digitalFont(context, color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: locale.translate('ADD_TO_MANIFEST'),
                      hintStyle: AppLocalization.digitalFont(context, color: Colors.white.withOpacity(0.1), fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () async {
                  if (_commentController.text.trim().isEmpty) return;
                  if (user == null) return;
                  
                  setState(() => _isSending = true);
                  final comment = CommentModel(
                    id: '',
                    postId: widget.post.id,
                    authorId: user.uid,
                    authorName: user.name,
                    authorProfileImage: user.profileImage,
                    text: _commentController.text.trim(),
                    parentCommentId: _replyingTo?.id,
                    replyToName: _replyingTo?.authorName,
                    createdAt: DateTime.now(),
                  );
                  await Provider.of<PostController>(context, listen: false).addComment(comment);
                  _commentController.clear();
                  _focusNode.unfocus();
                  setState(() {
                    _isSending = false;
                    _replyingTo = null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.2), blurRadius: 10, spreadRadius: 1),
                    ],
                  ),
                  child: Center(
                    child: _isSending 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InteractionNode extends StatelessWidget {
  final IconData icon;
  final String count;
  final Color color;
  final VoidCallback? onTap;
  const _InteractionNode({required this.icon, required this.count, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(icon, key: ValueKey(icon), color: color, size: 22),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              count,
              key: ValueKey(count),
              style: AppLocalization.digitalFont(context, color: color, fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentNode extends StatelessWidget {
  final CommentModel comment;
  const _CommentNode({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              image: comment.authorProfileImage.isNotEmpty ? DecorationImage(image: NetworkImage(comment.authorProfileImage), fit: BoxFit.cover) : null,
            ),
            child: comment.authorProfileImage.isEmpty ? const Icon(Icons.person, color: Colors.white10, size: 20) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(comment.authorName, style: AppLocalization.digitalFont(context, color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                    Text(AppLocalization.of(context)!.translate('NODE_RX'), style: AppLocalization.digitalFont(context, color: Colors.white.withOpacity(0.05), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ],
                ),
                const SizedBox(height: 4),
                if (comment.replyToName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '@${comment.replyToName}',
                      style: AppLocalization.digitalFont(context, color: const Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                Text(comment.text, style: AppLocalization.digitalFont(context, color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.6)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(timeago.format(comment.createdAt), style: AppLocalization.digitalFont(context, color: Colors.white.withOpacity(0.2), fontSize: 9, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        // Finding the ancestor state to trigger reply
                        final state = context.findAncestorStateOfType<_PostDetailsPageState>();
                        if (state != null) {
                          state.setReply(comment);
                        }
                      },
                      child: Text(AppLocalization.of(context)!.translate('REPLY_ACTION'), style: AppLocalization.digitalFont(context, color: const Color(0xFF00E5FF).withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
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
