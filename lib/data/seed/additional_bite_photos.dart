import 'package:flutter/material.dart';

import '../../core/assets/app_assets.dart';
import '../models/bite_guide.dart';

/// Individually sourced skin photographs, never generated or inferred matches.
/// Provenance is recorded in docs/BITE_PHOTO_SOURCES_A.md and _B.md.
abstract final class AdditionalBitePhotos {
  static const stings = <GuideMedia>[
    GuideMedia(
      asset: AppAssets.beeStingForearm,
      kind: GuideMediaKind.skin,
      fit: BoxFit.contain,
      caption: 'Reported bee sting · Forearm reaction after two days',
      semanticLabel:
          'A forearm with pink-red skin and a small central mark, reported as a bee-sting reaction after two days',
    ),
    GuideMedia(
      asset: AppAssets.yellowJacketSwelling,
      kind: GuideMediaKind.skin,
      fit: BoxFit.contain,
      caption: 'Hand swelling after a yellow-jacket sting · CDC',
      semanticLabel:
          'Both hands shown for comparison, with one hand visibly swollen 24 hours after a documented yellow-jacket sting',
    ),
    GuideMedia(
      asset: AppAssets.waspStingThigh,
      kind: GuideMediaKind.skin,
      fit: BoxFit.contain,
      caption: 'Reported wasp sting · Redness after two days',
      semanticLabel:
          'A thigh with a broad red area, reported by the photographer as a reaction two days after a wasp sting',
    ),
  ];

  static const tick = <GuideMedia>[
    GuideMedia(
      asset: AppAssets.tickAttached,
      kind: GuideMediaKind.skin,
      fit: BoxFit.contain,
      caption: 'Attachment example · A small tick on skin',
      semanticLabel:
          'A small dark tick attached to hairy skin with a slight pink area immediately around it',
    ),
    GuideMedia(
      asset: AppAssets.tickOnLeg,
      kind: GuideMediaKind.skin,
      fit: BoxFit.contain,
      caption: 'Attachment example · An engorged tick on a leg',
      semanticLabel:
          'An engorged gray tick attached to skin, with redness immediately around the attachment point',
    ),
  ];

  static const mosquito = <GuideMedia>[
    GuideMedia(
      asset: AppAssets.mosquitoForearm,
      kind: GuideMediaKind.skin,
      fit: BoxFit.contain,
      caption: 'Mosquito reaction on a forearm · CDC',
      semanticLabel:
          'A small pink bump on a forearm, circled in the original CDC photograph',
    ),
    GuideMedia(
      asset: AppAssets.mosquitoThreeBites,
      kind: GuideMediaKind.skin,
      fit: BoxFit.contain,
      caption: 'Three mosquito reactions · CDC',
      semanticLabel:
          'Three adjacent raised pink mosquito-bite reactions on a forearm',
    ),
    GuideMedia(
      asset: AppAssets.mosquitoRedness,
      kind: GuideMediaKind.skin,
      fit: BoxFit.contain,
      caption: 'Redness around a mosquito bite · CDC',
      semanticLabel:
          'Close view of reddened skin around a mosquito-bite reaction on a forearm',
    ),
  ];

  static const chigger = <GuideMedia>[
    GuideMedia(
      asset: AppAssets.chiggerFoot,
      kind: GuideMediaKind.skin,
      fit: BoxFit.contain,
      caption: 'Reported chigger bites on a foot',
      semanticLabel:
          'Scattered reddish marks on the side of a foot and around the ankle',
    ),
    GuideMedia(
      asset: AppAssets.chiggerMagnified,
      kind: GuideMediaKind.skin,
      fit: BoxFit.contain,
      caption: 'Reported chigger reactions · Magnified',
      semanticLabel:
          'Magnified reddish ankle reactions with the original 3.0 millimeter scale label',
    ),
  ];

  static const bedBug = <GuideMedia>[
    GuideMedia(
      asset: AppAssets.bedBugJaw,
      kind: GuideMediaKind.skin,
      fit: BoxFit.contain,
      caption: 'Reported bed bug reactions on the jaw',
      semanticLabel:
          'Pink-red raised reactions along the cheek, jaw, and side of the neck',
    ),
    GuideMedia(
      asset: AppAssets.bedBugLeg,
      kind: GuideMediaKind.skin,
      fit: BoxFit.contain,
      caption: 'Reported bed bug bites on a leg',
      semanticLabel: 'Several pink-red raised marks clustered on a lower leg',
    ),
    GuideMedia(
      asset: AppAssets.bedBugThigh,
      kind: GuideMediaKind.skin,
      fit: BoxFit.contain,
      caption: 'Reported bed bug bites on a thigh',
      semanticLabel: 'A small cluster of red marks on a thigh',
    ),
  ];
}
