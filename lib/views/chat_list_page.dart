import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'chat_detail_screen.dart';
import 'profile_page.dart';
import 'components/shimmer_loading.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final currentUser = Provider.of<AuthController>(context).currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            locale.translate('login_to_chat'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final chatController = Provider.of<ChatController>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: ShaderMask(
          shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
          child: Text(
            locale.translate('messages'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
              Container(color: Colors.white.withValues(alpha: 0.06), height: 1),
        ),
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: chatController.getUserChats(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              itemCount: 6,
              itemBuilder: (context, index) => const UserTileShimmer(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_outlined,
                        size: 56, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      locale.translate('chat_load_error'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.accent.withValues(alpha: 0.08),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 42, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    locale.translate('no_chats_yet'),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locale.translate('no_chats_sub'),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: chats.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 80, color: Colors.white10),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = chat.users.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => chat.users.first,
              );
              final isUnread =
                  !chat.isSeen && chat.lastSenderId != currentUser.uid;

              return _ChatTile(
                chat: chat,
                otherUserId: otherUserId,
                currentUser: currentUser,
                isUnread: isUnread,
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatefulWidget {
  final ChatModel chat;
  final String otherUserId;
  final UserModel currentUser;
  final bool isUnread;

  const _ChatTile({
    required this.chat,
    required this.otherUserId,
    required this.currentUser,
    required this.isUnread,
  });

  @override
  State<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<_ChatTile> {
  late bool _isMuted;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.currentUser.mutedChats.contains(widget.chat.id);
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;

    return FutureBuilder<UserModel?>(
      future: FirestoreService().getUser(widget.otherUserId),
      builder: (context, userSnap) {
        final user = userSnap.data;
        final isLoading = userSnap.connectionState == ConnectionState.waiting;

        return Dismissible(
          key: ValueKey(widget.chat.id),
          direction: DismissDirection.endToStart,
          background: _buildSwipeBackground(),
          confirmDismiss: (_) => _confirmDelete(context, locale),
          onDismissed: (_) => _deleteChat(context, locale),
          child: InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                    chatId: widget.chat.id, otherUserId: widget.otherUserId))),
            onLongPress: () {
              HapticFeedback.mediumImpact();
              _showChatOptions(context, user, locale);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            ProfilePage(userId: widget.otherUserId))),
                    child: isLoading
                        ? const ShimmerLoading.circular(width: 54, height: 54)
                        : Stack(
                            children: [
                              Container(
                                padding:
                                    widget.isUnread ? const EdgeInsets.all(2) : null,
                                decoration: widget.isUnread
                                    ? BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: AppColors.primaryGradient)
                                    : null,
                                child: CircleAvatar(
                                  radius: 27,
                                  backgroundColor: AppColors.cardLight,
                                  backgroundImage:
                                      user?.profileImage.isNotEmpty == true
                                          ? NetworkImage(user!.profileImage)
                                          : null,
                                  child: user?.profileImage.isNotEmpty != true
                                      ? const Icon(Icons.person,
                                          color: AppColors.textSecondary,
                                          size: 28)
                                      : null,
                                ),
                              ),
                              if (_isMuted)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.background,
                                          width: 1.5),
                                    ),
                                    child: const Icon(
                                        Icons.notifications_off_rounded,
                                        size: 10,
                                        color: AppColors.textMuted),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isLoading
                            ? const ShimmerLoading.rectangular(
                                height: 14, width: 120)
                            : Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user?.name ?? widget.otherUserId,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: widget.isUnread
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (user?.isVerified == true) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified,
                                        color: AppColors.accent, size: 14),
                                  ],
                                  if (_isMuted) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.notifications_off_outlined,
                                        size: 13, color: AppColors.textMuted),
                                  ],
                                ],
                              ),
                        const SizedBox(height: 4),
                        Text(
                          widget.chat.lastMessage.isNotEmpty
                              ? widget.chat.lastMessage
                              : '...',
                          style: TextStyle(
                            color: widget.isUnread
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: widget.isUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(widget.chat.lastMessageTime),
                        style: TextStyle(
                          color: widget.isUnread
                              ? AppColors.primary
                              : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: widget.isUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (widget.isUnread) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwipeBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: AppColors.error.withValues(alpha: 0.15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 22),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext ctx, AppLocalization locale) {
    return showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(locale.translate('delete_chat'),
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          locale.translate('delete_chat_confirm'),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(locale.translate('cancel'),
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(locale.translate('delete'),
                style: const TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _deleteChat(BuildContext ctx, AppLocalization locale) {
    final controller = Provider.of<ChatController>(ctx, listen: false);
    controller.deleteChat(widget.chat.id);
    AppWidgets.showSnackBar(ctx, locale.translate('conversation_deleted'),
        type: SnackBarType.success);
  }

  void _showChatOptions(
      BuildContext ctx, UserModel? user, AppLocalization locale) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ChatOptionsSheet(
        chat: widget.chat,
        user: user,
        currentUserId: widget.currentUser.uid,
        isMuted: _isMuted,
        onMuteToggled: (val) => setState(() => _isMuted = val),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays >= 1) return '${dt.day}/${dt.month}';
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ChatOptionsSheet extends StatelessWidget {
  final ChatModel chat;
  final UserModel? user;
  final String currentUserId;
  final bool isMuted;
  final ValueChanged<bool> onMuteToggled;

  const _ChatOptionsSheet({
    required this.chat,
    required this.user,
    required this.currentUserId,
    required this.isMuted,
    required this.onMuteToggled,
  });

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final otherUserId = chat.users.firstWhere(
      (id) => id != currentUserId,
      orElse: () => chat.users.first,
    );
    final chatController = Provider.of<ChatController>(context, listen: false);

    // Save messenger reference to avoid context deactivated error
    final messenger = ScaffoldMessenger.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
          const SizedBox(height: 16),
          if (user != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.cardLight,
                  backgroundImage: user!.profileImage.isNotEmpty
                      ? NetworkImage(user!.profileImage)
                      : null,
                  child: user!.profileImage.isEmpty
                      ? const Icon(Icons.person, color: AppColors.textSecondary)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user!.name,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    if (user!.position.isNotEmpty)
                      Text(user!.position,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const Divider(height: 28, color: Colors.white10),
          ],
          _OptionItem(
            icon: Icons.person_outline_rounded,
            color: AppColors.primary,
            label: locale.translate('view_profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProfilePage(userId: otherUserId)));
            },
          ),
          _OptionItem(
            icon: isMuted
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            color: AppColors.warning,
            label: locale.translate(
                isMuted ? 'unmute_notifications' : 'mute_notifications'),
            onTap: () async {
              Navigator.pop(context);
              await chatController.muteChat(currentUserId, chat.id,
                  mute: !isMuted);
              onMuteToggled(!isMuted);
              AppWidgets.showSnackBar(
                null, // Pass null or use messenger directly
                locale.translate(isMuted ? 'chat_unmuted' : 'chat_muted'),
                type: SnackBarType.info,
                messenger: messenger,
              );
            },
          ),
          _OptionItem(
            icon: Icons.mark_chat_unread_outlined,
            color: AppColors.accent,
            label: locale.translate('mark_as_unread'),
            onTap: () async {
              Navigator.pop(context);
              await chatController.toggleUnread(chat.id, true);
              AppWidgets.showSnackBar(null, locale.translate('marked_unread'),
                  type: SnackBarType.info, messenger: messenger);
            },
          ),
          _OptionItem(
            icon: Icons.archive_outlined,
            color: AppColors.textSecondary,
            label: locale.translate('archive_chat'),
            onTap: () async {
              Navigator.pop(context);
              await chatController.hideChat(currentUserId, chat.id);
              AppWidgets.showSnackBar(null, locale.translate('chat_archived'),
                  type: SnackBarType.success, messenger: messenger);
            },
          ),
          const Divider(height: 20, color: Colors.white10),
          _OptionItem(
            icon: Icons.delete_outline_rounded,
            color: AppColors.error,
            label: locale.translate('delete_chat'),
            isDestructive: true,
            onTap: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.card,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  title: Text(locale.translate('delete_chat'),
                      style: const TextStyle(color: AppColors.textPrimary)),
                  content: Text(
                    locale.translate('delete_chat_confirm'),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(locale.translate('cancel'),
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
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
              if (confirm == true) {
                chatController.deleteChat(chat.id);
                AppWidgets.showSnackBar(
                    null, locale.translate('conversation_deleted'),
                    type: SnackBarType.success, messenger: messenger);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _OptionItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _OptionItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isDestructive ? AppColors.error : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
