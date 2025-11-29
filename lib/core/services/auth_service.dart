import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Return null/mock if on Linux/Windows where Firebase isn't supported
  FirebaseAuth? get _auth {
    if (defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.windows) {
      return null;
    }
    return FirebaseAuth.instance;
  }
  
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream of auth changes
  Stream<User?> get user {
    if (_auth == null) return Stream.value(null);
    return _auth!.authStateChanges();
  }

  // Get current user
  User? get currentUser => _auth?.currentUser;

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google User credentials
      return await _auth?.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth?.signOut();
  }
}
