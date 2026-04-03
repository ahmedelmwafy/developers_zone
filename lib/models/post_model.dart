import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorProfileImage;
  final String authorPosition;
  final bool isAuthorVerified;
  final String text;
  final List<String> images;
  final List<String> likes; // Added for likes feature
  final int commentCount; // Added to optimize feed display
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorProfileImage,
    required this.authorPosition,
    this.isAuthorVerified = false,
    required this.text,
    this.images = const [],
    this.likes = const [],
    this.commentCount = 0,
    required this.createdAt,
  });

  factory PostModel.fromMap(Map<String, dynamic> data, String docId) {
    return PostModel(
      id: docId,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown User',
      authorProfileImage: data['authorProfileImage'] ?? '',
      authorPosition: data['authorPosition'] ?? '',
      isAuthorVerified: data['isAuthorVerified'] ?? false,
      text: data['text'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileImage': authorProfileImage,
      'authorPosition': authorPosition,
      'isAuthorVerified': isAuthorVerified,
      'text': text,
      'images': images,
      'likes': likes,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorProfileImage;
  final String text;
  final List<String> authorReplies; // For simple direct replies if needed or identifiers
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorProfileImage,
    required this.text,
    this.authorReplies = const [],
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> data, String docId) {
    return CommentModel(
      id: docId,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown User',
      authorProfileImage: data['authorProfileImage'] ?? '',
      text: data['text'] ?? '',
      authorReplies: List<String>.from(data['authorReplies'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileImage': authorProfileImage,
      'text': text,
      'authorReplies': authorReplies,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
