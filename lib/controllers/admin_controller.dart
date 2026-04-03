import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/ad_model.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class AdminController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<UserModel>> getAllUsers() {
    return _firestoreService.streamAllUsers();
  }

  Future<void> banUser(String uid, bool isBanned) async {
    await _firestoreService.banUser(uid, isBanned);
    notifyListeners();
  }

  Future<void> verifyUser(String uid, bool isVerified) async {
    await _firestoreService.verifyUser(uid, isVerified);
    if (isVerified) {
       final user = await _firestoreService.getUser(uid);
       if (user?.fcmToken != null) {
          await NotificationService.sendNotification(
            targetToken: user!.fcmToken!, 
            targetUid: uid,
            title: 'Account Verified!', 
            body: 'Your profile is now verified with a badge.',
            type: NotificationType.verify,
            relatedId: uid,
          );
       }
    }
    notifyListeners();
  }

  Future<void> approveUser(String uid, bool isApproved) async {
    await _firestoreService.approveUser(uid, isApproved);
    if (isApproved) {
       final user = await _firestoreService.getUser(uid);
       if (user?.fcmToken != null) {
          await NotificationService.sendNotification(
            targetToken: user!.fcmToken!, 
            targetUid: uid,
            title: 'Account Approved!', 
            body: 'Welcome to Developers Zone. Your account has been approved by the admin.',
            type: NotificationType.approve,
            relatedId: uid,
          );
       }
    }
    notifyListeners();
  }

  Future<void> toggleAdmin(String uid, bool isAdmin) async {
    await _firestoreService.toggleAdmin(uid, isAdmin);
    notifyListeners();
  }

  Future<void> addAd(AdModel ad) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.addAd(ad);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAd(AdModel ad) async {
    await _firestoreService.updateAd(ad);
    notifyListeners();
  }

  Future<void> deleteAd(String adId) async {
    await _firestoreService.deleteAd(adId);
    notifyListeners();
  }

  Stream<List<AdModel>> getAds({String? type}) {
    return _firestoreService.streamAds(type: type);
  }
}
