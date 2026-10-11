import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/navigation_helpers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/bite_guide.dart';
import '../../data/seed/seed_data.dart';
import '../../state/app_controller.dart';
import '../../state/profile_data_controller.dart';
import 'widgets/guide_image.dart';
import 'widgets/guide_step_tile.dart';

class GuideDetailScreen extends ConsumerStatefulWidget {
  const GuideDetailScreen({
    super.key,
    required this.guideId,
    this.initialPhoto = 0,
  });

  final String guideId;
  final int initialPhoto;

  @override
  ConsumerState<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends ConsumerState<GuideDetailScreen> {
  late PageController _pageController;
  int _selectedPage = 0;
  bool _savingGuide = false;

  @override
  void initState() {
    super.initState();
    _selectedPage = _initialPage();
    _pageController = PageController(initialPage: _selectedPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _findGuide(widget.guideId) == null) return;
      ref.read(profileDataProvider.notifier).recordGuideOpened(widget.guideId);
    });
  }

  int _initialPage() {
    final count = _findGuide(widget.guideId)?.gallery.length ?? 0;
    return count == 0 ? 0 : widget.initialPhoto.clamp(0, count - 1);
  }

  @override
  void didUpdateWidget(covariant GuideDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.guideId != widget.guideId ||
        oldWidget.initialPhoto != widget.initialPhoto) {
      _selectedPage = _initialPage();
      final oldController = _pageController;
      _pageController = PageController(initialPage: _selectedPage);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController.dispose();
        if (mounted &&
            oldWidget.guideId != widget.guideId &&
            _findGuide(widget.guideId) != null) {
          ref
              .read(profileDataProvider.notifier)
              .recordGuideOpened(widget.guideId);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markReviewed(BiteGuide guide) async {
    final succeeded = await ref
        .read(profileDataProvider.notifier)
        .markGuideCompleted(guide.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? '${guide.title} marked as reviewed.'
              : 'We could not update your bite history. Please try again.',
        ),
      ),
    );
  }

  Future<void> _toggleSaved(BiteGuide guide) async {
    if (_savingGuide) return;
    setState(() => _savingGuide = true);
    final saved = await ref
        .read(appControllerProvider.notifier)
        .toggleSavedGuide(guide.id);
    if (!mounted) return;
    setState(() => _savingGuide = false);
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This saved-guide change could not be stored. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final guide = _findGuide(widget.guideId);
    if (guide == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => popOrGo(context, '/explore'),
          ),
          title: const Text('Visual guide'),
        ),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: EmptyPanel(
              icon: Icons.search_off_rounded,
              title: 'Guide not found',
              message:
                  'This guide may have moved. Return to Explore to browse the current visual library.',
            ),
          ),
        ),
      );
    }
    final saved = ref
        .watch(appControllerProvider)
        .savedGuideIds
        .contains(guide.id);
    final gallery = guide.gallery;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => popOrGo(context, '/explore'),
        ),
        title: const Text('Visual guide'),
        actions: <Widget>[
          IconButton(
            tooltip: saved ? 'Remove from saved' : 'Save guide',
            icon: Icon(
              saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            ),
            onPressed: _savingGuide ? null : () => _toggleSaved(guide),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                GuidePill(label: guide.kind.label),
                const GuidePill(label: 'Possible match — compare carefully'),
              ],
            ),
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
            const SizedBox(height: 8),
            const Text(
              'Real reference photos: insects, reported bite reactions, and relevant care or surroundings. Skin reactions vary; a visual match cannot confirm the cause.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 260,
              child: PageView(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _selectedPage = value),
                children: gallery
                    .map((media) => GuideImage(media: media))
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              runSpacing: 6,
              children: List<Widget>.generate(
                gallery.length,
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
                child: GuideStepTile(step: step),
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
              onPressed: _savingGuide ? null : () => _toggleSaved(guide),
              icon: Icon(
                saved
                    ? Icons.bookmark_remove_outlined
                    : Icons.bookmark_add_outlined,
              ),
              label: Text(saved ? 'Saved to your profile' : 'Save this guide'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _markReviewed(guide),
              icon: const Icon(Icons.task_alt_rounded),
              label: const Text('Mark guide as reviewed'),
            ),
          ],
        ),
      ),
    );
  }
}

BiteGuide? _findGuide(String id) {
  for (final guide in guides) {
    if (guide.id == id) return guide;
  }
  return null;
}
