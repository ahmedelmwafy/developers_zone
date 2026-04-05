import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../services/firestore_service.dart';
import '../providers/app_provider.dart';
import '../widgets/page_entry_animation.dart';
import '../widgets/terminal_dialog.dart';

class ChatConfigPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatConfigPage(
      {required this.chatId, required this.otherUserId, super.key});

  @override
  State<ChatConfigPage> createState() => _ChatConfigPageState();
}

class _ChatConfigPageState extends State<ChatConfigPage> {
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
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final chatController = Provider.of<ChatController>(context);
    final isMuted =
        auth.currentUser?.mutedChats.contains(widget.chatId) ?? false;

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
          AppLocalization.of(context)!.translate('chat_config'),
          style: AppLocalization.digitalFont(context, 
              color: const Color(0xFF00E5FF),
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF00E5FF)),
            onPressed: () {},
          ),
        ],
      ),
      body: PageEntryAnimation(
        child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildProfileSection(),
            const SizedBox(height: 48),
            _buildOptionTile(
              icon: Icons.notifications_off_outlined,
              label:
                  AppLocalization.of(context)!.translate('mute_notifications'),
              trailing: Switch(
                value: isMuted,
                onChanged: (val) {
                  chatController.muteChat(auth.currentUser!.uid, widget.chatId,
                      mute: val);
                },
                activeThumbColor: const Color(0xFF00E5FF),
                activeTrackColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(
              icon: Icons.mark_chat_unread_outlined,
              label: AppLocalization.of(context)!.translate('mark_as_unread'),
              onTap: () {
                chatController.toggleUnread(widget.chatId, true);
                Navigator.pop(context);
              },
              trailing: Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.2)),
            ),
            const SizedBox(height: 16),
            _buildOptionTile(
              icon: Icons.delete_forever_outlined,
              label: AppLocalization.of(context)!.translate('purge_local_repo'),
              subLabel:
                  AppLocalization.of(context)!.translate('destructive_action'),
              onTap: () {
                _showDeleteConfirmation(chatController);
              },
              color: Colors.redAccent.withValues(alpha: 0.8),
              destructive: true,
            ),
            const SizedBox(height: 48),
            _buildHistorySection(chatController),
            const SizedBox(height: 48),
            _buildAssetSection(chatController),
            const SizedBox(height: 100),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildProfileSection() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.5), width: 3),
            image: _otherUser?.profileImage.isNotEmpty == true
                ? DecorationImage(
                    image: NetworkImage(_otherUser!.profileImage),
                    fit: BoxFit.cover)
                : null,
            color: Colors.white.withValues(alpha: 0.05),
          ),
          child: Stack(
            children: [
              if (_otherUser?.profileImage.isEmpty == true)
                const Center(
                    child: Icon(Icons.person, color: Colors.white10, size: 60)),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFF0D0D0D), width: 3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _otherUser?.name ??
              AppLocalization.of(context)!.translate('loading_dots'),
          style: AppLocalization.digitalFont(context, 
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          '${AppLocalization.of(context)!.translate('active_now')} • ${_otherUser?.position.toUpperCase() ?? AppLocalization.of(context)!.translate('kernel_contributor')}',
          style: AppLocalization.digitalFont(context, 
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    String? subLabel,
    Widget? trailing,
    VoidCallback? onTap,
    Color? color,
    bool destructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.white.withValues(alpha: 0.6), size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppLocalization.digitalFont(context, 
                          color: color ?? Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  if (subLabel != null)
                    Text(subLabel,
                        style: AppLocalization.digitalFont(context, 
                            color: color?.withValues(alpha: 0.5) ??
                                Colors.white.withValues(alpha: 0.2),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(ChatController chatController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalization.of(context)!.translate('COMMIT_HISTORY'),
          style: AppLocalization.digitalFont(context, 
              color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2),
        ),
        const SizedBox(height: 24),
        StreamBuilder<List<MessageModel>>(
          stream: chatController.getMessages(widget.chatId),
          builder: (context, snapshot) {
            final messages = snapshot.data?.take(2).toList() ?? [];
            return Column(
              children:
                  messages.map((msg) => _buildHistoryMessage(msg)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryMessage(MessageModel msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border:
            const Border(left: BorderSide(color: Color(0xFF00E5FF), width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
              image: _otherUser?.profileImage.isNotEmpty == true
                  ? DecorationImage(
                      image: NetworkImage(_otherUser!.profileImage),
                      fit: BoxFit.cover)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.text.isNotEmpty
                      ? msg.text
                      : '📷 ${AppLocalization.of(context)!.translate('image_payload')}',
                  style: AppLocalization.digitalFont(context, 
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                        AppLocalization.of(context)!
                            .translate('seen_at')
                            .replaceFirst('{}',
                                '${msg.createdAt.hour}:${msg.createdAt.minute}'),
                        style: AppLocalization.digitalFont(context, 
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 8,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                            color: Color(0xFF00E5FF), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(AppLocalization.of(context)!.translate('delivered'),
                        style: AppLocalization.digitalFont(context, 
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 8,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetSection(ChatController chatController) {
    return StreamBuilder<List<MessageModel>>(
      stream: chatController.getMessages(widget.chatId),
      builder: (context, snapshot) {
        final messages = snapshot.data ?? [];
        final imageMessages =
            messages.where((m) => m.image != null && m.image!.isNotEmpty).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalization.of(context)!.translate('shared_assets'),
                  style: AppLocalization.digitalFont(context, 
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2),
                ),
                Text(
                  AppLocalization.of(context)!
                      .translate('files_count')
                      .replaceFirst('{}', imageMessages.length.toString()),
                  style: AppLocalization.digitalFont(context, 
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (imageMessages.isEmpty)
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                ),
                child: Center(
                  child: Text(
                    AppLocalization.of(context)!.translate('no_assets_found'),
                    style: AppLocalization.digitalFont(context, 
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: imageMessages.length,
                  itemBuilder: (context, index) {
                    final msg = imageMessages[index];
                    return GestureDetector(
                      onTap: () {
                        // Potential full screen image view
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          image: DecorationImage(
                              image: NetworkImage(msg.image!),
                              fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(ChatController chatController) {
    final locale = AppLocalization.of(context)!;
    showDialog(
      context: context,
      builder: (_) => TerminalDialog(
        headerTag: 'DATABASE_MANAGER',
        title: locale.translate('purge_repo_confirm_title'),
        body: locale.translate('purge_repo_confirm_content'),
        confirmLabel: locale.translate('purge'),
        cancelLabel: locale.translate('cancel'),
        isDestructive: true,
        onConfirm: () {
          chatController.deleteChat(widget.chatId);
          Navigator.pop(context); // Close dialog
          Navigator.pop(context); // Exit config
          Navigator.pop(context); // Exit chat
        },
      ),
    );
  }
}
