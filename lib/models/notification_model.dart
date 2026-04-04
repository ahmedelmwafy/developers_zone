import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { message, post, like, follow, verify, approve, profileView, system, ad }

class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String relatedId; // postId, chatId, etc.
  final DateTime createdAt;
  final bool isRead;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId = '',
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotificationModel.fromMap(Map<String, dynamic> data, String docId) {
    return AppNotificationModel(
      id: docId,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: NotificationType.values.firstWhere((e) => e.toString() == data['type'], orElse: () => NotificationType.post),
      relatedId: data['relatedId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type.toString(),
      'relatedId': relatedId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}
