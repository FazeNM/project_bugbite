import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GuidePill extends StatelessWidget {
  const GuidePill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.roseSoft,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.rose,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    ),
  );
}
