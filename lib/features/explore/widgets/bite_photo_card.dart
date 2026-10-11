import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/asset_crop.dart';
import '../../../data/models/bite_guide.dart';

class BitePhotoCard extends StatelessWidget {
  const BitePhotoCard({super.key, required this.guide, required this.media});

  final BiteGuide guide;
  final GuideMedia media;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      key: ValueKey('bite-photo-${media.asset}'),
      onTap: () => context.push(
        '/guide/${guide.id}?photo=${guide.gallery.indexOf(media)}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: AssetCrop(
              asset: media.asset,
              fit: BoxFit.contain,
              semanticLabel: media.semanticLabel,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  guide.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 5),
                Text(
                  media.caption,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 9),
                const Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'View example',
                        style: TextStyle(
                          color: AppColors.rose,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.rose,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
