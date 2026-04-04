import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorProfileImage;
  final String authorPosition;
  final bool isAuthorVerified;
  final bool isAuthorApproved;
  final bool authorProfileComplete;
  final String text;
  final List<String> images;
  final List<String> likes; // Added for likes feature
  final List<String> tags; // Added for categorization
  final int commentCount; // Added to optimize feed display
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorProfileImage,
    required this.authorPosition,
    this.isAuthorVerified = false,
    this.isAuthorApproved = false,
    this.authorProfileComplete = false,
    required this.text,
    this.images = const [],
    this.likes = const [],
    this.tags = const [],
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
      isAuthorApproved: data['isAuthorApproved'] ?? false,
      authorProfileComplete: data['authorProfileComplete'] ?? false,
      text: data['text'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      likes: List<String>.from(data['likes'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
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
      'isAuthorApproved': isAuthorApproved,
      'authorProfileComplete': authorProfileComplete,
      'text': text,
      'images': images,
      'likes': likes,
      'tags': tags,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PostModel copyWith({
    String? text,
    List<String>? images,
    List<String>? likes,
    List<String>? tags,
    int? commentCount,
    bool? isAuthorVerified,
    bool? isAuthorApproved,
    bool? authorProfileComplete,
  }) {
    return PostModel(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorProfileImage: authorProfileImage,
      authorPosition: authorPosition,
      isAuthorVerified: isAuthorVerified ?? this.isAuthorVerified,
      isAuthorApproved: isAuthorApproved ?? this.isAuthorApproved,
      authorProfileComplete: authorProfileComplete ?? this.authorProfileComplete,
      text: text ?? this.text,
      images: images ?? this.images,
      likes: likes ?? this.likes,
      tags: tags ?? this.tags,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt,
    );
  }

  String get authorInitials {
    if (authorName.isEmpty) return '??';
    final parts = authorName.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorProfileImage;
  final String text;
  final String? parentCommentId;
  final String? replyToName;
  final List<String> authorReplies; 
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorProfileImage,
    required this.text,
    this.parentCommentId,
    this.replyToName,
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
      parentCommentId: data['parentCommentId'],
      replyToName: data['replyToName'],
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
      'parentCommentId': parentCommentId,
      'replyToName': replyToName,
      'authorReplies': authorReplies,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
