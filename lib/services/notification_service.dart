import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;
// http import removed as it was redundant with googleapis_auth's internal client or similar usage
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../views/chat_detail_screen.dart';
import '../views/profile_page.dart';
import '../views/admin_dashboard_page.dart';
import '../theme/app_theme.dart';
import '../firebase_options.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirestoreService _firestore = FirestoreService();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static AutoRefreshingAuthClient? _authClient;

  static Future<void> initialize() async {
    await _messaging.requestPermission();

    // Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.notification != null) {
        _showToast(message);
      }
    });

    // Background/Terminated listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message.data);
    });

    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(initialMessage.data);
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Node synchronized with topic: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Node detached from topic: $topic');
  }

  static void _showToast(RemoteMessage message) {
    if (navigatorKey.currentContext != null) {
      AppWidgets.showToast(
        navigatorKey.currentContext!,
        "${message.notification?.title}: ${message.notification?.body}",
        type: SnackBarType.info,
      );
    }
  }

  static void _handleNavigation(Map<String, dynamic> data) {
    final typeStr = data['type'];
    final relatedId = data['relatedId'];
    if (typeStr == null || relatedId == null) return;

    final type = NotificationType.values.firstWhere(
        (e) => e.toString().contains(typeStr),
        orElse: () => NotificationType.post);

    switch (type) {
      case NotificationType.admin_approval:
        navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => AdminDashboardPage(initialUserId: data['relatedId'])));
        break;
      case NotificationType.message:
        navigatorKey.currentState?.push(MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
                chatId: relatedId, otherUserId: data['otherUserId'] ?? '')));
        break;
      case NotificationType.follow:
      case NotificationType.verify:
      case NotificationType.approve:
        navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => ProfilePage(userId: relatedId)));
        break;
      case NotificationType.post:
      case NotificationType.like:
        // Navigator to post details - typically requires mapping relatedId to post model first or a dedicated ID loader
        break;
      case NotificationType.profileView:
        navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => ProfilePage(userId: relatedId)));
        break;
      case NotificationType.system:
      case NotificationType.ad:
        // System and Ad notifications typically just open the app or a specific URL
        break;
    }
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Future<AutoRefreshingAuthClient> _getAuthClient() async {
    if (_authClient != null) return _authClient!;

    final String jsonString =
        await rootBundle.loadString('assets/service_account.json');
    final accountCredentials = ServiceAccountCredentials.fromJson(jsonString);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    _authClient = await clientViaServiceAccount(accountCredentials, scopes);
    return _authClient!;
  }

  static Future<void> sendNotification({
    String? targetToken,
    required String targetUid,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
    Map<String, dynamic>? extraData,
  }) async {
    final String rId = relatedId ?? '';

    // 1. ALWAYS Save to Firestore History first
    try {
      await _firestore.createNotification(
          targetUid,
          AppNotificationModel(
            id: '',
            title: title,
            body: body,
            type: type,
            relatedId: rId,
            createdAt: DateTime.now(),
          ));
    } catch (e) {
      debugPrint('Notification Database Persist Error: $e');
      debugPrint('TIP: Ensure your Firestore Security Rules allow creation of documents in /users/{uid}/notifications/ by other users.');
    }

    // 2. If token exists, try sending push to node
    if (targetToken != null && targetToken.isNotEmpty) {
      try {
        final client = await _getAuthClient();
        final String projectId = DefaultFirebaseOptions.currentPlatform.projectId;
        final String url =
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

        final Map<String, dynamic> payload = {
          'message': {
            'token': targetToken,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': {
              'type': type.toString().split('.').last,
              'relatedId': rId,
              if (extraData != null) ...extraData,
            },
            'android': {
              'priority': 'HIGH',
              'notification': {
                'channel_id': 'high_importance_channel',
                'notification_priority': 'PRIORITY_HIGH',
              }
            },
            'apns': {
              'payload': {
                'aps': {'sound': 'default', 'badge': 1}
              }
            }
          }
        };

        final response = await client.post(
          Uri.parse(url),
          body: jsonEncode(payload),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode != 200) {
          debugPrint('FCM HTTP v1 Protocol Error: ${response.body}');
        }
      } catch (e) {
        debugPrint('FCM Transmission Error: $e');
      }
    }
  }

  static Future<void> notifyAdmins({
    required String title,
    required String body,
    required String relatedId,
  }) async {
    final admins = await _firestore.getAdmins();
    for (final admin in admins) {
      if (admin.fcmToken != null && admin.fcmToken!.isNotEmpty) {
        await sendNotification(
          targetToken: admin.fcmToken!,
          targetUid: admin.uid,
          title: title,
          body: body,
          type: NotificationType.admin_approval,
          relatedId: relatedId,
        );
      }
    }
  }
}
