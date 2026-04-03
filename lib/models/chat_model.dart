import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> users;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastSenderId;
  final bool isSeen;

  ChatModel({
    required this.id,
    required this.users,
    this.lastMessage = '',
    required this.lastMessageTime,
    this.lastSenderId = '',
    this.isSeen = false,
  });

  factory ChatModel.fromMap(Map<String, dynamic> data, String docId) {
    return ChatModel(
      id: docId,
      users: List<String>.from(data['users'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSenderId: data['lastSenderId'] ?? '',
      isSeen: data['isSeen'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'users': users,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastSenderId': lastSenderId,
      'isSeen': isSeen,
    };
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String? image;
  final DateTime createdAt;
  final bool isSeen;
  final List<String> likedBy; // uids that liked this message

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.text = '',
    this.image,
    required this.createdAt,
    this.isSeen = false,
    this.likedBy = const [],
  });

  bool isLikedBy(String uid) => likedBy.contains(uid);

  factory MessageModel.fromMap(Map<String, dynamic> data, String docId) {
    return MessageModel(
      id: docId,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      image: data['image'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSeen: data['isSeen'] ?? false,
      likedBy: data['likedBy'] != null ? List<String>.from(data['likedBy']) : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'image': image,
      'createdAt': Timestamp.fromDate(createdAt),
      'isSeen': isSeen,
      'likedBy': likedBy,
    };
  }
}
