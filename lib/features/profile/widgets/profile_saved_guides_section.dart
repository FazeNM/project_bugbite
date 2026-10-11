import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/models/bite_guide.dart';

class ProfileSavedGuidesSection extends StatelessWidget {
  const ProfileSavedGuidesSection({
    required this.guides,
    required this.onOpenGuide,
    super.key,
  });

  final List<BiteGuide> guides;
  final ValueChanged<String> onOpenGuide;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const SectionHeader(title: 'Saved visual guides'),
      if (guides.isEmpty)
        const EmptyPanel(
          icon: Icons.bookmark_border_rounded,
          title: 'Nothing saved yet',
          message:
              'Save a visual guide while browsing and it will stay handy here.',
        )
      else
        SizedBox(
          height: 166,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: guides.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final guide = guides[index];
              return SizedBox(
                width: 142,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onOpenGuide(guide.id),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: AssetCrop(
                              asset: guide.thumbnail.asset,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(19),
                              ),
                              semanticLabel: guide.thumbnail.semanticLabel,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            guide.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
    ],
  );
}
