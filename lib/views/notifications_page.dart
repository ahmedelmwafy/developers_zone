import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';
import '../services/firestore_service.dart';
import '../models/notification_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'profile_page.dart';
import 'chat_detail_screen.dart';
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
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF00E5FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'NOTIFICATIONS',
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF00E5FF),
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'DEV_ZONE',
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF00E5FF),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: user == null
          ? Center(child: Text(locale.translate('login_to_notifications'), style: const TextStyle(color: AppColors.textSecondary)))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.translate('latest_logs').toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              color: const Color(0xFF00E5FF),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            locale.translate('stream_activity'),
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 32,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => firestore.markAllNotificationsAsRead(user.uid),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            locale.translate('mark_all_read'),
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Expanded(
                    child: StreamBuilder<List<AppNotificationModel>>(
                      stream: firestore.streamNotifications(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: 5,
                            itemBuilder: (context, index) => const NotificationShimmer(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_none_outlined, size: 64, color: Colors.white.withOpacity(0.05)),
                                const SizedBox(height: 16),
                                Text(
                                  locale.translate('all_clear'),
                                  style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.1), fontWeight: FontWeight.w800, letterSpacing: 2),
                                ),
                              ],
                            ),
                          );
                        }

                        final notifications = snapshot.data!;
                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            return NotificationCard(notification: notifications[index]);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final AppNotificationModel notification;
  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final authController = Provider.of<AuthController>(context, listen: false);
    final locale = AppLocalization.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        onTap: () {
          firestore.markNotificationAsRead(authController.currentUser!.uid, notification.id);
          _handleNavigation(context);
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.02)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (!notification.isRead)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: Color(0xFF00E5FF), shape: BoxShape.circle),
                          ),
                        ),
                      Text(
                        _getTypeLabel(notification.type, locale).toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _timeAgo(notification.createdAt, locale).toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withOpacity(0.2),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(notification.type),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.spaceGrotesk(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.5),
                            children: _parseBody(notification.body),
                          ),
                        ),
                        if (notification.type == NotificationType.profileView) ...[
                           const SizedBox(height: 20),
                           _buildActionButton(context, locale.translate('view_pulse').toUpperCase()),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(NotificationType type) {
    IconData icon;
    switch (type) {
      case NotificationType.message: icon = Icons.chat_bubble_outline; break;
      case NotificationType.like: icon = Icons.favorite_outline; break;
      case NotificationType.follow: icon = Icons.person_add_outlined; break;
      case NotificationType.profileView: icon = Icons.visibility_outlined; break;
      default: icon = Icons.notifications_none_outlined;
    }
    
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Icon(icon, color: const Color(0xFF00E5FF).withOpacity(0.5), size: 20),
    );
  }

  Widget _buildActionButton(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(colors: [Color(0xFFB2FEFA), Color(0xFF0ED2F7)]),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }

  String _getTypeLabel(NotificationType type, AppLocalization locale) {
    switch (type) {
      case NotificationType.message: return 'MESSAGE_INBOUND';
      case NotificationType.like: return locale.translate('social_reaction');
      case NotificationType.follow: return locale.translate('new_connection');
      case NotificationType.profileView: return locale.translate('profile_interact');
      case NotificationType.verify: return 'NODE_VERIFIED';
      case NotificationType.approve: return 'ACCESS_GRANTED';
      default: return 'LOG_ENTRY';
    }
  }

  List<TextSpan> _parseBody(String body) {
    // Look for parts that should be bolded (currently assuming names are at the start or in a specific format)
    // We'll bold words that start with @ or anything before first common verb
    final words = body.split(' ');
    final List<TextSpan> spans = [];
    
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final isLast = i == words.length - 1;
      final suffix = isLast ? '' : ' ';
      
      if (word.startsWith('@') || (i == 0 && words.length > 1)) {
        spans.add(TextSpan(text: word + suffix, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF00E5FF))));
      } else {
        spans.add(TextSpan(text: word + suffix));
      }
    }
    return spans;
  }

  String _timeAgo(DateTime dt, AppLocalization locale) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return locale.translate('d_ago').replaceFirst('{}', diff.inDays.toString());
    if (diff.inHours > 0) return '${diff.inHours}H AGO';
    if (diff.inMinutes > 0) return '${diff.inMinutes}M AGO';
    return locale.translate('just_now');
  }

  void _handleNavigation(BuildContext context) {
    final type = notification.type;
    final relatedId = notification.relatedId;
    if (relatedId.isEmpty) return;

    switch (type) {
      case NotificationType.message:
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(chatId: relatedId, otherUserId: ''))); // Requires otherUserId logic
        break;
      case NotificationType.follow:
      case NotificationType.profileView:
      case NotificationType.verify:
      case NotificationType.approve:
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: relatedId)));
        break;
      default: break;
    }
  }
}
