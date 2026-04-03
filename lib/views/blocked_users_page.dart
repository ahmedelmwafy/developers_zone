import 'package:developers_zone/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import 'profile_page.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  late Future<List<UserModel>> _blockedFuture;

  @override
  void initState() {
    super.initState();
    _loadBlocked();
  }

  void _loadBlocked() {
    final auth = Provider.of<AuthController>(context, listen: false);
    _blockedFuture = auth.getBlockedUsers();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(locale.translate('blocked_users'),
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child:
              Container(color: Colors.white.withValues(alpha: 0.06), height: 1),
        ),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _blockedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.block_outlined,
                        size: 60,
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  const SizedBox(height: 20),
                  Text(locale.translate('blocked_users_empty'),
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(locale.translate('blocked_users_empty_sub'),
                      style:
                          const TextStyle(color: AppColors.textMuted, fontSize: 14)),
                ],
              ),
            );
          }

          final blockedUsers = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return _BlockedUserTile(
                user: user,
                onUnblock: () async {
                  final auth =
                      Provider.of<AuthController>(context, listen: false);
                  await auth.unblockUser(user.uid);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(locale.translate('unblocked_success').replaceFirst('{name}', user.name)),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                    setState(_loadBlocked);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onUnblock;
  const _BlockedUserTile({required this.user, required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Avatar with a blocked overlay indicator - Navigate to Profile
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProfilePage(userId: user.uid))),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: user.profileImage.isNotEmpty
                      ? NetworkImage(user.profileImage)
                      : null,
                  backgroundColor: AppColors.cardLight,
                  child: user.profileImage.isEmpty
                      ? const Icon(Icons.person, color: AppColors.textMuted)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                        color: AppColors.error, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.block, size: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Name + position
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProfilePage(userId: user.uid))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  if (user.position.isNotEmpty)
                    Text(user.position,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ),
          // Unblock button
          TextButton(
            onPressed: onUnblock,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(AppLocalization.of(context)!.translate('unblock'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
