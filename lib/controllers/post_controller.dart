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

  Stream<List<PostModel>> getGlobalFeed({String? positionFilter, List<String> blockedUsers = const []}) {
    return _firestoreService.streamGlobalFeed(positionFilter: positionFilter, blockedUsers: blockedUsers);
  }

  Stream<List<PostModel>> getFollowingFeed({required String userId, required List<String> followingIds}) {
    return _firestoreService.streamFollowingFeed(userId: userId, followingIds: followingIds);
  }

  Stream<List<PostModel>> getUserPosts(String uid) {
    return _firestoreService.streamUserPosts(uid);
  }

  Future<void> togglePostLike(String postId, String uid, bool isLiking) async {
    await _firestoreService.togglePostLike(postId, uid, isLiking);
    if (isLiking) {
       // Get post to find author
       final posts = await _firestoreService.streamGlobalFeed().first;
       final post = posts.firstWhere((p) => p.id == postId);
       if (post.authorId != uid) {
          final author = await _firestoreService.getUser(post.authorId);
          if (author?.fcmToken != null) {
             await NotificationService.sendNotification(
               targetToken: author!.fcmToken!, 
               targetUid: post.authorId,
               title: 'New Like!', 
               body: 'Someone liked your post.',
               type: NotificationType.like,
               relatedId: postId,
             );
          }
       }
    }
    notifyListeners();
  }

  Future<void> addComment(CommentModel comment) async {
    await _firestoreService.addComment(comment);
    // Get post to find author
    final posts = await _firestoreService.streamGlobalFeed().first;
    final post = posts.firstWhere((p) => p.id == comment.postId);
    if (post.authorId != comment.authorId) {
       final author = await _firestoreService.getUser(post.authorId);
       if (author?.fcmToken != null) {
          await NotificationService.sendNotification(
            targetToken: author!.fcmToken!, 
            targetUid: post.authorId,
            title: 'New Comment!', 
            body: '${comment.authorName} commented on your post.',
            type: NotificationType.post,
            relatedId: comment.postId,
          );
       }
    }
    notifyListeners();
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

  Future<void> toggleSavedPost(String uid, String postId, bool isSaving) async {
    await _firestoreService.toggleSavedPost(uid, postId, isSaving);
    notifyListeners();
  }
}
