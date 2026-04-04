import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_model.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../services/imgbb_service.dart';
import 'chat_config_page.dart';
import '../providers/app_provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatDetailScreen(
      {required this.chatId, required this.otherUserId, super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  UserModel? _otherUser;
  bool _isUploading = false;
  String? _editingMessageId;

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

    if (_editingMessageId != null) {
      _editingMessageId = null;
    }

    final message = MessageModel(
      id: '',
      senderId: authController.currentUser!.uid,
      receiverId: widget.otherUserId,
      text: _messageController.text.trim(),
      createdAt: DateTime.now(),
      isSeen: false,
    );

    _messageController.clear();
    await chatController.sendMessage(
        widget.chatId, message, authController.currentUser!.name);
  }

  void _pickAndSendImage() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    final authController = Provider.of<AuthController>(context, listen: false);
    final chatController = Provider.of<ChatController>(context, listen: false);

    try {
      final url = await ImgBBService.uploadImage(File(pickedFile.path));
      if (url != null) {
        final message = MessageModel(
          id: '',
          senderId: authController.currentUser!.uid,
          receiverId: widget.otherUserId,
          text: '',
          image: url,
          createdAt: DateTime.now(),
          isSeen: false,
        );
        await chatController.sendMessage(
            widget.chatId, message, authController.currentUser!.name);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatController = Provider.of<ChatController>(context);
    final currentUser = Provider.of<AuthController>(context).currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: _buildTechnicalAppBar(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatController.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF00E5FF)));
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.uid;
                    return _buildMessageNode(
                        context, message, isMe, chatController, currentUser);
                  },
                );
              },
            ),
          ),
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: Color(0xFF00E5FF)),
            ),
          _buildTerminalInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTechnicalAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0D0D0D),
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded,
            color: Color(0xFF00E5FF), size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ChatConfigPage(
                    chatId: widget.chatId, otherUserId: widget.otherUserId))),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF00E5FF).withOpacity(0.3)),
                    image: _otherUser?.profileImage.isNotEmpty == true
                        ? DecorationImage(
                            image: NetworkImage(_otherUser!.profileImage),
                            fit: BoxFit.cover)
                        : null,
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: _otherUser?.profileImage.isEmpty == true
                      ? const Icon(Icons.person,
                          color: Colors.white24, size: 18)
                      : null,
                ),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF0D0D0D), width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherUser?.name.toUpperCase() ?? AppLocalization.of(context)!.translate('loading_dots'),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5),
                  ),
                  Text(
                    '${AppLocalization.of(context)!.translate('active_now')} • ${_otherUser?.position.toUpperCase() ?? AppLocalization.of(context)!.translate('contributor')}',
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
            icon: Icon(Icons.phone_outlined,
                color: Colors.white.withOpacity(0.3), size: 18),
            onPressed: () {}),
        IconButton(
          icon: Icon(Icons.more_vert_rounded,
              color: Colors.white.withOpacity(0.3), size: 20),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ChatConfigPage(
                      chatId: widget.chatId, otherUserId: widget.otherUserId))),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessageNode(BuildContext context, MessageModel message,
      bool isMe, ChatController chatController, UserModel? currentUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe) _buildAvatar(_otherUser?.profileImage),
              const SizedBox(width: 12),
              Flexible(
                child: GestureDetector(
                  onLongPress: () => _showMessageActions(context, message, isMe,
                      chatController, currentUser?.uid ?? ""),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      borderRadius: BorderRadius.circular(12),
                      border: !isMe
                          ? const Border(
                              left: BorderSide(
                                  color: Color(0xFF00E5FF), width: 3))
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.image != null) ...[
                          ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(message.image!,
                                  fit: BoxFit.cover)),
                          if (message.text.isNotEmpty)
                            const SizedBox(height: 12),
                        ],
                        if (message.text.isNotEmpty)
                          Text(
                            message.text,
                            style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 14,
                                height: 1.55),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (isMe) _buildAvatar(currentUser?.profileImage),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.only(left: isMe ? 0 : 48, right: isMe ? 48 : 0),
            child: Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 8,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                        color: isMe
                            ? (message.isSeen
                                ? const Color(0xFF00E5FF)
                                : Colors.white10)
                            : Colors.white12,
                        shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(
                  isMe ? (message.isSeen ? AppLocalization.of(context)!.translate('delivered') : AppLocalization.of(context)!.translate('sent')) : AppLocalization.of(context)!.translate('encrypted'),
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 8,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? image) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        image: image?.isNotEmpty == true
            ? DecorationImage(image: NetworkImage(image!), fit: BoxFit.cover)
            : null,
      ),
      child: image?.isEmpty == true
          ? const Icon(Icons.person, color: Colors.white24, size: 16)
          : null,
    );
  }

  void _showMessageActions(BuildContext context, MessageModel message,
      bool isMe, ChatController chatController, String uId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMe) ...[
              _ActionTile(
                  icon: Icons.edit_rounded,
                  label: AppLocalization.of(context)!.translate('edit_payload'),
                  onTap: () {
                    Navigator.pop(context);
                    _messageController.text = message.text;
                  }),
              _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  label: AppLocalization.of(context)!.translate('delete_fragment'),
                  color: Colors.redAccent,
                  onTap: () {
                    chatController.deleteMessage(widget.chatId, message.id);
                    Navigator.pop(context);
                  }),
            ] else
              _ActionTile(
                  icon: Icons.favorite_border_rounded,
                  label: message.isLikedBy(uId)
                      ? AppLocalization.of(context)!.translate('unlike_segment')
                      : AppLocalization.of(context)!.translate('like_segment'),
                  onTap: () {
                    chatController.toggleMessageLike(widget.chatId, message.id,
                        uId, !message.isLikedBy(uId));
                    Navigator.pop(context);
                  }),
            _ActionTile(
                icon: Icons.copy_rounded,
                label: AppLocalization.of(context)!.translate('copy_content'),
                onTap: () {
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          border:
              Border(top: BorderSide(color: Colors.white.withOpacity(0.03)))),
      child: Row(
        children: [
          GestureDetector(
              onTap: _pickAndSendImage,
              child: Icon(Icons.attachment_rounded,
                  color: Colors.white.withOpacity(0.3), size: 18)),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Text('>',
                      style: GoogleFonts.sourceCodePro(
                          color: const Color(0xFF00E5FF).withOpacity(0.4),
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style:
                          GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                          hintText: AppLocalization.of(context)!.translate('initialize_message_sequence'),
                          hintStyle: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.1),
                              fontSize: 13),
                          border: InputBorder.none),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: CircleAvatar(
              backgroundColor: const Color(0xFF00E5FF).withOpacity(0.1),
              child: const Icon(Icons.send_rounded,
                  color: Color(0xFF00E5FF), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          Icon(icon, color: color ?? Colors.white.withOpacity(0.4), size: 22),
      title: Text(label,
          style: GoogleFonts.spaceGrotesk(
              color: color ?? Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700)),
      onTap: onTap,
    );
  }
}
