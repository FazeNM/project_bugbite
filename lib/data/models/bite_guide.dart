import 'package:flutter/material.dart';

enum BiteVisual { mosquito, flea, bedbug, spider, tick }

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
    required this.visual,
    required this.icon,
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
  final BiteVisual visual;
  final IconData icon;
}
