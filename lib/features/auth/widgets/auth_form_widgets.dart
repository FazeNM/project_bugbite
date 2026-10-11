import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AuthLabeledField extends StatelessWidget {
  const AuthLabeledField({super.key, required this.label, required this.child});

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

class AuthModeSwitch extends StatelessWidget {
  const AuthModeSwitch({
    super.key,
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
