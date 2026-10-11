import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/community_post.dart';
import '../data/models/community_notification.dart';
import '../data/services/auth_service.dart';
import '../data/services/community_repository.dart';
import '../data/services/firebase_community_repository.dart';
import 'auth_controller.dart';

/// Only the community uses this shared repository. Private guides/history keep
/// their separate, UID-scoped local store. Tests replace this boundary.
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  ref.watch(currentUserProvider.select((user) => user?.id));
  return FirebaseCommunityRepository();
});

typedef CommunityFeedQuery = ({String? tag, String? authorId, int limit});
typedef CommunityCommentsQuery = ({String postId, int limit});
typedef CommunityCommentQuery = ({String postId, String commentId});

final communityCommentProvider = StreamProvider.autoDispose
    .family<CommunityComment?, CommunityCommentQuery>((ref, query) {
      final user = ref.watch(currentUserProvider);
      if (user == null || !user.isEmailVerified) return Stream.value(null);
      return ref
          .watch(communityRepositoryProvider)
          .watchComment(query.postId, query.commentId);
    });

final communityNotificationsProvider = StreamProvider.autoDispose
    .family<List<CommunityNotification>, int>((ref, limit) {
      final user = ref.watch(currentUserProvider);
      if (user == null || !user.isEmailVerified) {
        return Stream.value(const <CommunityNotification>[]);
      }
      return ref
          .watch(communityRepositoryProvider)
          .watchNotifications(user.id, limit: limit);
    });

/// The repository caps this stream at 100; the UI displays 99+ at that bound.
final communityUnreadNotificationCountProvider =
    StreamProvider.autoDispose<int>((ref) {
      final user = ref.watch(currentUserProvider);
      if (user == null || !user.isEmailVerified) return Stream.value(0);
      return ref
          .watch(communityRepositoryProvider)
          .watchUnreadNotificationCount(user.id);
    });

final communityFeedProvider = StreamProvider.autoDispose
    .family<List<CommunityPost>, CommunityFeedQuery>((ref, query) {
      final user = ref.watch(currentUserProvider);
      if (user == null || !user.isEmailVerified) {
        return Stream.value(const <CommunityPost>[]);
      }
      return ref
          .watch(communityRepositoryProvider)
          .watchPosts(
            tag: query.tag,
            authorId: query.authorId,
            limit: query.limit,
          );
    });

final communityPostProvider = StreamProvider.autoDispose
    .family<CommunityPost?, String>((ref, postId) {
      final user = ref.watch(currentUserProvider);
      if (user == null || !user.isEmailVerified) return Stream.value(null);
      return ref.watch(communityRepositoryProvider).watchPost(postId);
    });

final communityCommentsProvider = StreamProvider.autoDispose
    .family<List<CommunityComment>, CommunityCommentsQuery>((ref, query) {
      final user = ref.watch(currentUserProvider);
      if (user == null || !user.isEmailVerified) {
        return Stream.value(const <CommunityComment>[]);
      }
      return ref
          .watch(communityRepositoryProvider)
          .watchComments(query.postId, limit: query.limit);
    });

final communityLikedProvider = StreamProvider.autoDispose.family<bool, String>((
  ref,
  postId,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isEmailVerified) return Stream.value(false);
  return ref.watch(communityRepositoryProvider).watchLiked(postId, user.id);
});

final communityPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>((ref, path) {
      final user = ref.watch(currentUserProvider);
      if (user == null || !user.isEmailVerified) {
        return Future.value(null);
      }
      return ref.watch(communityRepositoryProvider).loadPhoto(path);
    });

class CommunityActionState {
  const CommunityActionState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;
}

class CommunityActions extends Notifier<CommunityActionState> {
  int _generation = 0;

  @override
  CommunityActionState build() {
    ref.watch(currentUserProvider.select((user) => user?.id));
    _generation++;
    return const CommunityActionState();
  }

  Future<T?> _run<T>(
    Future<T> Function(AuthUser user, CommunityRepository repo) action,
  ) async {
    if (state.isLoading) return null;
    final user = ref.read(currentUserProvider);
    if (user == null || !user.isEmailVerified) {
      state = const CommunityActionState(
        errorMessage: 'Sign in with a verified account to use the community.',
      );
      return null;
    }
    state = const CommunityActionState(isLoading: true);
    final generation = _generation;
    try {
      final result = await action(user, ref.read(communityRepositoryProvider));
      if (!ref.mounted ||
          generation != _generation ||
          ref.read(currentUserProvider)?.id != user.id) {
        return null;
      }
      state = const CommunityActionState();
      return result;
    } catch (error) {
      if (ref.mounted &&
          generation == _generation &&
          ref.read(currentUserProvider)?.id == user.id) {
        state = CommunityActionState(
          errorMessage: error is CommunityException
              ? error.message
              : 'The community could not complete this request. Check your connection and try again.',
        );
      }
      return null;
    }
  }

  Future<String?> publishPost({
    String? draftId,
    required String possibleMatch,
    required String body,
    required String? guideId,
    required List<String> tags,
    Uint8List? imageBytes,
  }) => _run(
    (user, repo) => repo.publishPost(
      author: user,
      draftId: draftId,
      possibleMatch: possibleMatch,
      body: body,
      guideId: guideId,
      tags: tags,
      imageBytes: imageBytes,
    ),
  );

  Future<bool> addComment({
    required String postId,
    required String body,
    String? replyToCommentId,
  }) async =>
      await _run((user, repo) async {
        await repo.addComment(
          postId: postId,
          author: user,
          body: body,
          replyToCommentId: replyToCommentId,
        );
        return true;
      }) ??
      false;

  Future<bool> markNotificationRead({required String notificationId}) async =>
      await _run((user, repo) async {
        await repo.markNotificationRead(
          userId: user.id,
          notificationId: notificationId,
        );
        return true;
      }) ??
      false;

  Future<bool> setLiked({required String postId, required bool liked}) async =>
      await _run((user, repo) async {
        await repo.setLiked(postId: postId, userId: user.id, liked: liked);
        return true;
      }) ??
      false;

  Future<bool> deletePost({required String postId}) async =>
      await _run((user, repo) async {
        await repo.deletePost(postId: postId, userId: user.id);
        return true;
      }) ??
      false;

  Future<bool> deleteComment({
    required String postId,
    required String commentId,
  }) async =>
      await _run((user, repo) async {
        await repo.deleteComment(
          postId: postId,
          commentId: commentId,
          userId: user.id,
        );
        return true;
      }) ??
      false;

  Future<bool> reportPost({
    required String postId,
    required String reason,
  }) async =>
      await _run((user, repo) async {
        await repo.reportPost(postId: postId, userId: user.id, reason: reason);
        return true;
      }) ??
      false;
}

final communityActionsProvider =
    NotifierProvider<CommunityActions, CommunityActionState>(
      CommunityActions.new,
    );
