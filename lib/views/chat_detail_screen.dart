import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_model.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'profile_page.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatDetailScreen({required this.chatId, required this.otherUserId, super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  UserModel? _otherUser;

  @override
  void initState() {
    super.initState();
    _loadOtherUser();
  }

  Future<void> _loadOtherUser() async {
    final user = await FirestoreService().getUser(widget.otherUserId);
    if (mounted) setState(() => _otherUser = user);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final chatController = Provider.of<ChatController>(context, listen: false);

    if (_messageController.text.trim().isEmpty) return;

    final message = MessageModel(
      id: '',
      senderId: authController.currentUser!.uid,
      receiverId: widget.otherUserId,
      text: _messageController.text.trim(),
      createdAt: DateTime.now(),
      isSeen: false,
    );

    _messageController.clear();
    await chatController.sendMessage(widget.chatId, message, authController.currentUser!.name);
  }

  void _toggleLike(MessageModel message, String myUid) {
    final chatController = Provider.of<ChatController>(context, listen: false);
    final isLiked = message.isLikedBy(myUid);
    chatController.toggleMessageLike(widget.chatId, message.id, myUid, !isLiked);
  }

  @override
  Widget build(BuildContext context) {
    final chatController = Provider.of<ChatController>(context);
    final currentUserId = Provider.of<AuthController>(context).currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatController.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data![index];
                    final isMe = message.senderId == currentUserId;
                    final showDate = index == snapshot.data!.length - 1 ||
                        snapshot.data![index + 1].createdAt.day != message.createdAt.day;
                    return _buildMessageItem(message, isMe, showDate, currentUserId);
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final locale = AppLocalization.of(context)!;
    return AppBar(
      backgroundColor: AppColors.background,
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProfilePage(userId: widget.otherUserId)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.cardLight,
                backgroundImage: _otherUser?.profileImage.isNotEmpty == true
                    ? NetworkImage(_otherUser!.profileImage)
                    : null,
                child: _otherUser?.profileImage.isEmpty != false
                    ? const Icon(Icons.person, size: 18, color: AppColors.textSecondary)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otherUser?.name ?? '...',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  _otherUser?.position.isNotEmpty == true ? _otherUser!.position : 'Developer',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline_rounded, size: 22),
          tooltip: locale.translate('view_profile_tooltip'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProfilePage(userId: widget.otherUserId)),
          ),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.white.withValues(alpha: 0.06), height: 1),
      ),
    );
  }

  Widget _buildMessageItem(MessageModel message, bool isMe, bool showDate, String myUid) {
    final isLiked = message.isLikedBy(myUid);
    final hasLikes = message.likedBy.isNotEmpty;
    final locale = AppLocalization.of(context)!;

    return Column(
      children: [
        if (showDate) _buildDateDivider(message.createdAt, locale),
        GestureDetector(
          onDoubleTap: () => _toggleLike(message, myUid),
          onLongPress: () => _showMessageOptions(message, isMe, myUid),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) ...[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.cardLight,
                    backgroundImage: _otherUser?.profileImage.isNotEmpty == true
                        ? NetworkImage(_otherUser!.profileImage)
                        : null,
                    child: _otherUser?.profileImage.isEmpty != false
                        ? const Icon(Icons.person, size: 14, color: AppColors.textSecondary)
                        : null,
                  ),
                  const SizedBox(width: 8),
                ],
                Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isMe ? AppColors.primaryGradient : null,
                          color: isMe ? null : AppColors.card,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 18),
                          ),
                          border: isMe ? null : Border.all(color: Colors.white.withValues(alpha: 0.07)),
                          boxShadow: isMe
                              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (message.text.isNotEmpty)
                              Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(message.createdAt),
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    message.isSeen ? Icons.done_all : Icons.done,
                                    size: 12,
                                    color: message.isSeen ? AppColors.accent : Colors.white.withValues(alpha: 0.6),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Like reaction badge
                    if (hasLikes)
                      Transform.translate(
                        offset: Offset(isMe ? -4 : 4, -4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.background, width: 1.5),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(isLiked ? '❤️' : '🤍', style: const TextStyle(fontSize: 11)),
                              if (message.likedBy.length > 1) ...[
                                const SizedBox(width: 3),
                                Text('${message.likedBy.length}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMessageOptions(MessageModel message, bool isMe, String myUid) {
    final isLiked = message.isLikedBy(myUid);
    final locale = AppLocalization.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            _ActionTile(
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              iconColor: AppColors.error,
              label: isLiked ? locale.translate('unlike_label') : locale.translate('like'),
              onTap: () {
                Navigator.pop(context);
                _toggleLike(message, myUid);
              },
            ),
            if (isMe)
              _ActionTile(
                icon: Icons.delete_outline,
                iconColor: AppColors.error,
                label: locale.translate('delete_message'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.card,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      title: Text(locale.translate('delete_message_title'),
                          style: const TextStyle(color: AppColors.textPrimary)),
                      content: Text(
                        locale.translate('delete_message_confirm'),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
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
                    final chatController =
                        Provider.of<ChatController>(context, listen: false);
                    await chatController.deleteMessage(widget.chatId, message.id);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDivider(DateTime dt, AppLocalization locale) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(12)),
          child: Text(_formatDate(dt, locale), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final locale = AppLocalization.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.waving_hand_outlined, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(locale.translate('say_hello'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(locale.translate('start_conversation'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final locale = AppLocalization.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      padding: EdgeInsets.only(left: 12, right: 12, top: 10, bottom: MediaQuery.of(context).padding.bottom + 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image_outlined, color: AppColors.primary, size: 22),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: locale.translate('type_message'),
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  String _formatDate(DateTime dt, AppLocalization locale) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month) return locale.translate('today');
    if (dt.day == now.day - 1 && dt.month == now.month) return locale.translate('yesterday');
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.iconColor, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
    );
  }
}
