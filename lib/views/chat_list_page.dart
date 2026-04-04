import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  String _selectedFilter = 'ALL';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final currentUser = Provider.of<AuthController>(context).currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: Text(
            locale.translate('login_to_chat'),
            style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
          ),
        ),
      );
    }

    final chatController = Provider.of<ChatController>(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surfaceContainerHigh,
              backgroundImage: (currentUser.profileImage.isNotEmpty) ? NetworkImage(currentUser.profileImage) : null,
              child: (currentUser.profileImage.isEmpty) ? const Icon(Icons.person, color: AppColors.onSurfaceVariant) : null,
            ),
          ),
        ),
        title: Text(
          locale.translate('app_name').toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF00E5FF),
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF00E5FF)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.ghostBorder),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: locale.translate('search_conversations'),
                  hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.2)),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.3), size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
              ),
            ),
          ),
          
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: locale.translate('all_caps'),
                  isActive: _selectedFilter == 'ALL',
                  onTap: () => setState(() => _selectedFilter = 'ALL'),
                ),
                _FilterChip(
                  label: locale.translate('unread_caps'),
                  isActive: _selectedFilter == 'UNREAD',
                  onTap: () => setState(() => _selectedFilter = 'UNREAD'),
                ),
                _FilterChip(
                  label: locale.translate('groups_caps'),
                  isActive: _selectedFilter == 'GROUPS',
                  onTap: () => setState(() => _selectedFilter = 'GROUPS'),
                ),
                _FilterChip(
                  label: locale.translate('mentors_caps'),
                  isActive: _selectedFilter == 'MENTORS',
                  onTap: () => setState(() => _selectedFilter = 'MENTORS'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Chat List
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: chatController.getUserChats(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    itemCount: 6,
                    itemBuilder: (context, index) => const UserTileShimmer(),
                  );
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
                    final isUnread = !chat.isSeen && chat.lastSenderId != currentUser.uid;

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
              color: const Color(0xFF00E5FF).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(16),
            child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 32),
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
          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          Text(
            locale.translate('no_chats_yet'),
            style: GoogleFonts.spaceGrotesk(color: AppColors.onSurface, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2979FF) : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
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
    if (diff.inMinutes > 0) timeStr = locale.translate('m_ago').replaceFirst('{}', diff.inMinutes.toString());
    if (diff.inHours > 0) timeStr = locale.translate('h_ago').replaceFirst('{}', diff.inHours.toString());
    if (diff.inDays > 0) timeStr = locale.translate('yesterday_caps');

    return FutureBuilder<UserModel?>(
      future: FirestoreService().getUser(widget.otherUserId),
      builder: (context, userSnap) {
        final user = userSnap.data;
        final isLoading = userSnap.connectionState == ConnectionState.waiting;

        return InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                  chatId: widget.chat.id, otherUserId: widget.otherUserId))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            ? DecorationImage(image: NetworkImage(user!.profileImage), fit: BoxFit.cover)
                            : null,
                      ),
                      child: (user?.profileImage.isNotEmpty != true)
                          ? Icon(Icons.person, color: Colors.white.withOpacity(0.2), size: 30)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: (user?.lastSeen != null && DateTime.now().difference(user!.lastSeen!).inMinutes < 5) 
                              ? const Color(0xFF00E5FF) 
                              : Colors.white.withOpacity(0.2),
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
                            (user?.name != null) ? '@${user!.name.toLowerCase().replaceAll(' ', '_')}' : '...',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white.withOpacity(0.3),
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
                              widget.chat.lastMessage.isNotEmpty ? widget.chat.lastMessage : '...',
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.5),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '3', 
                                style: GoogleFonts.spaceGrotesk(
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
