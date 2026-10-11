import 'package:flutter/material.dart';

enum GuideKind { bite, sting, infestation }

enum GuideMediaKind { insect, skin, care, exposure }

extension GuideKindLabel on GuideKind {
  String get label => switch (this) {
    GuideKind.bite => 'Bite guide',
    GuideKind.sting => 'Sting guide',
    GuideKind.infestation => 'Infestation guide',
  };
}

class GuideMedia {
  const GuideMedia({
    required this.asset,
    required this.caption,
    required this.semanticLabel,
    this.fit = BoxFit.cover,
    this.kind = GuideMediaKind.insect,
  });

  final String asset;
  final String caption;
  final String semanticLabel;
  final BoxFit fit;
  final GuideMediaKind kind;
}

class BiteGuide {
  const BiteGuide({
    required this.id,
    required this.title,
    required this.tagline,
    required this.summary,
    required this.pattern,
    required this.recoverySteps,
    required this.watchFor,
    required this.filterTags,
    required this.category,
    required this.kind,
    required this.gallery,
    required this.icon,
    this.isFeatured = false,
  });

  final String id;
  final String title;
  final String tagline;
  final String summary;
  final String pattern;
  final List<String> recoverySteps;
  final String watchFor;
  final Set<String> filterTags;
  final String category;
  final GuideKind kind;
  final List<GuideMedia> gallery;
  final IconData icon;
  final bool isFeatured;

  GuideMedia get thumbnail => gallery.first;

  List<GuideMedia> get bitePhotos => List<GuideMedia>.unmodifiable(
    gallery.where((media) => media.kind == GuideMediaKind.skin),
  );
}
