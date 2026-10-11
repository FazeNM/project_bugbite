import 'bite_guide.dart';

class BiteHistoryItem {
  const BiteHistoryItem({
    required this.guide,
    required this.lastViewedAt,
    required this.progress,
  });

  final BiteGuide guide;
  final DateTime lastViewedAt;

  /// A value from 0 to 1 representing how much of the guide was reviewed.
  final double progress;

  bool get isComplete => progress >= 1;
}

class ProfileBiteData {
  const ProfileBiteData({
    required this.recentBites,
    required this.recommendations,
  });

  /// Always ordered newest first.
  final List<BiteHistoryItem> recentBites;
  final List<BiteGuide> recommendations;

  /// The newest guide that the user has not finished reviewing.
  BiteHistoryItem? get continueBite {
    for (final item in recentBites) {
      if (!item.isComplete) return item;
    }
    return null;
  }
}
