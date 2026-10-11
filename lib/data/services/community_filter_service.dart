import '../models/bite_filters.dart';
import '../models/community_post.dart';

/// Returns posts whose author explicitly selected every requested observation.
/// A linked guide is never evidence that a post has a symptom.
List<CommunityPost> filterCommunityPosts(
  Iterable<CommunityPost> posts,
  Iterable<String> selectedTags,
) {
  final selected = BiteFilters.normalizeAll(selectedTags);
  final matches = posts.where((post) {
    final observed = BiteFilters.normalizeAll(post.tags);
    return selected.every(observed.contains);
  }).toList();
  matches.sort((left, right) {
    final byDate = right.createdAt.compareTo(left.createdAt);
    return byDate != 0 ? byDate : left.id.compareTo(right.id);
  });
  return matches;
}
