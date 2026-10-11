import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../state/auth_controller.dart';
import 'auth_helpers.dart';
import 'widgets/auth_form_widgets.dart';
import 'widgets/auth_frame.dart';
import 'widgets/auth_shared_widgets.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  static const _enableAppleSignIn = bool.fromEnvironment(
    'ENABLE_APPLE_SIGN_IN',
  );
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final didSignIn = await ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(email: _email.text, password: _password.text);
    if (!mounted || !didSignIn) return;

    TextInput.finishAutofillContext();
    context.go('/home');
  }

  Future<void> _sendPasswordReset() async {
    FocusScope.of(context).unfocus();
    final validationMessage = validateEmail(_email.text);
    if (validationMessage != null) {
      showAuthMessage(
        context,
        'Enter your email address first, then choose Forgot password.',
      );
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_email.text);
  }

  Future<void> _resendVerification() async {
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .resendEmailVerification(email: _email.text, password: _password.text);
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    final didSignIn = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();
    if (mounted && didSignIn) context.go('/home');
  }

  Future<void> _signInWithApple() async {
    FocusScope.of(context).unfocus();
    final didSignIn = await ref
        .read(authControllerProvider.notifier)
        .signInWithApple();
    if (mounted && didSignIn) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AuthFrame(
      eyebrow: 'Welcome back',
      title: 'Sign in to keep\nlearning together.',
      subtitle:
          'Your visual guides, saved notes, and thoughtful community posts are waiting.',
      artwork: const AuthArtwork(showBack: false),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (authState.errorMessage != null)
                AuthFeedback(message: authState.errorMessage!, isError: true),
              if (authState.errorCode == 'email-not-verified')
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: authState.isLoading ? null : _resendVerification,
                    icon: const Icon(Icons.mark_email_unread_outlined),
                    label: const Text('Resend verification email'),
                  ),
                ),
              if (authState.infoMessage != null)
                AuthFeedback(message: authState.infoMessage!),
              AuthLabeledField(
                label: 'Email address',
                child: TextFormField(
                  controller: _email,
                  enabled: !authState.isLoading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.email],
                  autocorrect: false,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'you@example.com',
                  ),
                  validator: validateEmail,
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
              ),
              AuthLabeledField(
                label: 'Password',
                child: TextFormField(
                  controller: _password,
                  focusNode: _passwordFocus,
                  enabled: !authState.isLoading,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.password],
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    hintText: 'Enter your password',
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: authState.isLoading
                          ? null
                          : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                    ),
                  ),
                  validator: (value) => (value ?? '').length < 6
                      ? 'Enter at least 6 characters.'
                      : null,
                  onFieldSubmitted: (_) {
                    if (!authState.isLoading) _submit();
                  },
                ),
              ),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 2,
                children: <Widget>[
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 15,
                        color: AppColors.safe,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Secure sign-in with Firebase',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: authState.isLoading ? null : _sendPasswordReset,
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: authState.isLoading ? null : _submit,
                child: authState.isLoading
                    ? const AuthLoadingLabel(label: 'Signing in…')
                    : const Text('Sign in'),
              ),
              const SizedBox(height: 18),
              const AuthMethodDivider(),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: authState.isLoading ? null : _signInWithGoogle,
                icon: const GoogleAuthMark(),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              if (_enableAppleSignIn) ...<Widget>[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: authState.isLoading ? null : _signInWithApple,
                  icon: const Icon(Icons.apple),
                  label: const Text('Continue with Apple'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
              const SizedBox(height: 15),
              AuthModeSwitch(
                prompt: 'New to BiteWise?',
                action: 'Create an account',
                onTap: authState.isLoading
                    ? () {}
                    : () {
                        ref
                            .read(authControllerProvider.notifier)
                            .clearMessages();
                        context.go('/sign-up');
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
