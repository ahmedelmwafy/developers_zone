import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  AuthController() {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        _currentUser = await _firestoreService.getUser(user.uid);
      } else {
        _currentUser = null;
      }
      notifyListeners();
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

  Future<void> deleteAccount() async {
    if (_currentUser != null) {
      await _firestoreService.deleteUserData(_currentUser!.uid);
      await _authService.deleteAccount();
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<void> blockUser(String otherUid) async {
    if (_currentUser != null) {
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
  }
}
