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

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  static const _enableAppleSignIn = bool.fromEnvironment(
    'ENABLE_APPLE_SIGN_IN',
  );
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  bool _accepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  bool _hasAcceptedSafetyNote() {
    if (_accepted) return true;
    showAuthMessage(
      context,
      'Please acknowledge the suggestion-first safety note.',
    );
    return false;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || !_hasAcceptedSafetyNote()) {
      return;
    }

    final didCreateAccount = await ref
        .read(authControllerProvider.notifier)
        .createAccount(
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
    if (!mounted || !didCreateAccount) return;

    TextInput.finishAutofillContext();
    await _showVerificationSent();
  }

  Future<void> _signUpWithGoogle() async {
    if (!_hasAcceptedSafetyNote()) return;
    FocusScope.of(context).unfocus();
    final didSignIn = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();
    if (mounted && didSignIn) context.go('/home');
  }

  Future<void> _signUpWithApple() async {
    if (!_hasAcceptedSafetyNote()) return;
    FocusScope.of(context).unfocus();
    final didSignIn = await ref
        .read(authControllerProvider.notifier)
        .signInWithApple();
    if (mounted && didSignIn) context.go('/home');
  }

  Future<void> _showVerificationSent() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.mark_email_read_outlined, color: AppColors.safe),
        title: const Text('Check your email'),
        content: Text(
          'We sent a verification link to ${_email.text.trim()}. '
          'Verify your address before signing in.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Continue to sign in'),
          ),
        ],
      ),
    );
    if (mounted) context.go('/sign-in');
  }

  void _returnToSignIn() {
    ref.read(authControllerProvider.notifier).clearMessages();
    context.go('/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return AuthFrame(
      eyebrow: 'Join BiteWise',
      title: 'Build a calmer\nway to learn.',
      subtitle:
          'Save visual guides, share careful experiences, and keep information in context.',
      artwork: AuthArtwork(
        showBack: true,
        onBack: authState.isLoading ? null : _returnToSignIn,
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (authState.errorMessage != null)
                AuthFeedback(message: authState.errorMessage!, isError: true),
              if (authState.infoMessage != null)
                AuthFeedback(message: authState.infoMessage!),
              AuthLabeledField(
                label: 'Your name',
                child: TextFormField(
                  controller: _name,
                  enabled: !authState.isLoading,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.name],
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    hintText: 'Alex Morgan',
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Enter your name.' : null,
                  onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                ),
              ),
              AuthLabeledField(
                label: 'Email address',
                child: TextFormField(
                  controller: _email,
                  focusNode: _emailFocus,
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
                label: 'Create password',
                child: TextFormField(
                  controller: _password,
                  focusNode: _passwordFocus,
                  enabled: !authState.isLoading,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    hintText: 'At least 8 characters',
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
                  validator: (value) => (value ?? '').length < 8
                      ? 'Use at least 8 characters.'
                      : null,
                  onFieldSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                ),
              ),
              AuthLabeledField(
                label: 'Confirm password',
                child: TextFormField(
                  controller: _confirmPassword,
                  focusNode: _confirmPasswordFocus,
                  enabled: !authState.isLoading,
                  obscureText: _obscureConfirmation,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    hintText: 'Enter it once more',
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirmation
                          ? 'Show password confirmation'
                          : 'Hide password confirmation',
                      icon: Icon(
                        _obscureConfirmation
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: authState.isLoading
                          ? null
                          : () => setState(
                              () =>
                                  _obscureConfirmation = !_obscureConfirmation,
                            ),
                    ),
                  ),
                  validator: (value) => value != _password.text
                      ? 'Passwords do not match.'
                      : null,
                  onFieldSubmitted: (_) {
                    if (!authState.isLoading) _submit();
                  },
                ),
              ),
              CheckboxListTile(
                value: _accepted,
                onChanged: authState.isLoading
                    ? null
                    : (value) => setState(() => _accepted = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text(
                  'I understand BiteWise offers general suggestions and community experiences, not medical diagnoses.',
                  style: TextStyle(fontSize: 11, height: 1.35),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: authState.isLoading ? null : _submit,
                child: authState.isLoading
                    ? const AuthLoadingLabel(label: 'Creating account...')
                    : const Text('Create account'),
              ),
              const SizedBox(height: 18),
              const AuthMethodDivider(),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: authState.isLoading ? null : _signUpWithGoogle,
                icon: const GoogleAuthMark(),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              if (_enableAppleSignIn) ...<Widget>[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: authState.isLoading ? null : _signUpWithApple,
                  icon: const Icon(Icons.apple),
                  label: const Text('Continue with Apple'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
              const SizedBox(height: 15),
              AuthModeSwitch(
                prompt: 'Already have an account?',
                action: 'Sign in',
                onTap: authState.isLoading ? () {} : _returnToSignIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
