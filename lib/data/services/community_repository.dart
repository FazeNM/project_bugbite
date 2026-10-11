import 'dart:typed_data';

import '../models/community_post.dart';
import '../models/community_notification.dart';
import 'auth_service.dart';

/// A failure that is safe to show directly to a community member.
class CommunityException implements Exception {
  const CommunityException(this.message, {this.code = 'unknown'});

  final String message;
  final String code;

  /// A request may still commit: retain its draft ID and check the live feed.
  bool get isPending => code == 'pending';

  @override
  String toString() => message;
}

/// Shared community storage, independent from private device/profile history.
abstract interface class CommunityRepository {
  /// Only the first observation is queried remotely. The caller applies all
  /// other selected filters, and offers explicit loading of a larger window.
  Stream<List<CommunityPost>> watchPosts({
    String? tag,
    String? authorId,
    int limit = 50,
  });

  Stream<CommunityPost?> watchPost(String postId);

  Stream<List<CommunityComment>> watchComments(String postId, {int limit = 50});

  Stream<CommunityComment?> watchComment(String postId, String commentId);

  Stream<bool> watchLiked(String postId, String userId);

  /// Private activity for the signed-in account, newest first.
  Stream<List<CommunityNotification>> watchNotifications(
    String userId, {
    int limit = 50,
  });

  /// Reads at most 100 unread records. Display 100 as "99+" rather than an
  /// exact total; the bounded listener keeps activity within the free quota.
  Stream<int> watchUnreadNotificationCount(String userId);

  Future<void> markNotificationRead({
    required String userId,
    required String notificationId,
  });

  Future<Uint8List?> loadPhoto(String path);

  /// Use one stable [draftId] for every retry of a compose session. Existing
  /// device-only posts must never be automatically passed to this method.
  Future<String> publishPost({
    required AuthUser author,
    required String possibleMatch,
    required String body,
    required String? guideId,
    required List<String> tags,
    Uint8List? imageBytes,
    String? draftId,
  });

  Future<void> addComment({
    required String postId,
    required AuthUser author,
    required String body,
    String? replyToCommentId,
  });

  Future<void> setLiked({
    required String postId,
    required String userId,
    required bool liked,
  });

  Future<void> deletePost({required String postId, required String userId});

  Future<void> deleteComment({
    required String postId,
    required String commentId,
    required String userId,
  });

  Future<void> reportPost({
    required String postId,
    required String userId,
    required String reason,
  });
}
