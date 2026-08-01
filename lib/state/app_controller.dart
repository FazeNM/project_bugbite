import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bite_guide.dart';
import '../data/models/community_post.dart';
import '../data/seed/seed_data.dart';

class AppState {
  const AppState({
    required this.isSignedIn,
    required this.displayName,
    required this.posts,
    required this.savedGuideIds,
  });

  factory AppState.initial() => AppState(
    isSignedIn: false,
    displayName: 'Alex',
    posts: List<CommunityPost>.unmodifiable(seedPosts),
    savedGuideIds: const <String>{},
  );

  final bool isSignedIn;
  final String displayName;
  final List<CommunityPost> posts;
  final Set<String> savedGuideIds;

  AppState copyWith({
    bool? isSignedIn,
    String? displayName,
    List<CommunityPost>? posts,
    Set<String>? savedGuideIds,
  }) => AppState(
    isSignedIn: isSignedIn ?? this.isSignedIn,
    displayName: displayName ?? this.displayName,
    posts: posts ?? this.posts,
    savedGuideIds: savedGuideIds ?? this.savedGuideIds,
  );
}

class AppController extends Notifier<AppState> {
  @override
  AppState build() => AppState.initial();

  void signIn({required String displayName}) {
    final cleanedName = displayName.trim().isEmpty
        ? 'Alex'
        : displayName.trim();
    state = state.copyWith(isSignedIn: true, displayName: cleanedName);
  }

  void signOut() => state = AppState.initial();

  void toggleSavedGuide(String guideId) {
    final updated = Set<String>.from(state.savedGuideIds);
    if (!updated.add(guideId)) updated.remove(guideId);
    state = state.copyWith(savedGuideIds: Set<String>.unmodifiable(updated));
  }

  void togglePostLike(String postId) {
    final posts = state.posts
        .map((post) {
          if (post.id != postId) return post;
          final isLiked = !post.liked;
          return post.copyWith(
            liked: isLiked,
            likes: isLiked ? post.likes + 1 : post.likes - 1,
          );
        })
        .toList(growable: false);
    state = state.copyWith(posts: List<CommunityPost>.unmodifiable(posts));
  }

  void addCommunityPost({
    required String possibleMatch,
    required String body,
    required BiteVisual visual,
    required List<String> tags,
    Uint8List? imageBytes,
  }) {
    final post = CommunityPost(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      author: state.displayName,
      location: 'Your area',
      createdAt: DateTime.now(),
      possibleMatch: possibleMatch,
      body: body,
      visual: visual,
      tags: tags,
      imageBytes: imageBytes,
    );
    state = state.copyWith(
      posts: List<CommunityPost>.unmodifiable(<CommunityPost>[
        post,
        ...state.posts,
      ]),
    );
  }
}

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);
