import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'profile_page.dart';
import 'components/shimmer_loading.dart';

class UsersListPage extends StatelessWidget {
  final String title;
  final List<String> userIds;

  const UsersListPage({
    required this.title,
    required this.userIds,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
              Container(color: Colors.white.withValues(alpha: 0.06), height: 1),
        ),
      ),
      body: userIds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_outlined,
                      size: 64,
                      color: AppColors.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No users found',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : FutureBuilder<List<UserModel>>(
              future: _fetchUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: 8,
                    itemBuilder: (context, index) => const UserTileShimmer(),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No users found',
                          style: TextStyle(color: AppColors.textMuted)));
                }

                final users = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _UserListTile(user: user);
                  },
                );
              },
            ),
    );
  }

  Future<List<UserModel>> _fetchUsers() async {
    final service = FirestoreService();
    final List<UserModel> users = [];
    for (String id in userIds) {
      final user = await service.getUser(id);
      if (user != null) users.add(user);
    }
    return users;
  }
}

class _UserListTile extends StatelessWidget {
  final UserModel user;
  const _UserListTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProfilePage(userId: user.uid))),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: user.isVerified ? AppColors.primaryGradient : null,
              color: user.isVerified ? null : AppColors.cardLight,
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundImage: user.profileImage.isNotEmpty
                  ? NetworkImage(user.profileImage)
                  : null,
              backgroundColor: AppColors.cardLight,
              child: user.profileImage.isEmpty
                  ? const Icon(Icons.person, color: AppColors.textMuted)
                  : null,
            ),
          ),
        ),
        title: GestureDetector(
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProfilePage(userId: user.uid))),
          child: Row(
            children: [
              Flexible(
                child: Text(user.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                    overflow: TextOverflow.ellipsis),
              ),
              if (user.isVerified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, color: AppColors.accent, size: 14),
              ],
            ],
          ),
        ),
        subtitle: Text(user.position.isEmpty ? 'Developer' : user.position,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.textMuted, size: 18),
      ),
    );
  }
}
