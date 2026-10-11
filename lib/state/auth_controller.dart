import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>(
  (ref) => FirebaseAuthService(),
);

final authStateChangesProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

/// The latest authenticated user, including the synchronous Firebase value
/// while the first auth-state event is still loading.
final currentUserProvider = Provider<AuthUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return switch (authState) {
    AsyncData(:final value) => value,
    _ => ref.watch(authServiceProvider).currentUser,
  };
});

class AuthActionState {
  const AuthActionState({
    this.isLoading = false,
    this.errorMessage,
    this.errorCode,
    this.infoMessage,
  });

  final bool isLoading;
  final String? errorMessage;
  final String? errorCode;
  final String? infoMessage;
}

class AuthController extends Notifier<AuthActionState> {
  AuthService get _service => ref.read(authServiceProvider);

  @override
  AuthActionState build() => const AuthActionState();

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) {
    if (email.trim().isEmpty || password.isEmpty) {
      return _validationFailure('Enter your email and password.');
    }
    return _run(
      () => _service.signInWithEmail(email: email, password: password),
    );
  }

  Future<bool> createAccount({
    required String name,
    required String email,
    required String password,
  }) {
    if (name.trim().isEmpty) {
      return _validationFailure('Enter your name.');
    }
    if (email.trim().isEmpty || password.isEmpty) {
      return _validationFailure('Enter your email and password.');
    }
    return _run(
      () =>
          _service.createAccount(name: name, email: email, password: password),
      successMessage:
          'Verification email sent. Verify your address before signing in.',
    );
  }

  Future<bool> signInWithGoogle() => _run(_service.signInWithGoogle);

  Future<bool> signInWithApple() => _run(_service.signInWithApple);

  Future<bool> sendPasswordReset(String email) {
    if (email.trim().isEmpty) {
      return _validationFailure(
        'Enter your email address to reset your password.',
      );
    }
    return _run(
      () => _service.sendPasswordReset(email),
      successMessage: 'Password reset email sent. Check your inbox.',
    );
  }

  Future<bool> resendEmailVerification({
    required String email,
    required String password,
  }) {
    if (email.trim().isEmpty || password.isEmpty) {
      return _validationFailure(
        'Enter your email and password to resend verification.',
      );
    }
    return _run(
      () => _service.resendEmailVerification(email: email, password: password),
      successMessage:
          'A new verification email was sent. Check spam or junk folders too.',
    );
  }

  Future<bool> signOut() => _run(_service.signOut);

  void clearMessages() {
    if (state.errorMessage == null && state.infoMessage == null) return;
    state = const AuthActionState();
  }

  Future<bool> _validationFailure(String message) async {
    state = AuthActionState(errorMessage: message);
    return false;
  }

  Future<bool> _run(
    Future<void> Function() operation, {
    String? successMessage,
  }) async {
    if (state.isLoading) return false;
    state = const AuthActionState(isLoading: true);
    try {
      await operation();
      state = AuthActionState(infoMessage: successMessage);
      return true;
    } on AuthServiceException catch (error) {
      state = AuthActionState(
        errorMessage: error.message,
        errorCode: error.code,
      );
      return false;
    } catch (_) {
      state = const AuthActionState(
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthActionState>(AuthController.new);
