import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/chat_model.dart';
import '../models/ad_model.dart';
import '../models/notification_model.dart';

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

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
        (doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  Future<void> deleteUserData(String uid) async {
    final posts = await _db.collection('posts').where('authorId', isEqualTo: uid).get();
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

  Future<void> togglePostLike(String postId, String uid, bool isLiking) async {
    if (isLiking) {
      await _db.collection('posts').doc(postId).update({'likes': FieldValue.arrayUnion([uid])});
    } else {
      await _db.collection('posts').doc(postId).update({'likes': FieldValue.arrayRemove([uid])});
    }
  }

  Future<void> addComment(CommentModel comment) async {
    await _db.collection('posts').doc(comment.postId).collection('comments').add(comment.toMap());
    await _db.collection('posts').doc(comment.postId).update({'commentCount': FieldValue.increment(1)});
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _db.collection('posts').doc(postId).collection('comments').doc(commentId).delete();
    await _db.collection('posts').doc(postId).update({'commentCount': FieldValue.increment(-1)});
  }

  Stream<List<CommentModel>> streamComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<PostModel>> streamGlobalFeed({String? positionFilter, List<String> blockedUsers = const []}) {
    Query query = _db.collection('posts').orderBy('createdAt', descending: true);
    if (positionFilter != null && positionFilter.isNotEmpty) {
      query = query.where('authorPosition', isEqualTo: positionFilter);
    }
    return query.snapshots().map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      if (blockedUsers.isNotEmpty) {
        return posts.where((post) => !blockedUsers.contains(post.authorId)).toList();
      }
      return posts;
    });
  }

  Stream<List<PostModel>> streamUserPosts(String uid) {
    return _db
        .collection('posts')
        .where('authorId', isEqualTo: uid)
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
  Future<String> startOrGetChat(String uid1, String uid2) async {
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
    await _db.collection('chats').doc(chatId).collection('messages').add(message.toMap());
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': message.text.isNotEmpty
          ? message.text
          : (message.image != null ? '📷 Image' : ''),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': message.senderId,
      'isSeen': false,
    });
  }

  Future<void> toggleMessageLike(String chatId, String messageId, String uid, bool isLiking) async {
    await _db.collection('chats').doc(chatId).collection('messages').doc(messageId).update({
      'likedBy': isLiking ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
    });
  }

  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<ChatModel>> streamUserChats(String uid) {
    return _db
        .collection('chats')
        .where('users', arrayContains: uid)
        // ⚠️ No orderBy here — avoids composite index requirement.
        // Sorting is done client-side below.
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
    final msgs = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();
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

  Stream<List<AdModel>> streamAds({String? type}) {
    Query query = _db.collection('ads').where('active', isEqualTo: true);
    if (type != null) query = query.where('type', isEqualTo: type);
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => AdModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // ADMIN
  Stream<List<UserModel>> streamAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList());
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
  Future<void> createNotification(String uid, AppNotificationModel notification) async {
    await _db.collection('users').doc(uid).collection('notifications').add(notification.toMap());
  }

  Stream<List<AppNotificationModel>> streamNotifications(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
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

  Future<List<UserModel>> searchUsers(String query) async {
    final snapshot = await _db.collection('users').get();
    final users = snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data()))
        .toList();
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return users
        .where((u) =>
            u.name.toLowerCase().contains(q) ||
            u.position.toLowerCase().contains(q) ||
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
}
