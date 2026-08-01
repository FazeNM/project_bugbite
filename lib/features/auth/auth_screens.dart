import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../state/app_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'alex@email.com');
  final _password = TextEditingController(text: 'bitewise');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(appControllerProvider.notifier).signIn(displayName: 'Alex');
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) => _AuthFrame(
    eyebrow: 'Welcome back',
    title: 'Sign in to keep\nlearning together.',
    subtitle:
        'Your visual guides, saved notes, and thoughtful community posts are waiting.',
    artwork: const _AuthArtwork(showBack: false),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _LabeledField(
            label: 'Email address',
            child: TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
                hintText: 'alex@email.com',
              ),
              validator: _emailValidator,
            ),
          ),
          _LabeledField(
            label: 'Password',
            child: TextFormField(
              controller: _password,
              obscureText: _obscurePassword,
              autofillHints: const <String>[AutofillHints.password],
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                hintText: 'Enter your password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) => (value ?? '').length < 6
                  ? 'Enter at least 6 characters.'
                  : null,
            ),
          ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 2,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Checkbox(value: true, onChanged: (_) {}),
                  const Text(
                    'Keep me signed in',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _showSnack(
                  context,
                  'Password recovery is ready to connect to your auth provider.',
                ),
                child: const Text('Forgot password?'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _submit, child: const Text('Sign in')),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: () => _showSnack(
              context,
              'Social sign-in can be connected to your chosen identity provider.',
            ),
            icon: const Icon(Icons.apple),
            label: const Text('Continue with Apple'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 15),
          _AuthSwitch(
            prompt: 'New to BiteWise?',
            action: 'Create an account',
            onTap: () => context.go('/sign-up'),
          ),
        ],
      ),
    ),
  );
}

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _accepted = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate() || !_accepted) {
      if (!_accepted) {
        _showSnack(
          context,
          'Please acknowledge the suggestion-first safety note.',
        );
      }
      return;
    }
    ref.read(appControllerProvider.notifier).signIn(displayName: _name.text);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) => _AuthFrame(
    eyebrow: 'Join BiteWise',
    title: 'Build a calmer\nway to learn.',
    subtitle:
        'Save visual guides, share careful experiences, and keep information in context.',
    artwork: _AuthArtwork(showBack: true, onBack: () => context.go('/sign-in')),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _LabeledField(
            label: 'Your name',
            child: TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const <String>[AutofillHints.name],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline_rounded),
                hintText: 'Alex Morgan',
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Enter your name.' : null,
            ),
          ),
          _LabeledField(
            label: 'Email address',
            child: TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
                hintText: 'alex@email.com',
              ),
              validator: _emailValidator,
            ),
          ),
          _LabeledField(
            label: 'Create password',
            child: TextFormField(
              controller: _password,
              obscureText: true,
              autofillHints: const <String>[AutofillHints.newPassword],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.lock_outline_rounded),
                hintText: 'At least 8 characters',
              ),
              validator: (value) => (value ?? '').length < 8
                  ? 'Use at least 8 characters.'
                  : null,
            ),
          ),
          CheckboxListTile(
            value: _accepted,
            onChanged: (value) => setState(() => _accepted = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
              'I understand BiteWise offers general suggestions and community experiences—not medical diagnoses.',
              style: TextStyle(fontSize: 11, height: 1.35),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _submit, child: const Text('Create account')),
          const SizedBox(height: 15),
          _AuthSwitch(
            prompt: 'Already have an account?',
            action: 'Sign in',
            onTap: () => context.go('/sign-in'),
          ),
        ],
      ),
    ),
  );
}

class _AuthFrame extends StatelessWidget {
  const _AuthFrame({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.artwork,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget artwork;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: <Widget>[
          artwork,
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    eyebrow.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.rose,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(title, style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 9),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AuthArtwork extends StatelessWidget {
  const _AuthArtwork({required this.showBack, this.onBack});

  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Container(
    height: 210,
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: <Color>[Color(0xFFF4D9D0), Color(0xFFD29A9B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Stack(
      children: <Widget>[
        Positioned(
          top: 24,
          left: 24,
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.eco_rounded, color: AppColors.rose),
              ),
              const SizedBox(width: 9),
              const Text(
                'BiteWise',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF573E3D),
                ),
              ),
            ],
          ),
        ),
        if (showBack)
          Positioned(
            top: 22,
            right: 20,
            child: IconButton.filledTonal(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
        Positioned(
          right: 52,
          bottom: 28,
          child: _ArtworkBubble(
            icon: Icons.pest_control_rounded,
            size: 75,
            rotation: -.15,
          ),
        ),
        const Positioned(
          left: 48,
          bottom: 37,
          child: _ArtworkBubble(
            icon: Icons.bug_report_rounded,
            size: 48,
            rotation: .25,
          ),
        ),
      ],
    ),
  );
}

class _ArtworkBubble extends StatelessWidget {
  const _ArtworkBubble({
    required this.icon,
    required this.size,
    required this.rotation,
  });

  final IconData icon;
  final double size;
  final double rotation;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: rotation,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .58),
        borderRadius: BorderRadius.circular(size * .36),
      ),
      child: Icon(icon, color: AppColors.rose, size: size * .4),
    ),
  );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
        const SizedBox(height: 6),
        child,
      ],
    ),
  );
}

class _AuthSwitch extends StatelessWidget {
  const _AuthSwitch({
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          '$prompt ',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
}

String? _emailValidator(String? value) {
  final text = value?.trim() ?? '';
  return text.contains('@') && text.contains('.')
      ? null
      : 'Enter a valid email address.';
}

void _showSnack(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));
