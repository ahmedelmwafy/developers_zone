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
    return _db.collection('users').doc(uid).snapshots().map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  Future<void> deleteUserData(String uid) async {
    // Delete posts by user
    final posts = await _db.collection('posts').where('authorId', isEqualTo: uid).get();
    for (var post in posts.docs) {
      await _db.collection('posts').doc(post.id).delete();
    }
    // Delete user profile
    await _db.collection('users').doc(uid).delete();
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
    await _db.collection('posts').doc(comment.postId).collection('comments').add(comment.toMap());
    await _db.collection('posts').doc(comment.postId).update({
      'commentCount': FieldValue.increment(1)
    });
  }

  Stream<List<CommentModel>> streamComments(String postId) {
    return _db.collection('posts').doc(postId).collection('comments').orderBy('createdAt', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => CommentModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<PostModel>> streamGlobalFeed({String? positionFilter, List<String> blockedUsers = const []}) {
    Query query = _db.collection('posts').orderBy('createdAt', descending: true);
    if (positionFilter != null && positionFilter.isNotEmpty) {
      query = query.where('authorPosition', isEqualTo: positionFilter);
    }
    return query.snapshots().map((snapshot) {
      final posts = snapshot.docs.map((doc) => PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      // Filter out posts from blocked users on the client side
      if (blockedUsers.isNotEmpty) {
        return posts.where((post) => !blockedUsers.contains(post.authorId)).toList();
      }
      return posts;
    });
  }

  Stream<List<PostModel>> streamUserPosts(String uid) {
    return _db.collection('posts').where('authorId', isEqualTo: uid).orderBy('createdAt', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => PostModel.fromMap(doc.data(), doc.id)).toList());
  }

  // CHAT CRUD
  Future<String> startOrGetChat(String uid1, String uid2) async {
    final List<String> userIds = [uid1, uid2]..sort();
    final query = await _db.collection('chats').where('users', isEqualTo: userIds).limit(1).get();
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

  Future<void> sendMessage(String chatId, MessageModel message) async {
    await _db.collection('chats').doc(chatId).collection('messages').add(message.toMap());
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': message.text.isNotEmpty ? message.text : (message.image != null ? '📷 Image' : ''),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': message.senderId,
      'isSeen': false,
    });
  }

  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _db.collection('chats').doc(chatId).collection('messages').orderBy('createdAt', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => MessageModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<ChatModel>> streamUserChats(String uid) {
    return _db.collection('chats').where('users', arrayContains: uid).orderBy('lastMessageTime', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => ChatModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> markMessageAsSeen(String chatId) async {
    await _db.collection('chats').doc(chatId).update({'isSeen': true});
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
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) => AdModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // ADMIN
  Stream<List<UserModel>> streamAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) => snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
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
    return _db.collection('users').doc(uid).collection('notifications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => AppNotificationModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> markNotificationAsRead(String uid, String notificationId) async {
    await _db.collection('users').doc(uid).collection('notifications').doc(notificationId).update({'isRead': true});
  }

  Future<void> toggleAdmin(String uid, bool isAdmin) async {
    await _db.collection('users').doc(uid).update({'isAdmin': isAdmin});
  }

  Future<void> blockUser(String myUid, String otherUid, bool isBlocking) async {
    if (isBlocking) {
      await _db.collection('users').doc(myUid).update({
        'blockedUsers': FieldValue.arrayUnion([otherUid])
      });
    } else {
      await _db.collection('users').doc(myUid).update({
        'blockedUsers': FieldValue.arrayRemove([otherUid])
      });
    }
  }
}
