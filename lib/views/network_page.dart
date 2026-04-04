import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../providers/app_provider.dart';
import 'profile_page.dart';

enum NetworkTab { following, followers, blocked }

class NetworkPage extends StatefulWidget {
  final NetworkTab initialTab;
  final String? targetUserId;
  final bool isSingleMode;

  const NetworkPage({
    this.initialTab = NetworkTab.following,
    this.targetUserId,
    this.isSingleMode = false,
    super.key,
  });

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  late NetworkTab _activeTab;
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestore = FirestoreService();
  UserModel? _targetUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _fetchTargetUser();
  }

  Future<void> _fetchTargetUser() async {
    final currentUid = Provider.of<AuthController>(context, listen: false).currentUser?.uid;
    final uid = widget.targetUserId ?? currentUid;
    if (uid != null) {
      final user = await _firestore.getUser(uid);
      if (mounted) {
        setState(() {
          _targetUser = user;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthController>(context).currentUser;
    if (currentUser == null || _isLoading) return const Scaffold(backgroundColor: Color(0xFF0D0D0D), body: Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF))));
    if (_targetUser == null) return const Scaffold();
    
    final locale = AppLocalization.of(context)!;
    final bool isMe = currentUser.uid == _targetUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: _buildTechnicalAppBar(_targetUser!, locale),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isSingleMode && isMe)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: _buildTabSelector(),
            ),
          Expanded(
            child: _buildActiveList(_targetUser!, currentUser),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTechnicalAppBar(UserModel user, AppLocalization locale) {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      backgroundColor: const Color(0xFF0D0D0D),
      elevation: 0,
      leading: canPop
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF00E5FF)),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Text(
        locale.translate('NETWORK_MANIFEST'),
        style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF00E5FF),
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 1.5),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 20),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            image: user.profileImage.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(user.profileImage), fit: BoxFit.cover)
                : null,
          ),
          child: user.profileImage.isEmpty
              ? Center(
                  child: Text(user.initials,
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)))
              : null,
        ),
      ],
    );
  }
  Widget _buildTabSelector() {
    final locale = AppLocalization.of(context)!;
    return Row(
      children: [
        _TabItem(
            label: locale.translate('tab_following'),
            isActive: _activeTab == NetworkTab.following,
            onTap: () => setState(() => _activeTab = NetworkTab.following)),
        const SizedBox(width: 24),
        _TabItem(
            label: locale.translate('tab_followers'),
            isActive: _activeTab == NetworkTab.followers,
            onTap: () => setState(() => _activeTab = NetworkTab.followers)),
        const SizedBox(width: 24),
        _TabItem(
            label: locale.translate('tab_restricted'),
            isActive: _activeTab == NetworkTab.blocked,
            onTap: () => setState(() => _activeTab = NetworkTab.blocked)),
      ],
    );
  }

  Widget _buildActiveList(UserModel targetUser, UserModel currentUser) {
    switch (_activeTab) {
      case NetworkTab.following:
        return _buildFollowingList(targetUser, currentUser);
      case NetworkTab.followers:
        return _buildFollowersList(targetUser, currentUser);
      case NetworkTab.blocked:
        return _buildBlockedList(targetUser);
    }
  }

  Widget _buildFollowingList(UserModel targetUser, UserModel currentUser) {
    return FutureBuilder<List<UserModel>>(
      future: _loadUsers(targetUser.following),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoading();
        final users = snapshot.data!;
        final locale = AppLocalization.of(context)!;
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            _buildHeader(locale.translate('following'), '${users.length}'),
            const SizedBox(height: 24),
            ...users.map((u) {
              final isFollowing = currentUser.following.contains(u.uid);
              final isMe = currentUser.uid == u.uid;
              return _buildUserCard(
                u,
                isMe ? locale.translate('YOU') : (isFollowing ? locale.translate('unfollow') : locale.translate('follow')),
                () => isMe ? null : (isFollowing ? _unfollow(currentUser.uid, u.uid) : _follow(currentUser.uid, u.uid)),
                isOutline: isFollowing || isMe,
              );
            }),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Widget _buildFollowersList(UserModel targetUser, UserModel currentUser) {
    return FutureBuilder<List<UserModel>>(
      future: _loadUsers(targetUser.followers),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildLoading();
        final users = snapshot.data!;
        final locale = AppLocalization.of(context)!;
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            _buildHeader(locale.translate('followers'), null,
                sub: locale.translate('network_management_desc')),
            const SizedBox(height: 20),
            _buildSearchBar(locale.translate('QUERY_SYSTEM_NODES')),
            const SizedBox(height: 32),
            ...users.map((u) {
              final isFollowing = currentUser.following.contains(u.uid);
              final isMe = currentUser.uid == u.uid;
              return _buildUserCard(
                u,
                isMe ? locale.translate('YOU') : (isFollowing ? locale.translate('following') : locale.translate('follow_back')),
                () => isMe ? null : (isFollowing
                    ? _unfollow(currentUser.uid, u.uid)
                    : _follow(currentUser.uid, u.uid)),
                isOutline: isFollowing || isMe,
                showTags: true,
              );
            }),
            const SizedBox(height: 32),
            Center(
                child: Text(locale.translate('LOAD_MORE_NODES'),
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5))),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  Widget _buildBlockedList(UserModel user) {
    return FutureBuilder<List<UserModel>>(
      future: _firestore.getBlockedUsers(user.uid),
      builder: (context, snapshot) {
        final locale = AppLocalization.of(context)!;
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            _buildHeader(locale.translate('blocked_users'), null,
                sub: locale.translate('restricted_accounts_desc')),
            const SizedBox(height: 40),
            if (snapshot.hasData) ...[
              _buildRestrictionSummary(snapshot.data!.length, locale),
              const SizedBox(height: 24),
              ...snapshot.data!.map(
                  (u) => _buildBlockedCard(u, locale, () => _unblock(user.uid, u.uid))),
            ],
            const SizedBox(height: 32),
            _buildProtocolEnforcement(locale),
            const SizedBox(height: 60),
          ],
        );
      },
    );
  }

  Widget _buildHeader(String title, String? count, {String? sub}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(title,
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800)),
            if (count != null) ...[
              const SizedBox(width: 12),
              Text('($count)',
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 24,
                      fontWeight: FontWeight.w700)),
            ],
          ],
        ),
        if (sub != null) ...[
          const SizedBox(height: 8),
          Text(sub,
              style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                  height: 1.5)),
        ],
        const SizedBox(height: 12),
        Container(
            width: 60,
            height: 4,
            decoration: const BoxDecoration(
                color: Color(0xFF00E5FF),
                borderRadius: BorderRadius.all(Radius.circular(2)))),
      ],
    );
  }

  Widget _buildSearchBar(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.spaceGrotesk(
              color: Colors.white.withOpacity(0.1),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1),
          icon: Icon(Icons.search_rounded,
              color: Colors.white.withOpacity(0.2), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user, String btnLabel, VoidCallback onTap,
      {bool isOutline = false, bool showTags = false}) {
    final locale = AppLocalization.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProfilePage(userId: user.uid))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAvatar(user.profileImage),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name,
                              style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(user.position.toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white.withOpacity(0.35),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  user.bio.isNotEmpty ? user.bio : locale.translate('SYNCING_NODAL_BIOGRAPHY'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      height: 1.6),
                ),
              ],
            ),
          ),
          if (showTags) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTag('TYPESCRIPT'),
                const SizedBox(width: 8),
                _buildTag('KUBERNETES'),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isOutline
                          ? const Color(0xFF222222)
                          : const Color(0xFF00E5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        btnLabel,
                        style: GoogleFonts.spaceGrotesk(
                          color: isOutline
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (showTags) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.person_add_outlined,
                      color: Colors.white.withOpacity(0.3), size: 20),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedCard(UserModel user, AppLocalization locale, VoidCallback onUnblock) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: user.profileImage.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(user.profileImage), fit: BoxFit.cover)
                  : null,
              color: Colors.white.withOpacity(0.05),
            ),
            child: (user.profileImage.isEmpty)
                ? const Icon(Icons.person, color: Colors.white24)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${user.uid.substring(0, 8).toUpperCase()}',
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
                Text(locale.translate('blocked_relative_time').replaceFirst('{}', '3'),
                    style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 8,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onUnblock,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(locale.translate('unblock'),
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictionSummary(int count, AppLocalization locale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.03)))),
      child: Row(
        children: [
          Text(locale.translate('ACTIVE_RESTRICTIONS'),
              style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4)),
            child: Text('${count.toString().padLeft(2, '0')} ${locale.translate('total')}',
                style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFF00E5FF).withOpacity(0.6),
                    fontSize: 8,
                    fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 8),
          Icon(Icons.search_rounded,
              color: Colors.white.withOpacity(0.15), size: 14),
          const SizedBox(width: 8),
          Flexible(
            child: Text('${locale.translate('filter_hint')}...',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.1), fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolEnforcement(AppLocalization locale) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  color: Color(0xFF00E5FF), size: 24),
              const SizedBox(width: 16),
              Text(locale.translate('PROTOCOL_ENFORCEMENT'),
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            locale.translate('protocol_enforcement_desc'),
            style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String image) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        image: image.isNotEmpty
            ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover)
            : null,
        color: Colors.white.withOpacity(0.05),
      ),
      child: image.isEmpty
          ? const Icon(Icons.person, color: Colors.white24, size: 24)
          : null,
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withOpacity(0.3),
              fontSize: 8,
              fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildLoading() =>
      const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));

  Future<List<UserModel>> _loadUsers(List<String> ids) async {
    final futures = ids.map((id) => _firestore.getUser(id)).toList();
    final results = await Future.wait(futures);
    return results.whereType<UserModel>().toList();
  }

  void _unfollow(String myUid, String targetUid) async {
    await _firestore.unfollowUser(myUid, targetUid);
    setState(() {});
  }

  void _follow(String myUid, String targetUid) async {
    await _firestore.followUser(myUid, targetUid);
    setState(() {});
  }

  void _unblock(String myUid, String targetUid) async {
    await _firestore.blockUser(myUid, targetUid, false);
    setState(() {});
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: isActive
                  ? const Color(0xFF00E5FF)
                  : Colors.white.withOpacity(0.2),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 4),
            Container(
                width: 20,
                height: 2,
                decoration: const BoxDecoration(color: Color(0xFF00E5FF))),
          ],
        ],
      ),
    );
  }
}
