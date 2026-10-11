import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/models/bite_guide.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.guide});

  final BiteGuide guide;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.push('/guide/${guide.id}'),
      child: Ink(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(22),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: 118,
                height: 128,
                child: AssetCrop(
                  asset: guide.thumbnail.asset,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(21),
                  ),
                  semanticLabel: guide.thumbnail.semanticLabel,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GuidePill(label: guide.category),
                      const SizedBox(height: 7),
                      Text(
                        guide.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        guide.pattern,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.chevron_right_rounded, color: AppColors.rose),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
