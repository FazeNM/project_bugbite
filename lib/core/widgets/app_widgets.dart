import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/bite_guide.dart';

abstract final class AppAssets {
  static const commonBites = 'assets/images/common_bites_contact_sheet.png';
  static const bugBitePairs = 'assets/images/bug_bite_example_pairs.png';
  static const careContexts = 'assets/images/bite_care_contexts.png';
}

Alignment visualAlignment(BiteVisual visual) => switch (visual) {
  BiteVisual.mosquito => Alignment.topLeft,
  BiteVisual.flea => Alignment.topRight,
  BiteVisual.bedbug => Alignment.bottomLeft,
  BiteVisual.spider => Alignment.bottomRight,
  BiteVisual.tick => Alignment.topLeft,
};

class AssetCrop extends StatelessWidget {
  const AssetCrop({
    super.key,
    required this.asset,
    this.alignment = Alignment.center,
    this.overlay,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.semanticLabel,
  });

  final String asset;
  final Alignment alignment;
  final Widget? overlay;
  final BorderRadius borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Transform.scale(
            scale: 1.7,
            alignment: alignment,
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              semanticLabel: semanticLabel,
            ),
          ),
          ?overlay,
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    ),
  );
}

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

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: <Widget>[
        Icon(icon, color: AppColors.rose, size: 30),
        const SizedBox(height: 10),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}
