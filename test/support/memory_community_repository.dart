import 'dart:async';
import 'dart:typed_data';

import 'package:project_bugbite/data/models/bite_filters.dart';
import 'package:project_bugbite/data/models/community_post.dart';
import 'package:project_bugbite/data/models/community_notification.dart';
import 'package:project_bugbite/data/services/auth_service.dart';
import 'package:project_bugbite/data/services/community_repository.dart';

/// A shared, in-memory server boundary. Private device data is never imported.
class MemoryCommunityRepository implements CommunityRepository {
  MemoryCommunityRepository({List<CommunityPost> posts = const []})
    : posts = List<CommunityPost>.of(posts) {
    for (final post in posts) {
      comments[post.id] = List<CommunityComment>.of(post.comments);
      if (post.imagePath != null && post.imageBytes != null) {
        photos[post.imagePath!] = post.imageBytes!;
      }
    }
  }

  final List<CommunityPost> posts;
  final Map<String, List<CommunityComment>> comments = {};
  final Map<String, List<CommunityNotification>> notifications = {};
  final Map<String, Uint8List> photos = {};
  final Map<String, Set<String>> likedBy = {};
  final List<({String postId, String userId, String reason})> reports = [];
  final _changes = StreamController<void>.broadcast(sync: true);
  bool failWrites = false;
  bool failReads = false;
  bool holdReads = false;
  int _sequence = 0;

  static const failureMessage =
      'Community is temporarily unavailable. Please try again.';

  void emit() => _changes.add(null);

  Future<void> dispose() => _changes.close();

  Stream<T> _watch<T>(T Function() read) => Stream<T>.multi((controller) {
    void send() {
      if (holdReads) return;
      if (failReads) {
        controller.addError(const CommunityException(failureMessage));
      } else {
        controller.add(read());
      }
    }

    final subscription = _changes.stream.listen((_) => send());
    controller.onCancel = subscription.cancel;
    send();
  });

  CommunityPost _remote(CommunityPost post) => CommunityPost(
    id: post.id,
    authorId: post.authorId,
    author: post.author,
    location: post.location,
    createdAt: post.createdAt,
    possibleMatch: post.possibleMatch,
    body: post.body,
    guideId: post.guideId,
    tags: BiteFilters.normalizeAll(post.tags).toList(growable: false),
    imagePath: post.imagePath,
    likes: likedBy[post.id]?.length ?? post.likes,
    remoteCommentCount: comments[post.id]?.length ?? 0,
  );

  @override
  Stream<List<CommunityPost>> watchPosts({
    String? tag,
    String? authorId,
    int limit = 50,
  }) => _watch(() {
    final result =
        posts
            .where((post) {
              return (authorId == null || post.authorId == authorId) &&
                  (tag == null ||
                      BiteFilters.normalizeAll(
                        post.tags,
                      ).contains(BiteFilters.normalize(tag)));
            })
            .map(_remote)
            .toList()
          ..sort((a, b) {
            final byTime = b.createdAt.compareTo(a.createdAt);
            return byTime == 0 ? a.id.compareTo(b.id) : byTime;
          });
    return result.take(limit).toList(growable: false);
  });

  @override
  Stream<CommunityPost?> watchPost(String postId) => _watch(() {
    final post = posts.where((post) => post.id == postId).firstOrNull;
    return post == null ? null : _remote(post);
  });

  @override
  Stream<List<CommunityComment>> watchComments(
    String postId, {
    int limit = 50,
  }) => _watch(() {
    final result = List<CommunityComment>.of(comments[postId] ?? const [])
      ..sort((a, b) {
        final byTime = b.createdAt.compareTo(a.createdAt);
        return byTime == 0 ? a.id.compareTo(b.id) : byTime;
      });
    return result.take(limit).toList(growable: false);
  });

  @override
  Stream<bool> watchLiked(String postId, String userId) =>
      _watch(() => likedBy[postId]?.contains(userId) ?? false);

  @override
  Stream<CommunityComment?> watchComment(String postId, String commentId) =>
      _watch(
        () => comments[postId]
            ?.where((comment) => comment.id == commentId)
            .firstOrNull,
      );

  @override
  Stream<List<CommunityNotification>> watchNotifications(
    String userId, {
    int limit = 50,
  }) => _watch(() {
    final result = List<CommunityNotification>.of(
      notifications[userId] ?? const [],
    )..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result.take(limit).toList(growable: false);
  });

  @override
  Stream<int> watchUnreadNotificationCount(String userId) => _watch(
    () => (notifications[userId] ?? const [])
        .where((item) => !item.isRead)
        .take(100)
        .length,
  );

  @override
  Future<void> markNotificationRead({
    required String userId,
    required String notificationId,
  }) async {
    _checkWrite();
    final inbox = notifications[userId] ?? [];
    final index = inbox.indexWhere((item) => item.id == notificationId);
    if (index < 0) {
      throw const CommunityException(
        'This notification is no longer available.',
      );
    }
    inbox[index] = inbox[index].copyWith(isRead: true);
    emit();
  }

  @override
  Future<Uint8List?> loadPhoto(String path) async {
    if (failReads) throw const CommunityException(failureMessage);
    return photos[path];
  }

  void _checkWrite() {
    if (failWrites) throw const CommunityException(failureMessage);
  }

  void _checkAuthor(AuthUser user) {
    if (!user.isEmailVerified) {
      throw const CommunityException(
        'Verify your email before using the community.',
      );
    }
  }

  CommunityPost _requiredPost(String postId) => posts.firstWhere(
    (post) => post.id == postId,
    orElse: () =>
        throw const CommunityException('This post is no longer available.'),
  );

  @override
  Future<String> publishPost({
    required AuthUser author,
    required String possibleMatch,
    required String body,
    required String? guideId,
    required List<String> tags,
    Uint8List? imageBytes,
    String? draftId,
  }) async {
    _checkWrite();
    _checkAuthor(author);
    final id = draftId ?? 'post-${++_sequence}';
    final existing = posts.where((post) => post.id == id).firstOrNull;
    if (existing != null) {
      if (existing.authorId != author.id ||
          existing.body != body.trim() ||
          existing.possibleMatch != possibleMatch.trim()) {
        throw const CommunityException(
          'This draft was already used. Start a new post for different content.',
        );
      }
      return id;
    }
    if (body.trim().isEmpty || body.trim().length > 4000) {
      throw const CommunityException(
        'Enter a post between 1 and 4000 characters.',
      );
    }
    final path = imageBytes == null
        ? null
        : 'community/${author.id}/$id/photo.jpg';
    if (path != null) photos[path] = Uint8List.fromList(imageBytes!);
    posts.insert(
      0,
      CommunityPost(
        id: id,
        authorId: author.id,
        author: author.displayName ?? 'Community member',
        location: '',
        createdAt: DateTime.now(),
        possibleMatch: possibleMatch.trim(),
        body: body.trim(),
        guideId: guideId,
        tags: BiteFilters.normalizeAll(tags).toList(growable: false),
        imagePath: path,
        remoteCommentCount: 0,
      ),
    );
    comments[id] = [];
    emit();
    return id;
  }

  @override
  Future<void> addComment({
    required String postId,
    required AuthUser author,
    required String body,
    String? replyToCommentId,
  }) async {
    _checkWrite();
    _checkAuthor(author);
    final post = _requiredPost(postId);
    final target = replyToCommentId == null
        ? null
        : comments[postId]
              ?.where((comment) => comment.id == replyToCommentId)
              .firstOrNull;
    if (replyToCommentId != null && target == null) {
      throw const CommunityException(
        'This comment is no longer available. Choose another comment to reply to.',
        code: 'reply-unavailable',
      );
    }
    final commentId = 'comment-${++_sequence}';
    final createdAt = DateTime.now();
    comments
        .putIfAbsent(postId, () => [])
        .add(
          CommunityComment(
            id: commentId,
            authorId: author.id,
            author: author.displayName ?? 'Community member',
            body: body.trim(),
            createdAt: createdAt,
            replyToCommentId: target?.id,
            replyToAuthorId: target?.authorId,
            replyToAuthor: target?.author,
          ),
        );
    final recipient = target?.authorId ?? post.authorId;
    if (recipient != author.id) {
      notifications
          .putIfAbsent(recipient, () => [])
          .add(
            CommunityNotification(
              id: '${postId}_$commentId',
              recipientId: recipient,
              actorId: author.id,
              actorName: author.displayName ?? 'Member',
              postId: postId,
              commentId: commentId,
              replyToCommentId: target?.id,
              createdAt: createdAt,
              isRead: false,
            ),
          );
    }
    emit();
  }

  @override
  Future<void> setLiked({
    required String postId,
    required String userId,
    required bool liked,
  }) async {
    _checkWrite();
    _requiredPost(postId);
    final likes = likedBy.putIfAbsent(postId, () => {});
    if (liked) {
      likes.add(userId);
    } else {
      likes.remove(userId);
    }
    emit();
  }

  @override
  Future<void> deletePost({
    required String postId,
    required String userId,
  }) async {
    _checkWrite();
    final post = _requiredPost(postId);
    if (post.authorId != userId) {
      throw const CommunityException('Only the author can remove this post.');
    }
    posts.removeWhere((post) => post.id == postId);
    if (post.imagePath != null) photos.remove(post.imagePath);
    emit();
  }

  @override
  Future<void> deleteComment({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    _checkWrite();
    _requiredPost(postId);
    final replies = comments[postId] ?? [];
    final comment = replies
        .where((comment) => comment.id == commentId)
        .firstOrNull;
    if (comment == null) return;
    if (comment.authorId != userId) {
      throw const CommunityException(
        'Only the author can remove this comment.',
      );
    }
    replies.removeWhere((comment) => comment.id == commentId);
    emit();
  }

  @override
  Future<void> reportPost({
    required String postId,
    required String userId,
    required String reason,
  }) async {
    _checkWrite();
    _requiredPost(postId);
    reports.add((postId: postId, userId: userId, reason: reason));
    emit();
  }
}
