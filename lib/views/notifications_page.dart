import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../services/firestore_service.dart';
import '../models/notification_model.dart';
import '../providers/app_provider.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final firestore = FirestoreService();
    final locale = AppLocalization.of(context)!;
    final user = authController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.translate('notifications')),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Please login to see notifications'))
          : StreamBuilder<List<AppNotificationModel>>(
              stream: firestore.streamNotifications(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text(locale.translate('no_notifications')),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data!;
                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: notification.isRead ? Colors.grey[800] : const Color(0xFF673AB7),
                        child: Icon(_getIcon(notification.type), color: Colors.white, size: 20),
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        notification.body,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Text(
                        _formatDate(notification.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                      onTap: () {
                        firestore.markNotificationAsRead(user.uid, notification.id);
                        // Navigation logic (same as NotificationService)
                        // This could be centralized
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.message: return Icons.message;
      case NotificationType.post: return Icons.article;
      case NotificationType.like: return Icons.favorite;
      case NotificationType.verify: return Icons.verified;
      case NotificationType.approve: return Icons.check_circle;
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
