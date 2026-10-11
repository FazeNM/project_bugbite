import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/community_post.dart';
import '../data/seed/seed_data.dart';
import '../data/services/app_persistence_service.dart';
import 'persistence_providers.dart';

class AppState {
  const AppState({
    required this.isSignedIn,
    required this.userId,
    required this.displayName,
    required this.posts,
    required this.savedGuideIds,
    required this.gentleReminders,
    required this.stripPhotoMetadata,
    this.isHydrating = false,
    this.persistenceError,
    this.persistenceReadFailed = false,
  });

  factory AppState.initial() => AppState(
    isSignedIn: false,
    userId: null,
    displayName: 'Alex',
    posts: List<CommunityPost>.unmodifiable(seedPosts),
    savedGuideIds: const <String>{},
    gentleReminders: true,
    stripPhotoMetadata: true,
  );

  final bool isSignedIn;
  final String? userId;
  final String displayName;
  final List<CommunityPost> posts;
  final Set<String> savedGuideIds;
  final bool gentleReminders;
  final bool stripPhotoMetadata;
  final bool isHydrating;
  final String? persistenceError;
  final bool persistenceReadFailed;

  AppState copyWith({
    bool? isSignedIn,
    String? userId,
    String? displayName,
    List<CommunityPost>? posts,
    Set<String>? savedGuideIds,
    bool? gentleReminders,
    bool? stripPhotoMetadata,
    bool? isHydrating,
    String? persistenceError,
    bool? persistenceReadFailed,
    bool clearPersistenceError = false,
  }) => AppState(
    isSignedIn: isSignedIn ?? this.isSignedIn,
    userId: userId ?? this.userId,
    displayName: displayName ?? this.displayName,
    posts: posts ?? this.posts,
    savedGuideIds: savedGuideIds ?? this.savedGuideIds,
    gentleReminders: gentleReminders ?? this.gentleReminders,
    stripPhotoMetadata: stripPhotoMetadata ?? this.stripPhotoMetadata,
    isHydrating: isHydrating ?? this.isHydrating,
    persistenceError: clearPersistenceError
        ? null
        : persistenceError ?? this.persistenceError,
    persistenceReadFailed: persistenceReadFailed ?? this.persistenceReadFailed,
  );
}

class AppController extends Notifier<AppState> {
  AppPersistenceService get _persistence =>
      ref.read(appPersistenceServiceProvider);

  String? _activeUserId;
  Future<void> _writeQueue = Future<void>.value();

  @override
  AppState build() => AppState.initial();

  void signIn({required String displayName}) {
    final cleanedName = displayName.trim().isEmpty
        ? 'Alex'
        : displayName.trim();
    state = state.copyWith(isSignedIn: true, displayName: cleanedName);
  }

  Future<void> syncAuthenticatedUser({
    required String userId,
    String? displayName,
    String? email,
  }) async {
    final cleanedName = displayName?.trim();
    final emailName = email?.split('@').first.trim();
    final resolvedName = cleanedName?.isNotEmpty == true
        ? cleanedName!
        : emailName?.isNotEmpty == true
        ? emailName!
        : 'BiteWise member';

    if (_activeUserId == userId && state.isSignedIn) {
      if (state.displayName != resolvedName) {
        state = state.copyWith(displayName: resolvedName);
        unawaited(_persist());
      }
      return;
    }

    _activeUserId = userId;
    final defaults = AppState.initial();
    state = defaults.copyWith(
      isSignedIn: true,
      userId: userId,
      displayName: resolvedName,
      isHydrating: true,
      persistenceReadFailed: false,
      clearPersistenceError: true,
    );

    try {
      final persisted = await _persistence.load(userId);
      if (_activeUserId != userId) return;

      state = state.copyWith(
        posts: persisted?.posts ?? defaults.posts,
        savedGuideIds: persisted?.savedGuideIds ?? defaults.savedGuideIds,
        gentleReminders: persisted?.gentleReminders ?? defaults.gentleReminders,
        stripPhotoMetadata:
            persisted?.stripPhotoMetadata ?? defaults.stripPhotoMetadata,
        isHydrating: false,
        persistenceReadFailed: false,
        clearPersistenceError: true,
      );
      if (persisted == null) await _persist();
    } on AppPersistenceException catch (error) {
      if (_activeUserId != userId) return;
      state = state.copyWith(
        isHydrating: false,
        persistenceError: error.message,
        persistenceReadFailed: true,
      );
    }
  }

  void signOut() {
    _activeUserId = null;
    state = AppState.initial();
  }

  Future<bool> toggleSavedGuide(String guideId) async {
    final wasSaved = state.savedGuideIds.contains(guideId);
    final updated = Set<String>.from(state.savedGuideIds);
    if (!updated.add(guideId)) updated.remove(guideId);
    state = state.copyWith(savedGuideIds: Set<String>.unmodifiable(updated));
    final saved = await _persist();
    if (!saved) {
      final rollback = Set<String>.from(state.savedGuideIds);
      if (wasSaved) {
        rollback.add(guideId);
      } else {
        rollback.remove(guideId);
      }
      state = state.copyWith(savedGuideIds: Set<String>.unmodifiable(rollback));
    }
    return saved;
  }

  Future<bool> togglePostLike(String postId) async {
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
    final saved = await _persist();
    if (!saved) {
      final rollbackPosts = state.posts
          .map((post) {
            if (post.id != postId) return post;
            final liked = !post.liked;
            return post.copyWith(
              liked: liked,
              likes: liked ? post.likes + 1 : post.likes - 1,
            );
          })
          .toList(growable: false);
      state = state.copyWith(
        posts: List<CommunityPost>.unmodifiable(rollbackPosts),
      );
    }
    return saved;
  }

  Future<bool> addComment({
    required String postId,
    required String body,
  }) async {
    final activeUserId = _activeUserId;
    final cleanedBody = body.trim();
    if (activeUserId == null ||
        cleanedBody.length < 2 ||
        !state.posts.any((post) => post.id == postId)) {
      return false;
    }

    final comment = CommunityComment(
      id: 'comment-${DateTime.now().microsecondsSinceEpoch}',
      authorId: activeUserId,
      author: state.displayName,
      body: cleanedBody,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      posts: List<CommunityPost>.unmodifiable(
        state.posts.map(
          (post) => post.id == postId
              ? post.copyWith(
                  comments: List<CommunityComment>.unmodifiable(
                    <CommunityComment>[...post.comments, comment],
                  ),
                )
              : post,
        ),
      ),
    );

    final saved = await _persist();
    if (!saved) {
      state = state.copyWith(
        posts: List<CommunityPost>.unmodifiable(
          state.posts.map(
            (post) => post.id == postId
                ? post.copyWith(
                    comments: List<CommunityComment>.unmodifiable(
                      post.comments.where((item) => item.id != comment.id),
                    ),
                  )
                : post,
          ),
        ),
      );
    }
    return saved;
  }

  Future<bool> addCommunityPost({
    required String possibleMatch,
    required String body,
    required String? guideId,
    required List<String> tags,
    Uint8List? imageBytes,
  }) async {
    final post = CommunityPost(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      authorId: _activeUserId ?? 'local-user',
      author: state.displayName,
      location: 'Your area',
      createdAt: DateTime.now(),
      possibleMatch: possibleMatch,
      body: body,
      guideId: guideId,
      tags: tags,
      imageBytes: imageBytes,
    );
    state = state.copyWith(
      posts: List<CommunityPost>.unmodifiable(<CommunityPost>[
        post,
        ...state.posts,
      ]),
    );
    final saved = await _persist();
    if (!saved) {
      state = state.copyWith(
        posts: List<CommunityPost>.unmodifiable(
          state.posts.where((item) => item.id != post.id),
        ),
      );
    }
    return saved;
  }

  Future<bool> setGentleReminders(bool value) async {
    final previous = state.gentleReminders;
    state = state.copyWith(gentleReminders: value);
    final saved = await _persist();
    if (!saved) state = state.copyWith(gentleReminders: previous);
    return saved;
  }

  /// A local archive marker only; publishing is an explicit cloud action.
  Future<bool> markLegacyPublished({
    required String localPostId,
    required String remotePostId,
  }) async {
    final userId = _activeUserId;
    final previous = state.posts;
    if (userId == null ||
        !previous.any(
          (post) => post.id == localPostId && post.authorId == userId,
        )) {
      return false;
    }
    state = state.copyWith(
      posts: List<CommunityPost>.unmodifiable(
        previous.map(
          (post) => post.id == localPostId && post.authorId == userId
              ? post.copyWith(publishedPostId: remotePostId)
              : post,
        ),
      ),
    );
    final saved = await _persist();
    if (!saved && _activeUserId == userId) {
      state = state.copyWith(posts: previous);
    }
    return saved;
  }

  Future<bool> setStripPhotoMetadata(bool value) async {
    final previous = state.stripPhotoMetadata;
    state = state.copyWith(stripPhotoMetadata: value);
    final saved = await _persist();
    if (!saved) state = state.copyWith(stripPhotoMetadata: previous);
    return saved;
  }

  Future<bool> retryPersistence() async {
    if (!state.persistenceReadFailed) return _persist();

    final userId = _activeUserId;
    if (userId == null) return false;
    state = state.copyWith(isHydrating: true, clearPersistenceError: true);
    try {
      final persisted = await _persistence.load(userId);
      if (_activeUserId != userId) return false;
      final defaults = AppState.initial();
      state = state.copyWith(
        posts: persisted?.posts ?? defaults.posts,
        savedGuideIds: persisted?.savedGuideIds ?? defaults.savedGuideIds,
        gentleReminders: persisted?.gentleReminders ?? defaults.gentleReminders,
        stripPhotoMetadata:
            persisted?.stripPhotoMetadata ?? defaults.stripPhotoMetadata,
        isHydrating: false,
        persistenceReadFailed: false,
        clearPersistenceError: true,
      );
      return persisted != null || await _persist();
    } on AppPersistenceException catch (error) {
      if (_activeUserId == userId) {
        state = state.copyWith(
          isHydrating: false,
          persistenceError: error.message,
          persistenceReadFailed: true,
        );
      }
      return false;
    }
  }

  Future<bool> _persist() {
    final userId = _activeUserId;
    if (userId == null) return Future<bool>.value(false);

    final snapshot = state;
    final result = Completer<bool>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        await _persistence.save(
          userId,
          PersistedAppData(
            posts: snapshot.posts,
            savedGuideIds: snapshot.savedGuideIds,
            gentleReminders: snapshot.gentleReminders,
            stripPhotoMetadata: snapshot.stripPhotoMetadata,
          ),
        );
        if (_activeUserId == userId && state.persistenceError != null) {
          state = state.copyWith(
            clearPersistenceError: true,
            persistenceReadFailed: false,
          );
        }
        result.complete(true);
      } on AppPersistenceException catch (error) {
        if (_activeUserId == userId) {
          state = state.copyWith(persistenceError: error.message);
        }
        result.complete(false);
      }
    });
    return result.future;
  }
}

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);
