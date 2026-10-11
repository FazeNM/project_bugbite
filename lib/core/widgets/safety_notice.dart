import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SafetyNotice extends StatelessWidget {
  const SafetyNotice({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 12 : 14),
    decoration: BoxDecoration(
      color: AppColors.apricot,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.health_and_safety_outlined, color: AppColors.rose, size: 19),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'Suggestions and visual examples are not a diagnosis or 100% certain. Seek urgent care for trouble breathing, faintness, or swelling of the lips, face, or throat.',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: Color(0xFF705451),
            ),
          ),
        ),
      ],
    ),
  );
}
