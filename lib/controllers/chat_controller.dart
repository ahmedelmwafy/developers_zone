import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/chat_model.dart';

class ChatController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  Future<String> startOrGetChat(String uid1, String uid2) async {
    return _firestoreService.startOrGetChat(uid1, uid2);
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    await _firestoreService.sendMessage(chatId, message);
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
