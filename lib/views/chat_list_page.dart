import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'chat_detail_screen.dart';
import '../widgets/shimmer_component.dart';
import '../widgets/page_entry_animation.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final currentUser = Provider.of<AuthController>(context).currentUser;

    if (currentUser == null) {
      return _GuestRestrictedView(locale: locale);
    }

    final chatController = Provider.of<ChatController>(context);
    final appProps = Provider.of<AppProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: PageEntryAnimation(
        child: Column(
          children: [
          // Search Bar (Synced with SearchScreen UI)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: TextField(
                controller: _searchController,
                style: AppLocalization.digitalFont(context, color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: locale.translate('search_conversations'),
                  hintStyle:
                      AppLocalization.digitalFont(context, color: Colors.white.withValues(alpha: 0.15)),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: Colors.white.withValues(alpha: 0.3), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Chat List
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: chatController.getUserChats(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ShimmerComponent.userTileShimmer(count: 6);
                }

                final chats = snapshot.data ?? [];
                if (chats.isEmpty) {
                  return _buildEmptyState(locale);
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: chats.length,
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
          ),
        ],
      ),
    ),
    floatingActionButton: Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => appProps.setTabIndex(1),
          borderRadius: BorderRadius.circular(16),
          child: const Icon(Icons.edit_note_rounded,
              color: Colors.white, size: 32),
        ),
      ),
    ),
  );
}

  Widget _buildEmptyState(AppLocalization locale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 16),
          Text(
            locale.translate('no_chats_yet'),
            style: AppLocalization.digitalFont(context, 
                color: AppColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),
        ],
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
  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final diff = DateTime.now().difference(widget.chat.lastMessageTime);
    String timeStr = locale.translate('now_caps');
    if (diff.inMinutes > 0) {
      timeStr = locale.translate('m_ago').replaceFirst('{}', diff.inMinutes.toString());
    }
    if (diff.inHours > 0) {
      timeStr = locale.translate('h_ago').replaceFirst('{}', diff.inHours.toString());
    }
    if (diff.inDays > 0) {
      timeStr = locale.translate('yesterday_caps');
    }

    return FutureBuilder<UserModel?>(
      future: FirestoreService().getUser(widget.otherUserId),
      builder: (context, userSnap) {
        final user = userSnap.data;

        return InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                  chatId: widget.chat.id, otherUserId: widget.otherUserId))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.surfaceContainerHigh,
                        image: (user?.profileImage.isNotEmpty == true)
                            ? DecorationImage(
                                image: NetworkImage(user!.profileImage),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: (user?.profileImage.isNotEmpty != true)
                          ? Icon(Icons.person,
                              color: Colors.white.withValues(alpha: 0.2), size: 30)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: (user?.lastSeen != null &&
                                  DateTime.now()
                                          .difference(user!.lastSeen!)
                                          .inMinutes <
                                      5)
                              ? const Color(0xFF00E5FF)
                              : Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            (user?.name != null)
                                ? '@${user!.name.toLowerCase().replaceAll(' ', '_')}'
                                : '...',
                            style: AppLocalization.digitalFont(context, 
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: AppLocalization.digitalFont(context, 
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.chat.lastMessage.isNotEmpty
                                  ? widget.chat.lastMessage
                                  : '...',
                              style: AppLocalization.digitalFont(context, 
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                                height: 1.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '3',
                                style: AppLocalization.digitalFont(context, 
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GuestRestrictedView extends StatelessWidget {
  final AppLocalization locale;
  const _GuestRestrictedView({required this.locale});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.lock_person_outlined, color: Color(0xFF00E5FF), size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                locale.translate('LOGIN_REQUIRED_TITLE'),
                textAlign: TextAlign.center,
                style: AppLocalization.digitalFont(context, 
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                locale.translate('LOGIN_REQUIRED_BODY'),
                textAlign: TextAlign.center,
                style: AppLocalization.digitalFont(context, 
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
