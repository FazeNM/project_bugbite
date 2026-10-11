import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/models/bite_filters.dart';

/// Informational only: this card never opens a picker or starts an upload.
class PhotoComingSoon extends StatelessWidget {
  const PhotoComingSoon({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.apricot,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(
          Icons.photo_library_outlined,
          color: AppColors.rose,
          size: 28,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    'Photo uploads',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const GuidePill(label: 'Coming soon'),
                ],
              ),
              const SizedBox(height: 8),
              const Text('You can still share a text experience.'),
            ],
          ),
        ),
      ],
    ),
  );
}

class PhotoAttachment extends StatelessWidget {
  const PhotoAttachment({
    super.key,
    required this.bytes,
    required this.previewAsset,
    required this.isLoading,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final String? previewAsset;
  final bool isLoading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    height: 190,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.apricot,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
    child: bytes == null
        ? InkWell(
            onTap: isLoading ? null : onPick,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (previewAsset case final asset?)
                  AssetCrop(
                    asset: asset,
                    borderRadius: BorderRadius.zero,
                    semanticLabel: 'Selected possible-match guide image',
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: previewAsset == null
                        ? AppColors.apricot
                        : const Color(0x990F0A09),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (isLoading)
                          CircularProgressIndicator(
                            color: previewAsset == null
                                ? AppColors.rose
                                : Colors.white,
                          )
                        else
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: previewAsset == null
                                ? AppColors.rose
                                : Colors.white,
                            size: 30,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          isLoading
                              ? 'Opening your photo library…'
                              : 'Add a photo from your library',
                          style: TextStyle(
                            color: previewAsset == null
                                ? AppColors.ink
                                : Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Optional · shared only with this post',
                          style: TextStyle(
                            color: previewAsset == null
                                ? AppColors.muted
                                : const Color(0xFFEEDDD8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        : Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.memory(
                bytes!,
                fit: BoxFit.cover,
                semanticLabel: 'Selected bite photo',
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton.filled(
                  tooltip: 'Remove photo',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
  );
}

class BiteTagSelector extends StatelessWidget {
  const BiteTagSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final void Function(String tag, bool selected) onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: BiteFilters.postOptions
        .map(
          (option) => FilterChip(
            key: ValueKey('post-tag-${option.id}'),
            label: Text(option.label),
            selected: BiteFilters.normalizeAll(selected).contains(option.id),
            onSelected: (value) => onChanged(option.id, value),
          ),
        )
        .toList(),
  );
}
