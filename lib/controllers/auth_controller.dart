import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  StreamSubscription<UserModel?>? _userSubscription;

  AuthController() {
    _authService.authStateChanges.listen((user) {
      _userSubscription?.cancel();
      if (user != null) {
        _userSubscription = _firestoreService.streamUser(user.uid).listen((userData) {
          _currentUser = userData;
          _isInitialized = true;
          notifyListeners();
        });
        // Auto-sync FCM Node
        updateFCMToken();
      } else {
        _currentUser = null;
        _isInitialized = true;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  Future<void> register(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await _authService.registerWithEmail(email, password);
      if (credential != null && credential.user != null) {
        final newUser = UserModel(
          uid: credential.user!.uid,
          name: name,
          email: email,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUser(newUser);
        await _firestoreService.autoFollowFeaturedUsers(newUser.uid);
        await _syncSubscriptions(newUser);
        _currentUser = newUser;
        updateFCMToken();

        // Notify Admins about new registration
        await NotificationService.notifyAdmins(
          title: 'ACCESS_REQUEST_INITIAL',
          body: 'A new nodal identity ($name) has registered. Initial security clearance required.',
          relatedId: newUser.uid,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await _authService.loginWithEmail(email, password);
      if (credential != null && credential.user != null) {
        _currentUser = await _firestoreService.getUser(credential.user!.uid);
        updateFCMToken();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGitHub() async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await _authService.signInWithGitHub();
      if (credential != null && credential.user != null) {
        final existingUser = await _firestoreService.getUser(credential.user!.uid);
        
        // Extract GitHub specific profile data
        final githubProfile = credential.additionalUserInfo?.profile ?? {};
        final bio = githubProfile['bio'] ?? '';
        final company = githubProfile['company'] ?? '';
        final location = githubProfile['location'] ?? ''; // e.g. "San Francisco, CA"
        
        String city = '';
        String country = '';
        if (location.contains(',')) {
          final parts = location.split(',');
          city = parts.first.trim();
          country = parts.last.trim();
        } else {
          city = location;
        }

        if (existingUser == null) {
          final newUser = UserModel(
            uid: credential.user!.uid,
            name: credential.user!.displayName ?? githubProfile['login'] ?? 'Developer',
            email: credential.user!.email ?? '',
            profileImage: credential.user!.photoURL ?? '',
            bio: bio,
            position: company,
            city: city,
            country: country,
            createdAt: DateTime.now(),
          );
          await _firestoreService.createUser(newUser);
          await _firestoreService.autoFollowFeaturedUsers(newUser.uid);
          _currentUser = newUser;
        } else {
          // Optional: Update existing user with latest GitHub data if desired
           _currentUser = existingUser;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential != null && credential.user != null) {
        final existingUser = await _firestoreService.getUser(credential.user!.uid);
        if (existingUser == null) {
          final newUser = UserModel(
            uid: credential.user!.uid,
            name: credential.user!.displayName ?? 'Developer',
            email: credential.user!.email ?? '',
            profileImage: credential.user!.photoURL ?? '',
            createdAt: DateTime.now(),
          );
          await _firestoreService.createUser(newUser);
          await _firestoreService.autoFollowFeaturedUsers(newUser.uid);
          await _syncSubscriptions(newUser);
          _currentUser = newUser;
        } else {
          _currentUser = existingUser;
        }
        updateFCMToken();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithApple() async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await _authService.signInWithApple();
      if (credential != null && credential.user != null) {
        final existingUser = await _firestoreService.getUser(credential.user!.uid);
        if (existingUser == null) {
          final newUser = UserModel(
            uid: credential.user!.uid,
            name: credential.user!.displayName ?? 'Developer',
            email: credential.user!.email ?? '',
            profileImage: credential.user!.photoURL ?? '',
            createdAt: DateTime.now(),
          );
          await _firestoreService.createUser(newUser);
          await _firestoreService.autoFollowFeaturedUsers(newUser.uid);
          await _syncSubscriptions(newUser);
          _currentUser = newUser;
        } else {
          _currentUser = existingUser;
        }
        updateFCMToken();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updatePassword(String newPassword) async {
    await _authService.updatePassword(newPassword);
  }

  Future<void> deleteAccount() async {
    if (_currentUser != null) {
      await _firestoreService.deleteUserData(_currentUser!.uid);
      await _authService.deleteAccount();
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.sendPasswordReset(email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> blockUser(String otherUid) async {
    if (_currentUser == null) return;
    final isBlocking = !_currentUser!.blockedUsers.contains(otherUid);
    await _firestoreService.blockUser(_currentUser!.uid, otherUid, isBlocking);
    // Note: Local state will be updated via the stream listener
  }

  Future<void> unblockUser(String otherUid) async {
    if (_currentUser == null) return;
    await _firestoreService.blockUser(_currentUser!.uid, otherUid, false);
  }

  Future<void> followUser(String targetUid) async {
    if (_currentUser == null) return;
    await _firestoreService.followUser(_currentUser!.uid, targetUid);
    
    // Trigger Notification Manifest
    final target = await _firestoreService.getUser(targetUid);
    await NotificationService.sendNotification(
      targetToken: target?.fcmToken, 
      targetUid: targetUid,
      title: 'New Follower!', 
      body: '${_currentUser!.name} followed you.',
      type: NotificationType.follow,
      relatedId: _currentUser!.uid,
    );
  }

  Future<void> unfollowUser(String targetUid) async {
    if (_currentUser == null) return;
    await _firestoreService.unfollowUser(_currentUser!.uid, targetUid);
  }

  bool isFollowing(String uid) => _currentUser?.following.contains(uid) ?? false;

  bool isBlocked(String uid) => _currentUser?.blockedUsers.contains(uid) ?? false;

  Future<List<UserModel>> searchUsers(String query, {int limit = 50}) async {
    return await _firestoreService.searchUsers(query, limit: limit);
  }

  Future<List<UserModel>> getBlockedUsers() async {
    if (_currentUser == null) return [];
    return await _firestoreService.getBlockedUsers(_currentUser!.uid);
  }

  Future<void> updateProfile(UserModel newUser) async {
    final wasApproved = _currentUser?.isApproved ?? false;
    final wasComplete = isProfileComplete;
    
    await _firestoreService.updateUser(newUser);
    // Local state will be updated via the stream listener
    
    // If profile is now complete and user is not yet approved, notify admins
    if (!wasApproved && !newUser.isApproved && isProfileComplete && !wasComplete) {
       await NotificationService.notifyAdmins(
          title: 'MANIFEST_COMPLETE',
          body: '${newUser.name} has finalized their tech transcript. Ready for final clearance.',
          relatedId: newUser.uid,
        );
    }
  }

  Future<bool> checkUsernameAvailable(String username) async {
    return await _firestoreService.checkUsernameAvailable(username, excludeUid: currentUser?.uid);
  }

  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    final updatedUser = await _firestoreService.getUser(_currentUser!.uid);
    if (updatedUser != null) {
      _currentUser = updatedUser;
      notifyListeners();
    }
  }

  double get profileCompletionPercentage {
    if (_currentUser == null) return 0.0;
    int completedFields = 0;
    int totalFields = 11;

    // Identity (3)
    if (_currentUser!.name.isNotEmpty) completedFields++;
    if (_currentUser!.username.isNotEmpty) completedFields++;
    if (_currentUser!.profileImage.isNotEmpty) completedFields++;

    // Tech Profile (3)
    if (_currentUser!.bio.isNotEmpty) completedFields++;
    if (_currentUser!.position.isNotEmpty) completedFields++;
    if (_currentUser!.company.isNotEmpty) completedFields++;

    // Location (2)
    if (_currentUser!.city.isNotEmpty) completedFields++;
    if (_currentUser!.country.isNotEmpty) completedFields++;

    // Social Nodes (3)
    if (_currentUser!.socialLinks != null) {
      if (_currentUser!.socialLinks!['github']?.isNotEmpty == true) {
        completedFields++;
      }
      if (_currentUser!.socialLinks!['linkedin']?.isNotEmpty == true) {
        completedFields++;
      }
      if (_currentUser!.socialLinks!['portfolio']?.isNotEmpty == true) {
        completedFields++;
      }
    }

    return (completedFields / totalFields);
  }

  bool get isProfileComplete => profileCompletionPercentage >= 0.8;

  Future<void> updateFCMToken() async {
    if (_currentUser == null) return;
    try {
      final token = await NotificationService.getToken();
      if (token != null) {
        await _firestoreService.updateFCMToken(_currentUser!.uid, token);
        _currentUser = _currentUser!.copyWith(fcmToken: token);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating FCM Token: $e');
    }
  }
  Future<void> _syncSubscriptions(UserModel user) async {
    for (final topic in user.subscribedTopics) {
      await NotificationService.subscribeToTopic(topic);
    }
  }

  Future<void> toggleTopicSubscription(String topic, bool subscribe) async {
    if (_currentUser == null) return;

    final updatedTopics = List<String>.from(_currentUser!.subscribedTopics);
    if (subscribe) {
      if (!updatedTopics.contains(topic)) {
        updatedTopics.add(topic);
        await NotificationService.subscribeToTopic(topic);
      }
    } else {
      updatedTopics.remove(topic);
      await NotificationService.unsubscribeFromTopic(topic);
    }

    _currentUser = _currentUser!.copyWith(subscribedTopics: updatedTopics);
    await _firestoreService.updateUser(_currentUser!);
    notifyListeners();
  }
}
