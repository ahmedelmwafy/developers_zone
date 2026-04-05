import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth/firebase_auth.dart'
    show UserCredential, GoogleAuthProvider, OAuthCredential, OAuthProvider;

class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  firebase_auth.User? get currentUser => _auth.currentUser;

  Future<UserCredential?> registerWithEmail(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      // ignore: avoid_print
      print('Registration Error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> loginWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      // ignore: avoid_print
      print('Login Error: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      // ignore: avoid_print
      print('Password Reset Error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Ensure GoogleSignIn is initialized with serverClientId for Android in v7.0.0+
      // You can find your Web Client ID in the Google Cloud Console:
      // Credentials -> OAuth 2.0 Client IDs -> Web client (auto-created by Google Service)
      await _googleSignIn.initialize();

      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final String idToken = googleAuth.idToken ?? '';

      // In v7.0.0+, accessToken is obtained via authorizationClient
      final authorization = await googleUser.authorizationClient
          .authorizeScopes(['email', 'profile']);
      final String accessToken = authorization.accessToken;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      // ignore: avoid_print
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGitHub() async {
    try {
      final OAuthProvider githubProvider = OAuthProvider('github.com');
      return await _auth.signInWithProvider(githubProvider);
    } catch (e) {
      // ignore: avoid_print
      print('GitHub Sign-In Error: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      // ignore: avoid_print
      print('Apple Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Update Password Error: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Delete Account Error: $e');
      rethrow;
    }
  }
}
