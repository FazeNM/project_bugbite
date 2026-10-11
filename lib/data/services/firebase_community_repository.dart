import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../core/config/community_config.dart';
import '../models/bite_filters.dart';
import '../models/community_notification.dart';
import '../models/community_post.dart';
import 'auth_service.dart';
import 'community_repository.dart';

/// Authenticated, shared storage. Nothing here reads or migrates local posts.
class FirebaseCommunityRepository implements CommunityRepository {
  FirebaseCommunityRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final _publishing = <String, Future<String>>{};
  final _commentAttempts = <String, String>{};
  static const _timeout = Duration(seconds: 30);
  static const _maxPhotoBytes = 5 * 1024 * 1024;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('communityPosts');

  CollectionReference<Map<String, dynamic>> _notifications(String userId) =>
      _firestore
          .collection('communityNotifications')
          .doc(_documentId(userId))
          .collection('items');

  @override
  Stream<List<CommunityPost>> watchPosts({
    String? tag,
    String? authorId,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _posts.where(
      'status',
      isEqualTo: 'published',
    );
    if (tag != null) {
      final normalized = BiteFilters.normalize(tag);
      if (normalized == null) {
        return Stream.error(const CommunityException('Choose a valid filter.'));
      }
      query = query.where('tags', arrayContains: normalized);
    }
    if (authorId != null) {
      query = query.where('authorId', isEqualTo: authorId);
    }
    return _safeStream(
      query
          .orderBy('createdAt', descending: true)
          .limit(_boundedLimit(limit))
          .snapshots(includeMetadataChanges: true)
          .map(
            (snapshot) => List<CommunityPost>.unmodifiable(
              snapshot.docs
                  .where((doc) => !doc.metadata.hasPendingWrites)
                  .map((doc) => communityPostFromFirestore(doc.id, doc.data())),
            ),
          ),
    );
  }

  @override
  Stream<CommunityPost?> watchPost(String postId) => _safeStream(
    _posts
        .doc(_documentId(postId))
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.hasPendingWrites)
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null || data['status'] != 'published') return null;
          return communityPostFromFirestore(snapshot.id, data);
        }),
  );

  @override
  Stream<List<CommunityComment>> watchComments(
    String postId, {
    int limit = 50,
  }) => _safeStream(
    _posts
        .doc(_documentId(postId))
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(_boundedLimit(limit))
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => List<CommunityComment>.unmodifiable(
            snapshot.docs
                .where((doc) => !doc.metadata.hasPendingWrites)
                .map(
                  (doc) => communityCommentFromFirestore(doc.id, doc.data()),
                ),
          ),
        ),
  );

  @override
  Stream<CommunityComment?> watchComment(String postId, String commentId) =>
      _safeStream(
        _posts
            .doc(_documentId(postId))
            .collection('comments')
            .doc(_documentId(commentId))
            .snapshots(includeMetadataChanges: true)
            .where((snapshot) => !snapshot.metadata.hasPendingWrites)
            .map((snapshot) {
              final data = snapshot.data();
              return data == null
                  ? null
                  : communityCommentFromFirestore(snapshot.id, data);
            }),
      );

  @override
  Stream<bool> watchLiked(String postId, String userId) => _safeStream(
    _posts
        .doc(_documentId(postId))
        .collection('likes')
        .doc(_documentId(userId))
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.hasPendingWrites)
        .map((snapshot) => snapshot.exists),
  );

  @override
  Stream<List<CommunityNotification>> watchNotifications(
    String userId, {
    int limit = 50,
  }) => _safeStream(
    _notifications(userId)
        .orderBy('createdAt', descending: true)
        .limit(_boundedLimit(limit))
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => List<CommunityNotification>.unmodifiable(
            snapshot.docs
                .where((doc) => !doc.metadata.hasPendingWrites)
                .map(
                  (doc) =>
                      communityNotificationFromFirestore(doc.id, doc.data()),
                ),
          ),
        ),
  );

  @override
  Stream<int> watchUnreadNotificationCount(String userId) => _safeStream(
    _notifications(userId)
        .where('isRead', isEqualTo: false)
        .limit(100)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => !doc.metadata.hasPendingWrites)
              .length,
        ),
  );

  @override
  Future<void> markNotificationRead({
    required String userId,
    required String notificationId,
  }) => _request(() async {
    final identity = await _identity(userId);
    final notification = _notifications(
      identity.id,
    ).doc(_notificationId(notificationId));
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(notification);
      if (!snapshot.exists || snapshot.data()?['isRead'] == true) return;
      transaction.update(notification, <String, dynamic>{'isRead': true});
    });
  }, mutating: true);

  @override
  Future<Uint8List?> loadPhoto(String path) => _request(() async {
    if (!isCommunityPhotoPath(path)) {
      throw const CommunityException('This community photo is unavailable.');
    }
    try {
      return await _storage.ref(path).getData(_maxPhotoBytes);
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') return null;
      rethrow;
    }
  });

  @override
  Future<String> publishPost({
    required AuthUser author,
    required String possibleMatch,
    required String body,
    required String? guideId,
    required List<String> tags,
    Uint8List? imageBytes,
    String? draftId,
  }) {
    if (imageBytes != null && !communityPhotoUploadsEnabled) {
      return Future.error(
        const CommunityException(
          'Photo uploads are coming soon. Remove the attached photo to publish a text post.',
          code: 'photos-not-enabled',
        ),
      );
    }
    if (_auth.currentUser?.uid != author.id) {
      return Future.error(
        const CommunityException(
          'Sign in again before publishing.',
          code: 'unauthenticated',
        ),
      );
    }
    final id = draftId == null ? _posts.doc().id : _documentId(draftId);
    final operationKey = '${author.id}/$id';
    final existing = _publishing[operationKey];
    if (existing != null) return _request(() => existing, mutating: true);
    final future = _publishPost(
      id: id,
      author: author,
      possibleMatch: _text(possibleMatch, 'possible match', 100),
      body: _text(body, 'post', 4000),
      guideId: guideId == null ? null : _documentId(guideId),
      tags: _canonicalTags(tags),
      imageBytes: imageBytes,
    );
    _publishing[operationKey] = future;
    // Keep the actual operation in flight after a UI timeout. Reusing this
    // draft does not create a second upload or a second Firestore document.
    unawaited(
      future.then<void>(
        (_) {
          _publishing.remove(operationKey);
        },
        onError: (Object _, StackTrace _) {
          _publishing.remove(operationKey);
        },
      ),
    );
    return _request(() => future, mutating: true);
  }

  Future<String> _publishPost({
    required String id,
    required AuthUser author,
    required String possibleMatch,
    required String body,
    required String? guideId,
    required List<String> tags,
    required Uint8List? imageBytes,
  }) async {
    final identity = await _identity(author.id);
    final ref = _posts.doc(id);
    final imagePath = imageBytes == null
        ? null
        : 'communityPhotos/${identity.id}/$id/photo.jpg';
    final content = <String, dynamic>{
      'authorId': identity.id,
      'author': identity.name,
      'location': 'Your area',
      'createdAt': FieldValue.serverTimestamp(),
      'possibleMatch': possibleMatch,
      'body': body,
      'guideId': guideId,
      'tags': tags,
      'status': 'published',
      'imagePath': imagePath,
      'likeCount': 0,
      'commentCount': 0,
      'lastCommentId': null,
    };
    final previous = await ref.get(const GetOptions(source: Source.server));
    if (previous.exists) {
      _checkSameDraft(previous.data()!, content);
      if (imageBytes != null) {
        final expected = await compute(prepareCommunityPhoto, imageBytes);
        final saved = await _storage.ref(imagePath!).getData(_maxPhotoBytes);
        if (!listEquals(saved, expected)) {
          throw const CommunityException(
            'This post already has a different photo. Start a new post to change it.',
            code: 'draft-changed',
          );
        }
      }
      return id;
    }
    var uploaded = false;
    var transactionStarted = false;
    try {
      if (imageBytes != null) {
        final jpeg = await compute(prepareCommunityPhoto, imageBytes);
        await _uploadPhoto(imagePath!, jpeg);
        uploaded = true;
      }
      // Authentication may change while a large image is being processed.
      await _identity(identity.id);
      transactionStarted = true;
      await _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(ref);
        if (existing.exists) {
          _checkSameDraft(existing.data()!, content);
        } else {
          transaction.set(ref, content);
        }
      });
      return id;
    } catch (error) {
      // Never remove a photo after an ambiguous commit: a published post may
      // already reference it. A retry with the same draft ID reconciles it.
      if (uploaded && (!transactionStarted || _definitelyRejected(error))) {
        try {
          final saved = await ref.get(const GetOptions(source: Source.server));
          if (!saved.exists) await _storage.ref(imagePath!).delete();
        } catch (_) {
          /* An orphan is private and can be retried at this path. */
        }
      }
      rethrow;
    }
  }

  Future<void> _uploadPhoto(String path, Uint8List bytes) async {
    final ref = _storage.ref(path);
    try {
      await ref.getMetadata();
      final existing = await ref.getData(_maxPhotoBytes);
      if (!listEquals(existing, bytes)) {
        throw const CommunityException(
          'This draft already has a different photo. Start a new post to change it.',
          code: 'draft-changed',
        );
      }
      return;
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
  }

  @override
  Future<void> addComment({
    required String postId,
    required AuthUser author,
    required String body,
    String? replyToCommentId,
  }) async {
    final text = _text(body, 'comment', 4000);
    final post = _posts.doc(_documentId(postId));
    final replyId = replyToCommentId == null
        ? null
        : _documentId(replyToCommentId);
    final key = '${author.id}\n$postId\n${replyId ?? ''}\n$text';
    final id = _commentAttempts.putIfAbsent(
      key,
      () => post.collection('comments').doc().id,
    );
    final comment = post.collection('comments').doc(id);
    await _request(() async {
      final identity = await _identity(author.id);
      await _firestore.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(post);
        final commentSnapshot = await transaction.get(comment);
        final replySnapshot = replyId == null
            ? null
            : await transaction.get(post.collection('comments').doc(replyId));
        final data = _publishedData(postSnapshot);
        // The target may have been deleted after a previously confirmed write.
        // Reconcile that write before requiring the target for a new reply.
        if (commentSnapshot.exists) {
          final saved = commentSnapshot.data()!;
          if (saved['authorId'] != identity.id ||
              saved['body'] != text ||
              saved['replyToCommentId'] != replyId) {
            throw const CommunityException(
              'This comment could not be confirmed. Refresh before retrying.',
              code: 'comment-conflict',
            );
          }
          return;
        }
        final reply = replySnapshot?.data();
        if (replyId != null && reply == null) {
          throw const CommunityException(
            'This comment is no longer available. Choose another comment to reply to.',
            code: 'reply-unavailable',
          );
        }
        final recipientId = _documentId(_string(reply ?? data, 'authorId'));
        transaction.set(comment, <String, dynamic>{
          'authorId': identity.id,
          'author': identity.name,
          'body': text,
          'createdAt': FieldValue.serverTimestamp(),
          if (replyId != null) ...<String, dynamic>{
            'replyToCommentId': replyId,
            'replyToAuthorId': recipientId,
            'replyToAuthor': _string(reply!, 'author'),
          },
        });
        transaction.update(post, <String, dynamic>{
          'commentCount': _count(data['commentCount']) + 1,
          'lastCommentId': id,
        });
        if (recipientId != identity.id) {
          // Recipient inboxes are private. Never read one as the sender; the
          // matching comment and strict create-only rules prove this event.
          transaction.set(
            _notifications(recipientId).doc('${post.id}_$id'),
            <String, dynamic>{
              'recipientId': recipientId,
              'actorId': identity.id,
              'actorName': identity.name,
              'postId': post.id,
              'commentId': id,
              'replyToCommentId': replyId,
              'createdAt': FieldValue.serverTimestamp(),
              'isRead': false,
            },
          );
        }
      });
    }, mutating: true);
    // Only forget after the caller receives a confirmed success. If the UI
    // timed out, retrying this same text reconciles the earlier comment ID.
    if (_commentAttempts[key] == id) _commentAttempts.remove(key);
  }

  @override
  Future<void> setLiked({
    required String postId,
    required String userId,
    required bool liked,
  }) => _request(() async {
    final identity = await _identity(userId);
    final post = _posts.doc(_documentId(postId));
    final like = post.collection('likes').doc(identity.id);
    await _firestore.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(post);
      final likeSnapshot = await transaction.get(like);
      final data = _publishedData(postSnapshot);
      if (likeSnapshot.exists == liked) return;
      if (liked) {
        transaction.set(like, <String, dynamic>{
          'userId': identity.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.delete(like);
      }
      transaction.update(post, <String, dynamic>{
        'likeCount': _count(data['likeCount']) + (liked ? 1 : -1),
      });
    });
  }, mutating: true);

  @override
  Future<void> deletePost({
    required String postId,
    required String userId,
  }) => _request(() async {
    final identity = await _identity(userId);
    final post = _posts.doc(_documentId(postId));
    final path = await _firestore.runTransaction<String?>((transaction) async {
      final snapshot = await transaction.get(post);
      final data = snapshot.data();
      if (data == null) return null;
      if (data['authorId'] != identity.id) {
        throw const CommunityException('Only the author can delete this post.');
      }
      if (data['status'] != 'deleted') {
        transaction.update(post, <String, dynamic>{'status': 'deleted'});
      }
      return data['imagePath'] as String?;
    });
    if (path != null && isCommunityPhotoPath(path)) {
      try {
        await _storage.ref(path).delete().timeout(_timeout);
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') {
          throw const CommunityException(
            'Your post is hidden. Its photo could not yet be removed from storage; contact support if this continues.',
            code: 'photo-cleanup-pending',
          );
        }
      } on TimeoutException {
        throw const CommunityException(
          'Your post is hidden. Photo removal has not been confirmed yet.',
          code: 'photo-cleanup-pending',
        );
      }
    }
  }, mutating: true);

  @override
  Future<void> deleteComment({
    required String postId,
    required String commentId,
    required String userId,
  }) => _request(() async {
    final identity = await _identity(userId);
    final post = _posts.doc(_documentId(postId));
    final comment = post.collection('comments').doc(_documentId(commentId));
    await _firestore.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(post);
      final commentSnapshot = await transaction.get(comment);
      final data = _publishedData(postSnapshot);
      if (!commentSnapshot.exists) return;
      if (commentSnapshot.data()!['authorId'] != identity.id) {
        throw const CommunityException(
          'Only the author can delete this comment.',
        );
      }
      transaction.delete(comment);
      transaction.update(post, <String, dynamic>{
        'commentCount': _count(data['commentCount']) - 1,
        'lastCommentId': commentId,
      });
    });
  }, mutating: true);

  @override
  Future<void> reportPost({
    required String postId,
    required String userId,
    required String reason,
  }) => _request(() async {
    final identity = await _identity(userId);
    final id = _documentId(postId);
    final text = _text(reason, 'report reason', 500);
    final report = _firestore
        .collection('communityReports')
        .doc('${identity.id}_$id');
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(report);
      if (existing.exists) return;
      transaction.set(report, <String, dynamic>{
        'reporterId': identity.id,
        'postId': id,
        'reason': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }, mutating: true);

  Future<({String id, String name})> _identity(String requestedId) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != requestedId) {
      throw const CommunityException(
        'Sign in again before making this change.',
        code: 'unauthenticated',
      );
    }
    final token = await user.getIdTokenResult(true);
    if (!user.emailVerified || token.claims?['email_verified'] != true) {
      throw const CommunityException(
        'Verify your email before using the community.',
        code: 'email-not-verified',
      );
    }
    if (_auth.currentUser?.uid != user.uid) {
      throw const CommunityException(
        'Your account changed. Please try again.',
        code: 'unauthenticated',
      );
    }
    final name = token.claims?['name'];
    return (
      id: user.uid,
      name: name is String && name.isNotEmpty && name.length <= 100
          ? name
          : 'Member',
    );
  }
}

/// Pure codecs are kept public so fixture tests do not require Firebase.
CommunityPost communityPostFromFirestore(
  String id,
  Map<String, dynamic> data,
) => CommunityPost(
  id: id,
  authorId: _string(data, 'authorId'),
  author: _string(data, 'author'),
  location: data['location'] as String? ?? 'Your area',
  createdAt: _date(data['createdAt']),
  possibleMatch: _string(data, 'possibleMatch'),
  body: _string(data, 'body'),
  guideId: data['guideId'] as String?,
  tags: List<String>.unmodifiable((data['tags'] as List).cast<String>()),
  imagePath: data['imagePath'] as String?,
  likes: _count(data['likeCount']),
  remoteCommentCount: _count(data['commentCount']),
);

CommunityComment communityCommentFromFirestore(
  String id,
  Map<String, dynamic> data,
) => CommunityComment(
  id: id,
  authorId: _string(data, 'authorId'),
  author: _string(data, 'author'),
  body: _string(data, 'body'),
  createdAt: _date(data['createdAt']),
  replyToCommentId: data['replyToCommentId'] as String?,
  replyToAuthorId: data['replyToCommentId'] == null
      ? null
      : _string(data, 'replyToAuthorId'),
  replyToAuthor: data['replyToCommentId'] == null
      ? null
      : _string(data, 'replyToAuthor'),
);

CommunityNotification communityNotificationFromFirestore(
  String id,
  Map<String, dynamic> data,
) {
  final isRead = data['isRead'];
  if (isRead is! bool) {
    throw const CommunityException(
      'This notification could not be read. Please refresh.',
      code: 'invalid-data',
    );
  }
  return CommunityNotification(
    id: id,
    recipientId: _string(data, 'recipientId'),
    actorId: _string(data, 'actorId'),
    actorName: _string(data, 'actorName'),
    postId: _string(data, 'postId'),
    commentId: _string(data, 'commentId'),
    replyToCommentId: data['replyToCommentId'] as String?,
    createdAt: _date(data['createdAt']),
    isRead: isRead,
  );
}

bool isCommunityPhotoPath(String path) => RegExp(
  r'^communityPhotos/[A-Za-z0-9_-]+/[A-Za-z0-9_-]+/photo\.jpg$',
).hasMatch(path);

/// Re-encodes only the user's actual photo, with orientation baked in and all
/// metadata discarded. This is resizing/encoding, not image generation.
Uint8List prepareCommunityPhoto(Uint8List bytes) {
  try {
    return _prepareCommunityPhoto(bytes);
  } on CommunityException {
    rethrow;
  } catch (_) {
    // Some format decoders throw RangeError for truncated headers. Never
    // expose a decoder exception as a crash or a raw message in the composer.
    throw const CommunityException(
      'This photo could not be opened. Try a different JPEG, PNG, or WebP image.',
      code: 'invalid-photo',
    );
  }
}

Uint8List _prepareCommunityPhoto(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > 20 * 1024 * 1024) {
    throw const CommunityException(
      'Choose a photo smaller than 20 MB.',
      code: 'invalid-photo',
    );
  }
  final decoder = img.findDecoderForData(bytes);
  final info = decoder?.startDecode(bytes);
  if (info == null ||
      info.width <= 0 ||
      info.height <= 0 ||
      info.width * info.height > 40000000) {
    throw const CommunityException(
      'Choose a JPEG, PNG, or WebP photo up to 40 megapixels.',
      code: 'invalid-photo',
    );
  }
  final decoded = decoder!.decodeFrame(0);
  if (decoded == null) {
    throw const CommunityException(
      'This photo could not be opened. Try another image.',
      code: 'invalid-photo',
    );
  }
  var oriented = img.bakeOrientation(decoded);
  if (oriented.width > 1280 || oriented.height > 1280) {
    oriented = img.copyResize(
      oriented,
      width: oriented.width >= oriented.height ? 1280 : null,
      height: oriented.height > oriented.width ? 1280 : null,
      interpolation: img.Interpolation.average,
    );
  }
  // Construct from pixels rather than copying an Image with EXIF/GPS/text data.
  final pixels = oriented.getBytes(order: img.ChannelOrder.rgb);
  final clean = img.Image.fromBytes(
    width: oriented.width,
    height: oriented.height,
    bytes: pixels.buffer,
    bytesOffset: pixels.offsetInBytes,
    numChannels: 3,
    order: img.ChannelOrder.rgb,
  );
  return Uint8List.fromList(img.encodeJpg(clean, quality: 86));
}

Map<String, dynamic> _publishedData(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
) {
  final data = snapshot.data();
  if (data == null || data['status'] != 'published') {
    throw const CommunityException(
      'This post is no longer available.',
      code: 'post-unavailable',
    );
  }
  return data;
}

void _checkSameDraft(
  Map<String, dynamic> saved,
  Map<String, dynamic> proposed,
) {
  const keys = ['authorId', 'possibleMatch', 'body', 'guideId', 'imagePath'];
  if (saved['status'] != 'published' ||
      keys.any((key) => saved[key] != proposed[key]) ||
      !listEquals(
        (saved['tags'] as List).cast<String>(),
        (proposed['tags'] as List).cast<String>(),
      )) {
    throw const CommunityException(
      'This draft was already used. Start a new post for different content.',
      code: 'draft-changed',
    );
  }
}

List<String> _canonicalTags(List<String> tags) {
  if (tags.any((tag) => BiteFilters.normalize(tag) == null)) {
    throw const CommunityException(
      'One of the selected filters is no longer available.',
    );
  }
  final result = BiteFilters.normalizeAll(tags).toList()..sort();
  if (result.length > 15) {
    throw const CommunityException('Choose up to 15 filters.');
  }
  return result;
}

String _text(String value, String label, int maximum) {
  final cleaned = value.trim();
  if (cleaned.isEmpty || cleaned.length > maximum) {
    throw CommunityException(
      'Enter a $label between 1 and $maximum characters.',
      code: 'invalid-input',
    );
  }
  return cleaned;
}

String _documentId(String value) {
  if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(value)) {
    throw const CommunityException(
      'This community item is unavailable.',
      code: 'invalid-id',
    );
  }
  return value;
}

String _notificationId(String value) {
  if (!RegExp(r'^[A-Za-z0-9_-]{3,257}$').hasMatch(value)) {
    throw const CommunityException(
      'This notification is unavailable.',
      code: 'invalid-id',
    );
  }
  return value;
}

int _boundedLimit(int value) {
  if (value < 1) throw const CommunityException('Load at least one item.');
  return value;
}

bool _definitelyRejected(Object error) =>
    error is CommunityException ||
    error is FirebaseException &&
        const <String>{
          'permission-denied',
          'invalid-argument',
          'failed-precondition',
        }.contains(error.code);
int _count(Object? value) {
  if (value is int && value >= 0) return value;
  throw const CommunityException(
    'This community item could not be read. Please refresh.',
    code: 'invalid-data',
  );
}

String _string(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is String && value.isNotEmpty) return value;
  throw const CommunityException(
    'This community item could not be read. Please refresh.',
    code: 'invalid-data',
  );
}

DateTime _date(Object? value) {
  if (value is Timestamp) return value.toDate();
  throw const CommunityException(
    'This community item has not finished syncing.',
    code: 'invalid-data',
  );
}

Future<T> _request<T>(
  Future<T> Function() action, {
  bool mutating = false,
}) async {
  try {
    return await action().timeout(FirebaseCommunityRepository._timeout);
  } on CommunityException {
    rethrow;
  } on TimeoutException {
    throw CommunityException(
      mutating
          ? 'Confirmation is taking longer than expected. Check the feed before retrying; this request may still finish.'
          : 'The connection is taking too long. Check your internet connection and try again.',
      code: mutating ? 'pending' : 'timeout',
    );
  } catch (error) {
    throw _safeError(error);
  }
}

Stream<T> _safeStream<T>(Stream<T> source) => source.transform(
  StreamTransformer<T, T>.fromHandlers(
    handleError: (Object error, StackTrace stack, EventSink<T> sink) {
      sink.addError(_safeError(error), stack);
    },
  ),
);

CommunityException _safeError(Object error) {
  if (error is CommunityException) return error;
  final code = error is FirebaseException ? error.code : 'unknown';
  final message = switch (code) {
    'permission-denied' || 'unauthorized' =>
      'Community access was denied. Verify your email and sign in again. If this continues, the community security setup may need attention.',
    'unauthenticated' => 'Please sign in again to use the community.',
    'unavailable' || 'network-request-failed' || 'retry-limit-exceeded' =>
      'The community could not connect. Check your internet connection and try again.',
    'failed-precondition' =>
      'The community is still being configured. Its database or search indexes may not be ready yet.',
    'bucket-not-found' || 'project-not-found' =>
      'Community photo storage has not been enabled for this app yet.',
    'quota-exceeded' || 'resource-exhausted' =>
      'The community service has reached its current limit. Please try again later.',
    'canceled' => 'The request was canceled. Please try again.',
    'aborted' => 'The post changed while saving. Refresh it and try again.',
    'deadline-exceeded' =>
      'The request could not be confirmed. Check the feed before retrying.',
    _ => 'The community could not finish this request. Please try again.',
  };
  return CommunityException(
    message,
    code: code == 'deadline-exceeded' ? 'pending' : code,
  );
}
