import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// The authentication data the rest of BiteWise needs.
///
/// Keeping Firebase's [User] behind this model makes the authentication layer
/// straightforward to replace with a fake in widget and unit tests.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.isEmailVerified,
  });

  factory AuthUser.fromFirebaseUser(User user) => AuthUser(
    id: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoURL,
    isEmailVerified: user.emailVerified,
  );

  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;
}

/// A user-safe authentication failure.
class AuthServiceException implements Exception {
  const AuthServiceException(this.message, {this.code = 'unknown'});

  factory AuthServiceException.fromFirebase(FirebaseAuthException error) {
    return AuthServiceException(
      _firebaseErrorMessage(error.code),
      code: error.code,
    );
  }

  final String code;
  final String message;

  @override
  String toString() => message;
}

/// Contract used by the UI and Riverpod controller.
///
/// Tests can implement this interface without loading Firebase plugins.
abstract interface class AuthService {
  AuthUser? get currentUser;

  Stream<AuthUser?> authStateChanges();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates the account, sends its verification email, then signs it out.
  Future<void> createAccount({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();

  Future<void> signInWithApple();

  Future<void> sendPasswordReset(String email);

  Future<void> resendEmailVerification({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  bool _googleSignInInitialized = false;

  @override
  AuthUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    return user == null ? null : AuthUser.fromFirebaseUser(user);
  }

  @override
  Stream<AuthUser?> authStateChanges() => _firebaseAuth.userChanges().map(
    (user) => user == null ? null : AuthUser.fromFirebaseUser(user),
  );

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;

      if (user == null) {
        throw const AuthServiceException(
          'We could not finish signing you in. Please try again.',
          code: 'missing-user',
        );
      }
      if (!user.emailVerified) {
        await _firebaseAuth.signOut();
        throw const AuthServiceException(
          'Please verify your email before signing in. Check your inbox for the verification link.',
          code: 'email-not-verified',
        );
      }
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException.fromFirebase(error);
    }
  }

  @override
  Future<void> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    var accountCreated = false;
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      accountCreated = true;
      final user = credential.user;
      if (user == null) {
        throw const AuthServiceException(
          'Your account was created, but setup could not be completed. Try signing in again.',
          code: 'missing-user',
        );
      }

      await user.updateDisplayName(name.trim());
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException.fromFirebase(error);
    } finally {
      // A newly registered email/password account must verify its address before
      // receiving an authenticated BiteWise session.
      if (accountCreated) await _firebaseAuth.signOut();
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await _firebaseAuth.signInWithPopup(GoogleAuthProvider());
        return;
      }

      if (!_googleSignInInitialized) {
        await _googleSignIn.initialize();
        _googleSignInInitialized = true;
      }
      final googleUser = await _googleSignIn.authenticate();
      final googleAuthentication = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuthentication.idToken,
      );
      await _firebaseAuth.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthServiceException(
          'Google sign-in was canceled.',
          code: 'sign-in-canceled',
        );
      }
      throw const AuthServiceException(
        'Google sign-in is unavailable right now. Please try again.',
        code: 'google-sign-in-failed',
      );
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException.fromFirebase(error);
    }
  }

  @override
  Future<void> signInWithApple() async {
    try {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      if (kIsWeb) {
        await _firebaseAuth.signInWithPopup(provider);
      } else {
        await _firebaseAuth.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException.fromFirebase(error);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException.fromFirebase(error);
    }
  }

  @override
  Future<void> resendEmailVerification({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthServiceException(
          'We could not find this account. Please try again.',
          code: 'missing-user',
        );
      }
      if (user.emailVerified) {
        throw const AuthServiceException(
          'This email is already verified. You can sign in now.',
          code: 'email-already-verified',
        );
      }
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException.fromFirebase(error);
    } finally {
      await _firebaseAuth.signOut();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      if (!kIsWeb && _googleSignInInitialized) {
        await _googleSignIn.signOut();
      }
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException.fromFirebase(error);
    } on GoogleSignInException {
      // The Firebase session is already closed. A stale Google session should
      // not prevent the user from signing out of BiteWise.
    }
  }
}

String _firebaseErrorMessage(String code) {
  return switch (code) {
    'invalid-email' => 'Enter a valid email address.',
    'user-disabled' =>
      'This account has been disabled. Contact support for help.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'The email or password is incorrect.',
    'email-already-in-use' =>
      'An account already exists for this email address.',
    'weak-password' => 'Choose a stronger password with at least 6 characters.',
    'operation-not-allowed' => 'This sign-in method has not been enabled yet.',
    'too-many-requests' =>
      'Too many attempts were made. Wait a moment and try again.',
    'network-request-failed' => 'Check your internet connection and try again.',
    'popup-blocked' =>
      'Your browser blocked the sign-in window. Allow pop-ups and try again.',
    'popup-closed-by-user' ||
    'web-context-cancelled' => 'Sign-in was canceled.',
    'account-exists-with-different-credential' =>
      'An account already exists with this email. Use its original sign-in method.',
    'credential-already-in-use' =>
      'This sign-in credential is already connected to another account.',
    'unauthorized-domain' =>
      'This website is not authorized for Firebase sign-in.',
    'requires-recent-login' =>
      'For security, sign in again before making this change.',
    _ => 'Something went wrong while signing you in. Please try again.',
  };
}
