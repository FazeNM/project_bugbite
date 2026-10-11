import 'package:flutter/material.dart';

class AssetCrop extends StatelessWidget {
  const AssetCrop({
    super.key,
    required this.asset,
    this.alignment = Alignment.center,
    this.overlay,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.semanticLabel,
    this.fit = BoxFit.cover,
  });

  final String asset;
  final Alignment alignment;
  final Widget? overlay;
  final BorderRadius borderRadius;
  final String? semanticLabel;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            asset,
            fit: fit,
            alignment: alignment,
            semanticLabel: semanticLabel,
            errorBuilder: (context, error, stackTrace) => ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: Icon(Icons.image_not_supported_outlined),
              ),
            ),
          ),
          ?overlay,
        ],
      ),
    );
  }
}
