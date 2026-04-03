import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../services/firestore_service.dart';
import '../models/notification_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'components/shimmer_loading.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final firestore = FirestoreService();
    final locale = AppLocalization.of(context)!;
    final user = authController.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppWidgets.appBar(locale.translate('notifications'), centerTitle: true),
      body: user == null
          ? Center(child: Text(locale.translate('login_to_notifications'), style: const TextStyle(color: AppColors.textSecondary)))
          : StreamBuilder<List<AppNotificationModel>>(
              stream: firestore.streamNotifications(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: 8,
                    itemBuilder: (context, index) => const UserTileShimmer(),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.cardLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                          ),
                          child: const Icon(Icons.notifications_none_outlined, size: 40, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        Text(locale.translate('all_clear'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(locale.translate('no_notifications'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final isUnread = !notification.isRead;

                    return InkWell(
                      onTap: () => firestore.markNotificationAsRead(user.uid, notification.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        color: isUnread ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon badge
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: isUnread ? AppColors.primaryGradient : null,
                                color: isUnread ? null : AppColors.cardLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_getIcon(notification.type), color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notification.title,
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (isUnread)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(notification.body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                                  const SizedBox(height: 5),
                                  Text(
                                    _formatDate(notification.createdAt, locale),
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
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
              },
            ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.message: return Icons.chat_bubble;
      case NotificationType.post: return Icons.article;
      case NotificationType.like: return Icons.favorite;
      case NotificationType.verify: return Icons.verified;
      case NotificationType.approve: return Icons.check_circle;
      case NotificationType.follow: return Icons.person_add;
    }
  }

  String _formatDate(DateTime dt, AppLocalization locale) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return locale.translate('days_ago').replaceFirst('{}', diff.inDays.toString());
    if (diff.inHours > 0) return locale.translate('hours_ago').replaceFirst('{}', diff.inHours.toString());
    if (diff.inMinutes > 0) return locale.translate('minutes_ago').replaceFirst('{}', diff.inMinutes.toString());
    return locale.translate('just_now');
  }
}
