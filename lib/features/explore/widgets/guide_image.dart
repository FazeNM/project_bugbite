import 'package:flutter/material.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../../data/models/bite_guide.dart';

class GuideImage extends StatelessWidget {
  const GuideImage({super.key, required this.media});

  final GuideMedia media;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: AssetCrop(
              asset: media.asset,
              fit: media.fit,
              borderRadius: BorderRadius.zero,
              semanticLabel: media.semanticLabel,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Text(
              media.caption,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    ),
  );
}
