import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/chat_model.dart';
import '../models/ad_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';
import '../models/report_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // USER CRUD
  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<void> updateFCMToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  Future<bool> checkUsernameAvailable(String username, {String? excludeUid}) async {
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return true;
    if (excludeUid != null && query.docs.first.id == excludeUid) return true;
    return false;
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Stream<UserModel?> streamUser(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  Future<void> deleteUserData(String uid) async {
    final posts =
        await _db.collection('posts').where('authorId', isEqualTo: uid).get();
    for (var post in posts.docs) {
      await _db.collection('posts').doc(post.id).delete();
    }
    await _db.collection('users').doc(uid).delete();
  }

  // FOLLOW SYSTEM
  Future<void> followUser(String myUid, String targetUid) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(myUid), {
      'following': FieldValue.arrayUnion([targetUid]),
    });
    batch.update(_db.collection('users').doc(targetUid), {
      'followers': FieldValue.arrayUnion([myUid]),
    });
    await batch.commit();
  }

  Future<void> unfollowUser(String myUid, String targetUid) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(myUid), {
      'following': FieldValue.arrayRemove([targetUid]),
    });
    batch.update(_db.collection('users').doc(targetUid), {
      'followers': FieldValue.arrayRemove([myUid]),
    });
    await batch.commit();
  }

  // POST CRUD
  Future<void> createPost(PostModel post) async {
    await _db.collection('posts').add(post.toMap());
  }

  Future<void> updatePost(PostModel post) async {
    await _db.collection('posts').doc(post.id).update(post.toMap());
  }

  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  Future<PostModel?> getPost(String postId) async {
    final doc = await _db.collection('posts').doc(postId).get();
    if (!doc.exists) return null;
    return PostModel.fromMap(doc.data()!, doc.id);
  }

  Stream<PostModel?> streamPost(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists ? PostModel.fromMap(doc.data()!, doc.id) : null);
  }

  Future<void> togglePostLike(String postId, String uid, bool isLiking) async {
    if (isLiking) {
      await _db.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayUnion([uid])
      });
    } else {
      await _db.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayRemove([uid])
      });
    }
  }

  Future<void> addComment(CommentModel comment) async {
    await _db
        .collection('posts')
        .doc(comment.postId)
        .collection('comments')
        .add(comment.toMap());
    await _db
        .collection('posts')
        .doc(comment.postId)
        .update({'commentCount': FieldValue.increment(1)});

    // Add notification logic if it's a reply
    if (comment.parentCommentId != null) {
      // Find parent comment to notify its author
      final parentDoc = await _db
          .collection('posts')
          .doc(comment.postId)
          .collection('comments')
          .doc(comment.parentCommentId!)
          .get();
      if (parentDoc.exists) {
        final parentComment = CommentModel.fromMap(parentDoc.data()!, parentDoc.id);
        if (parentComment.authorId != comment.authorId) {
           final author = await getUser(parentComment.authorId);
           if (author?.fcmToken != null) {
             await NotificationService.sendNotification(
               targetToken: author!.fcmToken!, 
               targetUid: parentComment.authorId,
               title: 'New Reply!', 
               body: '${comment.authorName} replied into your manifest thread.',
               type: NotificationType.post,
               relatedId: comment.postId,
             );
           }
        }
      }
    }
  }

  Future<void> toggleSavedPost(String uid, String postId, bool isSaving) async {
    await _db.collection('users').doc(uid).update({
      'savedPosts': isSaving
          ? FieldValue.arrayUnion([postId])
          : FieldValue.arrayRemove([postId])
    });
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
    await _db
        .collection('posts')
        .doc(postId)
        .update({'commentCount': FieldValue.increment(-1)});
  }

  Stream<List<CommentModel>> streamComments(String postId, {int limit = 20}) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<PostModel>> streamGlobalFeed(
      {String? positionFilter, List<String> blockedUsers = const [], int limit = 20}) {
    Query query =
        _db.collection('posts').orderBy('createdAt', descending: true).limit(limit);
    if (positionFilter != null && positionFilter.isNotEmpty) {
      query = query.where('authorPosition', isEqualTo: positionFilter);
    }
    return query.snapshots().map((snapshot) {
      final posts = snapshot.docs
          .map((doc) =>
              PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((post) {
            // Visibility Rule: Show only if Verified OR (Complete AND Approved)
            return post.isAuthorVerified || 
                (post.authorProfileComplete && post.isAuthorApproved);
          })
          .toList();
      if (blockedUsers.isNotEmpty) {
        return posts
            .where((post) => !blockedUsers.contains(post.authorId))
            .toList();
      }
      return posts;
    });
  }

  Stream<List<PostModel>> streamFollowingFeed(
      {required String userId, required List<String> followingIds, int limit = 20}) {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .toList();
      return posts
          .where((post) => followingIds.contains(post.authorId))
          .toList();
    });
  }

  Stream<List<PostModel>> streamUserPosts(String uid, {int limit = 20}) {
    return _db
        .collection('posts')
        .where('authorId', isEqualTo: uid)
        .limit(limit)
        // No orderBy to avoid composite index requirement — sorted client-side.
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }

  Future<List<PostModel>> searchPosts(String query) async {
    final snapshot = await _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    final posts = snapshot.docs
        .map((doc) => PostModel.fromMap(doc.data(), doc.id))
        .toList();
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return posts
        .where((p) =>
            p.text.toLowerCase().contains(q) ||
            p.authorName.toLowerCase().contains(q) ||
            p.authorPosition.toLowerCase().contains(q))
        .toList();
  }

  // CHAT CRUD
  Future<String> getOrCreateChat(String uid1, String uid2) async {
    final List<String> userIds = [uid1, uid2]..sort();
    final query = await _db
        .collection('chats')
        .where('users', isEqualTo: userIds)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) return query.docs.first.id;
    final doc = await _db.collection('chats').add({
      'users': userIds,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': '',
      'isSeen': false,
    });
    return doc.id;
  }

  Future<ChatModel?> getChat(String chatId) async {
    final doc = await _db.collection('chats').doc(chatId).get();
    if (!doc.exists) return null;
    return ChatModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': message.text.isNotEmpty
          ? message.text
          : (message.image != null ? '📷 Image' : ''),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': message.senderId,
      'isSeen': false,
    });
  }

  Future<void> toggleMessageLike(
      String chatId, String messageId, String uid, bool isLiking) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'likedBy': isLiking
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  Stream<List<MessageModel>> streamMessages(String chatId, {int limit = 50}) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<ChatModel>> streamUserChats(String uid, {int limit = 20}) {
    return _db
        .collection('chats')
        .where('users', arrayContains: uid)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final chats = snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort by lastMessageTime descending (most recent first)
      chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return chats;
    });
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<void> markMessageAsSeen(String chatId) async {
    await _db.collection('chats').doc(chatId).update({'isSeen': true});
  }

  Future<void> toggleUnread(String chatId, bool isUnread) async {
    await _db.collection('chats').doc(chatId).update({'isSeen': !isUnread});
  }

  /// Permanently deletes a chat and all its messages (best-effort).
  Future<void> deleteChat(String chatId) async {
    // Delete sub-collection messages first
    final msgs =
        await _db.collection('chats').doc(chatId).collection('messages').get();
    final batch = _db.batch();
    for (final doc in msgs.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('chats').doc(chatId));
    await batch.commit();
  }

  /// Mutes/unmutes a chat by adding/removing its ID from the user's mutedChats list.
  Future<void> muteChat(String myUid, String chatId, {bool mute = true}) async {
    await _db.collection('users').doc(myUid).update({
      'mutedChats': mute
          ? FieldValue.arrayUnion([chatId])
          : FieldValue.arrayRemove([chatId]),
    });
  }

  /// Hides a chat from the user's list without deleting the actual messages for the other person.
  Future<void> hideChat(String myUid, String chatId) async {
    await _db.collection('users').doc(myUid).update({
      'hiddenChats': FieldValue.arrayUnion([chatId]),
    });
  }

  // AD CRUD
  Future<void> addAd(AdModel ad) async {
    await _db.collection('ads').add(ad.toMap());
  }

  Future<void> updateAd(AdModel ad) async {
    await _db.collection('ads').doc(ad.id).update(ad.toMap());
  }

  Future<void> deleteAd(String adId) async {
    await _db.collection('ads').doc(adId).delete();
  }

  Stream<List<AdModel>> streamAds({String? type, bool activeOnly = true}) {
    Query query = _db.collection('ads');
    if (activeOnly) {
      query = query.where('active', isEqualTo: true);
    }
    return query.snapshots().map((snapshot) {
      final ads = snapshot.docs
          .map((doc) => AdModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      if (type != null) {
        return ads.where((ad) => ad.type == type).toList();
      }
      return ads;
    });
  }

  // ADMIN
  Stream<List<UserModel>> streamAllUsers({int limit = 20}) {
    return _db.collection('users').limit(limit).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  Future<List<UserModel>> getAdmins() async {
    final snapshot = await _db.collection('users').where('isAdmin', isEqualTo: true).get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  Future<void> banUser(String uid, bool isBanned) async {
    await _db.collection('users').doc(uid).update({'isBanned': isBanned});
  }

  Future<void> verifyUser(String uid, bool isVerified) async {
    await _db.collection('users').doc(uid).update({'isVerified': isVerified});
  }

  Future<void> approveUser(String uid, bool isApproved) async {
    await _db.collection('users').doc(uid).update({'isApproved': isApproved});
  }

  // NOTIFICATIONS
  Future<void> createNotification(
      String uid, AppNotificationModel notification) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .add(notification.toMap());
  }

  Stream<List<AppNotificationModel>> streamNotifications(String uid, {int limit = 20}) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> markNotificationAsRead(String uid, String notificationId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllNotificationsAsRead(String uid) async {
    final batch = _db.batch();
    final notifications = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> toggleAdmin(String uid, bool isAdmin) async {
    await _db.collection('users').doc(uid).update({'isAdmin': isAdmin});
  }

  Future<void> blockUser(String myUid, String otherUid, bool isBlocking) async {
    if (isBlocking) {
      await _db.collection('users').doc(myUid).update({
        'blockedUsers': FieldValue.arrayUnion([otherUid]),
      });
    } else {
      await _db.collection('users').doc(myUid).update({
        'blockedUsers': FieldValue.arrayRemove([otherUid]),
      });
    }
  }

  Future<List<UserModel>> searchUsers(String query, {int limit = 50}) async {
    final snapshot = await _db.collection('users').limit(limit * 2).get(); // Fetch double for filtering margin
    final users =
        snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return users
        .where((u) =>
            u.name.toLowerCase().contains(q) ||
            u.username.toLowerCase().contains(q) ||
            u.position.toLowerCase().contains(q) ||
            u.uid.toLowerCase().contains(q) || // UID search support
            u.city.toLowerCase().contains(q) ||
            u.country.toLowerCase().contains(q))
        .toList();
  }

  Future<List<UserModel>> getBlockedUsers(String uid) async {
    final me = await getUser(uid);
    if (me == null || me.blockedUsers.isEmpty) return [];
    final futures = me.blockedUsers.map(getUser).toList();
    final results = await Future.wait(futures);
    return results.whereType<UserModel>().toList();
  }

  Stream<int> streamUnreadNotificationsCount(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // PROFILE VIEWS
  Future<void> recordProfileView(String viewerId, String viewedId) async {
    if (viewerId == viewedId) return;

    final viewRef = _db
        .collection('users')
        .doc(viewedId)
        .collection('profile_views')
        .doc(viewerId);

    final doc = await viewRef.get();
    bool isNewView = true;

    if (doc.exists) {
      final lastView = (doc.data()?['createdAt'] as Timestamp).toDate();
      // Only notify again if last view was more than 24 hours ago
      if (DateTime.now().difference(lastView).inHours < 24) {
        isNewView = false;
      }
    }

    await viewRef.set({
      'viewerId': viewerId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (isNewView) {
      final viewer = await getUser(viewerId);
      final viewed = await getUser(viewedId);

      if (viewer != null && viewed != null) {
        // Persist to notifications collection for the UI list
        final notification = AppNotificationModel(
          id: '', // Generated by Firestore
          title: 'Pulse Detected',
          body: '${viewer.name} scanned your profile transcript.',
          type: NotificationType.profileView,
          relatedId: viewerId,
          createdAt: DateTime.now(),
        );
        await createNotification(viewedId, notification);

        // Send Push Notification
        if (viewed.fcmToken != null && viewed.pushNotifications) {
          await NotificationService.sendNotification(
            targetToken: viewed.fcmToken!,
            targetUid: viewedId,
            title: notification.title,
            body: notification.body,
            type: NotificationType.profileView,
            relatedId: viewerId,
          );
        }
      }
    }
  }

  Stream<List<Map<String, dynamic>>> streamProfileViewers(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('profile_views')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<PostModel>> streamSavedPosts(List<String> postIds) {
    if (postIds.isEmpty) return Stream.value([]);
    // Firestore whereIn limit is 30 in modern versions
    final ids = postIds.take(30).toList();
    return _db
        .collection('posts')
        .where(FieldPath.documentId, whereIn: ids)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // AD SETTINGS
  Stream<AdSettingsModel> streamAdSettings() {
    return _db.collection('settings').doc('ads').snapshots().map((doc) {
      if (!doc.exists) return AdSettingsModel();
      return AdSettingsModel.fromMap(doc.data()!);
    });
  }

  Future<void> updateAdSettings(AdSettingsModel settings) async {
    await _db.collection('settings').doc('ads').set(settings.toMap());
  }

  // CONTENT MODERATION
  Future<void> reportPost(ReportModel report) async {
    await _db.collection('reports').add(report.toMap());
  }

  Stream<List<ReportModel>> streamReports() {
    return _db.collection('reports').orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => ReportModel.fromMap(doc.data(), doc.id)).toList()
    );
  }

  Future<void> dismissReports(String postId) async {
    final snapshot = await _db.collection('reports').where('postId', isEqualTo: postId).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // SYSTEM ANALYTICS
  Future<Map<String, int>> getCounts() async {
    final users = await _db.collection('users').count().get();
    final posts = await _db.collection('posts').count().get();
    final ads = await _db.collection('ads').count().get();
    final reports = await _db.collection('reports').count().get();
    return {
      'users': users.count ?? 0,
      'posts': posts.count ?? 0,
      'ads': ads.count ?? 0,
      'reports': reports.count ?? 0,
    };
  }

  // GRANULAR USER CONTROL
  Future<void> toggleUserPermission(String uid, String field, bool value) async {
    await _db.collection('users').doc(uid).update({field: value});
    
    // Notify user about the action
    final user = await getUser(uid);
    if (user?.fcmToken != null) {
      String title = 'Security Update';
      String body = 'An administrative manifestation has altered your transcript permissions.';
      if (field == 'isLocked' && value) body = 'Your profile has been locked for review.';
      if (field == 'isVerified' && value) body = 'Your manifest has been verified by an Architect.';
      if (field == 'canPost' && !value) body = 'Your posting permissions have been restricted.';
      
      await NotificationService.sendNotification(
        targetToken: user!.fcmToken!,
        targetUid: uid,
        title: title,
        body: body,
        type: NotificationType.system,
      );
    }
  }

  // GLOBAL PUSH
  Future<void> sendGlobalNotification(String title, String body) async {
    final snapshot = await _db.collection('users').get();
    for (var doc in snapshot.docs) {
      final user = UserModel.fromMap(doc.data());
      if (user.fcmToken != null) {
        await NotificationService.sendNotification(
          targetToken: user.fcmToken!,
          targetUid: user.uid,
          title: title,
          body: body,
          type: NotificationType.system,
        );
      }
    }
  }

  Future<void> autoFollowFeaturedUsers(String uid) async {
    final featured = await _db.collection('users').where('isFeatured', isEqualTo: true).get();
    for (var doc in featured.docs) {
      final targetUid = doc.id;
      if (targetUid != uid) {
        await followUser(uid, targetUid);
      }
    }
  }
}
