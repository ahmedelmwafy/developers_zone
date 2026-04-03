import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../views/post_details_page.dart';
import '../views/chat_detail_screen.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirestoreService _firestore = FirestoreService();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> initialize() async {
    await _messaging.requestPermission();
    await _messaging.subscribeToTopic('all');

    // Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.notification != null) {
        _showToast(message);
        // Save to history (if UI is open we might want to refresh)
        // Note: For background, FCM takes care of system notification.
      }
    });

    // Background/Terminated listener (when user clicks the notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message.data);
    });

    // Handle initial message if app was terminated
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(initialMessage.data);
    }
  }

  static void _showToast(RemoteMessage message) {
    Fluttertoast.showToast(
      msg: "${message.notification?.title}\n${message.notification?.body}",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: const Color(0xFF673AB7),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void _handleNavigation(Map<String, dynamic> data) {
    final typeStr = data['type'];
    final relatedId = data['relatedId'];
    if (typeStr == null || relatedId == null) return;

    final type = NotificationType.values.firstWhere((e) => e.toString().contains(typeStr), orElse: () => NotificationType.post);

    switch (type) {
      case NotificationType.message:
        navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => ChatDetailScreen(chatId: relatedId, otherUserId: data['otherUserId'] ?? '')));
        break;
      case NotificationType.post:
      case NotificationType.like:
        // Ideally we fetch the post first or pass it
        // For simplicity, we navigate to a placeholder or fetch it
        // navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => PostDetailsPage(postId: relatedId)));
        break;
      default:
        break;
    }
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Future<void> sendNotification({
    required String targetToken,
    required String targetUid,
    required String title,
    required String body,
    required NotificationType type,
    required String relatedId,
  }) async {
    try {
      // Direct FCM send (Legacy API structure as placeholder)
      const String serverKey = 'YOUR_FCM_SERVER_KEY'; 
      
      final payload = {
        'to': targetToken,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
        },
        'data': {
          'type': type.toString().split('.').last,
          'relatedId': relatedId,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      };

      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(payload),
      );
      
      // Save to Firestore History
      await _firestore.createNotification(targetUid, AppNotificationModel(
        id: '', 
        title: title, 
        body: body, 
        type: type, 
        relatedId: relatedId, 
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('FCM Send Error: $e');
    }
  }
}
