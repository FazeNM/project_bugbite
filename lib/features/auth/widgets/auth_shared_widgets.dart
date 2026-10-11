import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AuthFeedback extends StatelessWidget {
  const AuthFeedback({super.key, required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isError
          ? Theme.of(context).colorScheme.errorContainer
          : const Color(0xFFEAF4EF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
          size: 19,
          color: isError
              ? Theme.of(context).colorScheme.onErrorContainer
              : AppColors.safe,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isError
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class AuthLoadingLabel extends StatelessWidget {
  const AuthLoadingLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
      const SizedBox(width: 10),
      Text(label),
    ],
  );
}

class AuthMethodDivider extends StatelessWidget {
  const AuthMethodDivider({super.key});

  @override
  Widget build(BuildContext context) => const Row(
    children: <Widget>[
      Expanded(child: Divider(color: AppColors.border)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'OR',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ),
      Expanded(child: Divider(color: AppColors.border)),
    ],
  );
}

class GoogleAuthMark extends StatelessWidget {
  const GoogleAuthMark({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 21,
    height: 21,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.border),
    ),
    child: const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}
