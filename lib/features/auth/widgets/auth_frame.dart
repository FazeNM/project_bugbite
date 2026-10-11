import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AuthFrame extends StatelessWidget {
  const AuthFrame({
    super.key,
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

class AuthArtwork extends StatelessWidget {
  const AuthArtwork({super.key, required this.showBack, this.onBack});

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
        const Positioned(
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
