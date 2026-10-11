import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class GuideStepTile extends StatelessWidget {
  const GuideStepTile({super.key, required this.step});

  final String step;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 19,
          color: AppColors.rose,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(step, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}
