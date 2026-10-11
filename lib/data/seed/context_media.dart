import 'package:flutter/material.dart';

import '../../core/assets/app_assets.dart';
import '../models/bite_guide.dart';

/// Curated context images. Each entry describes what the image actually shows.
/// Source pages and public-domain status are recorded in THIRD_PARTY_NOTICES.md.
abstract final class ContextMedia {
  static const cleanHands = GuideMedia(
    asset: AppAssets.handwashing,
    kind: GuideMediaKind.care,
    caption: 'Care · Clean hands before caring for skin',
    semanticLabel: 'A person washing their hands under running water',
  );

  static const tickRemoval = GuideMedia(
    asset: AppAssets.tickRemoval,
    kind: GuideMediaKind.care,
    caption: 'Care · Grasp close to the skin and pull steadily upward',
    semanticLabel:
        'CDC diagram showing tweezers grasping a tick near the skin, then lifting straight upward',
    fit: BoxFit.contain,
  );

  static const tickOnVegetation = GuideMedia(
    asset: AppAssets.tickOnVegetation,
    kind: GuideMediaKind.exposure,
    caption: 'Exposure · A brown dog tick on vegetation',
    semanticLabel: 'A brown dog tick crawling on a green leaf',
  );

  static const bedBugEvidence = GuideMedia(
    asset: AppAssets.bedBugEvidence,
    kind: GuideMediaKind.exposure,
    caption: 'Exposure · Bed bugs and eggs on a bed',
    semanticLabel: 'Bed bugs and small pale eggs gathered in a bed crevice',
  );

  static const mosquitoWater = GuideMedia(
    asset: AppAssets.mosquitoLarvaeWater,
    kind: GuideMediaKind.exposure,
    caption: 'Exposure · Mosquito larvae in standing water',
    semanticLabel: 'Culex mosquito larvae visible in standing water',
  );

  static const petCheck = GuideMedia(
    asset: AppAssets.dogScratching,
    kind: GuideMediaKind.exposure,
    caption: 'Pet context · Scratching alone does not confirm fleas',
    semanticLabel: 'A beagle scratching itself while sitting on grass',
  );

  static const beeOnFlower = GuideMedia(
    asset: AppAssets.honeyBee,
    caption: 'A closer look at common insects',
    semanticLabel: 'A honey bee visiting a flower',
  );
}
