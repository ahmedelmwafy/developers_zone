import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/chat_model.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class ChatController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  Future<String> getOrCreateChat(String uid1, String uid2) async {
    return _firestoreService.getOrCreateChat(uid1, uid2);
  }

  Future<void> sendMessage(
      String chatId, MessageModel message, String senderName) async {
    await _firestoreService.sendMessage(chatId, message);

    // Trigger Notification
    final chatDoc = await _firestoreService.getChat(chatId);
    if (chatDoc != null) {
      final recipientId =
          chatDoc.users.firstWhere((id) => id != message.senderId);
      final recipient = await _firestoreService.getUser(recipientId);
      if (recipient?.fcmToken != null) {
        await NotificationService.sendNotification(
          targetToken: recipient!.fcmToken!,
          targetUid: recipientId,
          title: 'New Message from $senderName',
          body: message.text.isNotEmpty ? message.text : '📷 Image',
          type: NotificationType.message,
          relatedId: chatId,
          extraData: {'otherUserId': message.senderId},
        );
      }
    }
    notifyListeners();
  }

  Future<void> toggleMessageLike(
      String chatId, String messageId, String uid, bool isLiking) async {
    await _firestoreService.toggleMessageLike(chatId, messageId, uid, isLiking);
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestoreService.deleteMessage(chatId, messageId);
    notifyListeners();
  }

  Future<void> deleteChat(String chatId) async {
    await _firestoreService.deleteChat(chatId);
    notifyListeners();
  }

  Future<void> muteChat(String myUid, String chatId, {bool mute = true}) async {
    await _firestoreService.muteChat(myUid, chatId, mute: mute);
    notifyListeners();
  }

  Future<void> hideChat(String myUid, String chatId) async {
    await _firestoreService.hideChat(myUid, chatId);
    notifyListeners();
  }

  Future<void> toggleUnread(String chatId, bool isUnread) async {
    await _firestoreService.toggleUnread(chatId, isUnread);
    notifyListeners();
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestoreService.streamMessages(chatId);
  }

  Stream<List<ChatModel>> getUserChats(String uid) {
    return _firestoreService.streamUserChats(uid);
  }

  Future<void> markAsSeen(String chatId) async {
    await _firestoreService.markMessageAsSeen(chatId);
  }
}
