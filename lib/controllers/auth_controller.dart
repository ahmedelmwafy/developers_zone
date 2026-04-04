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

  AuthController() {
    _authService.authStateChanges.listen((user) async {
      try {
        if (user != null) {
          _currentUser = await _firestoreService.getUser(user.uid);
        } else {
          _currentUser = null;
        }
      } catch (e) {
        _currentUser = null;
      } finally {
        _isInitialized = true;
        notifyListeners();
      }
    });
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
        _currentUser = newUser;
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
          _currentUser = newUser;
        } else {
          _currentUser = existingUser;
        }
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
    final updatedList = List<String>.from(_currentUser!.blockedUsers);
    if (isBlocking) {
      updatedList.add(otherUid);
    } else {
      updatedList.remove(otherUid);
    }
    _currentUser = _currentUser!.copyWith(blockedUsers: updatedList);
    notifyListeners();
  }

  Future<void> unblockUser(String otherUid) async {
    if (_currentUser == null) return;
    await _firestoreService.blockUser(_currentUser!.uid, otherUid, false);
    final updatedList = List<String>.from(_currentUser!.blockedUsers)..remove(otherUid);
    _currentUser = _currentUser!.copyWith(blockedUsers: updatedList);
    notifyListeners();
  }

  Future<void> followUser(String targetUid) async {
    if (_currentUser == null) return;
    await _firestoreService.followUser(_currentUser!.uid, targetUid);
    
    // Trigger Notification
    final target = await _firestoreService.getUser(targetUid);
    if (target?.fcmToken != null) {
      await NotificationService.sendNotification(
        targetToken: target!.fcmToken!, 
        targetUid: targetUid,
        title: 'New Follower!', 
        body: '${_currentUser!.name} followed you.',
        type: NotificationType.follow,
        relatedId: _currentUser!.uid,
      );
    }

    final updatedFollowing = List<String>.from(_currentUser!.following)..add(targetUid);
    _currentUser = _currentUser!.copyWith(following: updatedFollowing);
    notifyListeners();
  }

  Future<void> unfollowUser(String targetUid) async {
    if (_currentUser == null) return;
    await _firestoreService.unfollowUser(_currentUser!.uid, targetUid);
    final updatedFollowing = List<String>.from(_currentUser!.following)..remove(targetUid);
    _currentUser = _currentUser!.copyWith(following: updatedFollowing);
    notifyListeners();
  }

  bool isFollowing(String uid) => _currentUser?.following.contains(uid) ?? false;

  bool isBlocked(String uid) => _currentUser?.blockedUsers.contains(uid) ?? false;

  Future<List<UserModel>> searchUsers(String query) async {
    return await _firestoreService.searchUsers(query);
  }

  Future<List<UserModel>> getBlockedUsers() async {
    if (_currentUser == null) return [];
    return await _firestoreService.getBlockedUsers(_currentUser!.uid);
  }

  Future<void> updateProfile(UserModel newUser) async {
    await _firestoreService.updateUser(newUser);
    _currentUser = newUser;
    notifyListeners();
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
    int totalFields = 10;

    // Identity (2)
    if (_currentUser!.name.isNotEmpty) completedFields++;
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
}
