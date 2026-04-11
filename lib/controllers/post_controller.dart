import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/post_model.dart';

import '../models/notification_model.dart';
import '../services/notification_service.dart';

class PostController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> createPost(PostModel post) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.createPost(post);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePost(String postId) async {
    await _firestoreService.deletePost(postId);
    notifyListeners();
  }

  Future<void> updatePost(PostModel post) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.updatePost(post);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<PostModel>> getGlobalFeed({String? positionFilter, List<String> blockedUsers = const [], int limit = 20}) {
    return _firestoreService.streamGlobalFeed(positionFilter: positionFilter, blockedUsers: blockedUsers, limit: limit);
  }

  Stream<List<PostModel>> getFollowingFeed({required String userId, required List<String> followingIds, int limit = 20}) {
    return _firestoreService.streamFollowingFeed(userId: userId, followingIds: followingIds, limit: limit);
  }

  Stream<List<PostModel>> getUserPosts(String uid, {int limit = 20}) {
    return _firestoreService.streamUserPosts(uid, limit: limit);
  }

  Future<void> togglePostLike(String postId, String uid, bool isLiking) async {
    await _firestoreService.togglePostLike(postId, uid, isLiking);
    if (isLiking) {
       final post = await _firestoreService.getPost(postId);
       if (post != null && post.authorId != uid) {
          final author = await _firestoreService.getUser(post.authorId);
          await NotificationService.sendNotification(
            targetToken: author?.fcmToken, 
            targetUid: post.authorId,
            title: 'New Like!', 
            body: 'Someone liked your post.',
            type: NotificationType.like,
            relatedId: postId,
          );
       }
    }
  }

  Future<void> addComment(CommentModel comment) async {
    await _firestoreService.addComment(comment);
    final post = await _firestoreService.getPost(comment.postId);
    if (post != null && post.authorId != comment.authorId) {
       final author = await _firestoreService.getUser(post.authorId);
       await NotificationService.sendNotification(
         targetToken: author?.fcmToken, 
         targetUid: post.authorId,
         title: 'New Comment!', 
         body: '${comment.authorName} commented on your post.',
         type: NotificationType.post,
         relatedId: comment.postId,
       );
    }
  }

  Stream<List<CommentModel>> getPostComments(String postId) {
    return _firestoreService.streamComments(postId);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _firestoreService.deleteComment(postId, commentId);
    notifyListeners();
  }

  Future<List<PostModel>> searchPosts(String query) async {
    return await _firestoreService.searchPosts(query);
  }

  Future<void> repostPost(PostModel originalPost, String currentUserId, String currentUserName, String currentUserProfileImage, String currentUserPosition, String repostLabel) async {
    _isLoading = true;
    notifyListeners();
    try {
      final repost = PostModel(
        id: '',
        authorId: currentUserId,
        authorName: currentUserName,
        authorProfileImage: currentUserProfileImage,
        authorPosition: currentUserPosition,
        text: '$repostLabel: \n\n${originalPost.text}',
        images: originalPost.images,
        createdAt: DateTime.now(),
        tags: ['REPOST', originalPost.id],
      );
      await _firestoreService.createPost(repost);
      
      // Notify original author
      if (originalPost.authorId != currentUserId) {
        final author = await _firestoreService.getUser(originalPost.authorId);
        await NotificationService.sendNotification(
          targetToken: author?.fcmToken,
          targetUid: originalPost.authorId,
          title: 'Manifest Reposted!',
          body: '$currentUserName shared your transcript.',
          type: NotificationType.post,
          relatedId: originalPost.id,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleSavedPost(String uid, String postId, bool isSaving) async {
    await _firestoreService.toggleSavedPost(uid, postId, isSaving);
    notifyListeners();
  }

  Stream<PostModel?> getPostStream(String postId) {
    return _firestoreService.streamPost(postId);
  }
}
