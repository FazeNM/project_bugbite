import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/bite_guide.dart';
import '../../data/seed/seed_data.dart';
import '../../state/app_controller.dart';

class GuideDetailScreen extends ConsumerStatefulWidget {
  const GuideDetailScreen({super.key, required this.guideId});

  final String guideId;

  @override
  ConsumerState<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends ConsumerState<GuideDetailScreen> {
  final PageController _pageController = PageController();
  int _selectedPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guide = guides.firstWhere((item) => item.id == widget.guideId);
    final saved = ref
        .watch(appControllerProvider)
        .savedGuideIds
        .contains(guide.id);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Visual guide'),
        actions: <Widget>[
          IconButton(
            tooltip: saved ? 'Remove from saved' : 'Save guide',
            icon: Icon(
              saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            ),
            onPressed: () => ref
                .read(appControllerProvider.notifier)
                .toggleSavedGuide(guide.id),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: <Widget>[
            const GuidePill(label: 'Possible match — compare carefully'),
            const SizedBox(height: 12),
            Text(
              guide.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              guide.tagline,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.rose),
            ),
            const SizedBox(height: 12),
            Text(guide.summary, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 18),
            SizedBox(
              height: 260,
              child: PageView(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _selectedPage = value),
                children: <Widget>[
                  _GuideImage(
                    asset: AppAssets.bugBitePairs,
                    guide: guide,
                    label: 'Example reaction',
                  ),
                  _GuideImage(
                    asset: AppAssets.commonBites,
                    guide: guide,
                    label: 'Common visual patterns',
                  ),
                  _GuideImage(
                    asset: AppAssets.careContexts,
                    guide: guide,
                    label: 'Care context',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                3,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _selectedPage ? 19 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: index == _selectedPage
                        ? AppColors.rose
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.visibility_outlined,
                        color: AppColors.rose,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Often described as',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    guide.pattern,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            SectionHeader(title: 'Gentle next steps'),
            ...guide.recoverySteps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StepTile(step: step),
              ),
            ),
            SectionHeader(title: 'Keep an eye on'),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.roseSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                guide.watchFor,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 18),
            const SafetyNotice(),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => ref
                  .read(appControllerProvider.notifier)
                  .toggleSavedGuide(guide.id),
              icon: Icon(
                saved
                    ? Icons.bookmark_remove_outlined
                    : Icons.bookmark_add_outlined,
              ),
              label: Text(saved ? 'Saved to your profile' : 'Save this guide'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideImage extends StatelessWidget {
  const _GuideImage({
    required this.asset,
    required this.guide,
    required this.label,
  });

  final String asset;
  final BiteGuide guide;
  final String label;

  @override
  Widget build(BuildContext context) {
    final alignment = asset == AppAssets.careContexts
        ? Alignment.center
        : visualAlignment(guide.visual);
    return AssetCrop(
      asset: asset,
      alignment: alignment,
      borderRadius: BorderRadius.circular(24),
      semanticLabel: '$label for ${guide.title}',
      overlay: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.center,
            colors: <Color>[Color(0x991E1513), Colors.transparent],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step});

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
