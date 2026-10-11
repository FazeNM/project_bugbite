import 'package:flutter/material.dart';

class ProfileSignOutButton extends StatelessWidget {
  const ProfileSignOutButton({
    required this.isLoading,
    required this.onPressed,
    super.key,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: isLoading ? null : onPressed,
    icon: isLoading
        ? const SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.logout_rounded),
    label: Text(isLoading ? 'Signing out...' : 'Sign out'),
  );
}
