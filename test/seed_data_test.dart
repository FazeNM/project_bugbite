import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_bugbite/data/models/bite_guide.dart';
import 'package:project_bugbite/data/seed/seed_data.dart';

void main() {
  test(
    'Explore skin-photo library is uncropped, unique, and locally bundled',
    () {
      final photos = guides.expand((guide) => guide.bitePhotos).toList();
      expect(photos.length, greaterThanOrEqualTo(18));
      expect(photos.map((photo) => photo.asset).toSet().length, photos.length);
      for (final photo in photos) {
        expect(photo.kind, GuideMediaKind.skin);
        expect(photo.fit, BoxFit.contain);
        expect(photo.asset, startsWith('assets/images/bites/'));
        expect(File(photo.asset).existsSync(), isTrue, reason: photo.asset);
        expect(photo.caption, isNotEmpty);
        expect(photo.semanticLabel, isNotEmpty);
      }
    },
  );

  test('guide library includes a broad set of common insects and flies', () {
    expect(guides, hasLength(13));
    expect(
      guides.map((guide) => guide.id),
      containsAll(<String>[
        'mosquito',
        'flea',
        'bedbug',
        'tick',
        'biting-midge',
        'black-fly',
        'horse-deer-fly',
        'stable-fly',
        'chigger',
        'fire-ant',
        'stinging-insect',
        'head-lice',
      ]),
    );
  });

  test('guide identifiers and local image assets are valid', () {
    final ids = guides.map((guide) => guide.id).toList(growable: false);
    expect(ids.toSet(), hasLength(ids.length));

    for (final guide in guides) {
      expect(guide.gallery, isNotEmpty, reason: '${guide.id} needs media');
      for (final media in guide.gallery) {
        expect(
          File(media.asset).existsSync(),
          isTrue,
          reason: '${guide.id} is missing ${media.asset}',
        );
      }
    }
  });

  test('featured guides and filter tags stay aligned with the UI', () {
    const supportedTags = <String>{
      'red',
      'itchy',
      'raised',
      'single',
      'cluster',
      'lower-leg',
      'line',
      'painful',
      'puncture',
      'blister',
      'tick',
      'swollen',
      'waistline',
      'pustule',
      'stinger',
      'scalp',
    };

    expect(featuredGuides.length, greaterThanOrEqualTo(6));
    for (final guide in guides) {
      expect(
        supportedTags.containsAll(guide.filterTags),
        isTrue,
        reason: '${guide.id} has an unsupported filter tag',
      );
    }
  });
}
