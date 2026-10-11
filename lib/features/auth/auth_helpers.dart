import 'package:flutter/material.dart';

String? validateEmail(String? value) {
  final text = value?.trim() ?? '';
  return text.contains('@') && text.contains('.')
      ? null
      : 'Enter a valid email address.';
}

void showAuthMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
