import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:project_bugbite/data/models/community_post.dart';
import 'package:project_bugbite/data/services/community_repository.dart';
import 'package:project_bugbite/data/services/firebase_community_repository.dart';

void main() {
  final createdAt = DateTime.utc(2026, 9, 13, 12);
  Map<String, dynamic> remotePost() => <String, dynamic>{
    'authorId': 'account-a',
    'author': 'Member A',
    'location': 'Your area',
    'createdAt': Timestamp.fromDate(createdAt),
    'possibleMatch': 'Other garden insect',
    'body': 'A shared observation, not a diagnosis.',
    'guideId': null,
    'tags': <String>['itchy', 'outdoors'],
    'status': 'published',
    'imagePath': 'communityPhotos/account-a/post-1/photo.jpg',
    'likeCount': 3,
    'commentCount': 74,
    'lastCommentId': 'comment-74',
  };

  test(
    'cloud post preserves custom match, photo path and full comment count',
    () {
      final post = communityPostFromFirestore('post-1', remotePost());
      expect(post.authorId, 'account-a');
      expect(post.guideId, isNull);
      expect(post.possibleMatch, 'Other garden insect');
      expect(post.createdAt.toUtc(), createdAt);
      expect(post.imagePath, 'communityPhotos/account-a/post-1/photo.jpg');
      expect(post.imageBytes, isNull);
      expect(post.comments, isEmpty);
      expect(post.totalComments, 74);
      expect(post.likes, 3);
      expect(post.liked, isFalse);
      expect(post.publishedPostId, isNull);
    },
  );

  test(
    'pending or invalid server timestamps are not replaced by invented dates',
    () {
      final data = remotePost()..['createdAt'] = null;
      expect(
        () => communityPostFromFirestore('post-1', data),
        throwsA(isA<CommunityException>()),
      );
    },
  );

  test('negative community counters are rejected', () {
    final data = remotePost()..['commentCount'] = -1;
    expect(
      () => communityPostFromFirestore('post-1', data),
      throwsA(isA<CommunityException>()),
    );
  });

  test('cloud comment records retain author and server time', () {
    final comment =
        communityCommentFromFirestore('comment-1', <String, dynamic>{
          'authorId': 'account-b',
          'author': 'Member B',
          'body': 'Thank you for sharing.',
          'createdAt': Timestamp.fromDate(createdAt),
        });
    expect(comment.id, 'comment-1');
    expect(comment.authorId, 'account-b');
    expect(comment.createdAt.toUtc(), createdAt);
    expect(comment.isReply, isFalse);
    expect(comment.replyToCommentId, isNull);
    expect(comment.replyToAuthorId, isNull);
    expect(comment.replyToAuthor, isNull);
  });

  test('reply metadata survives cloud decoding and local JSON round trip', () {
    final comment = communityCommentFromFirestore('reply-1', <String, dynamic>{
      'authorId': 'account-b',
      'author': 'Member B',
      'body': 'Thank you for the update.',
      'createdAt': Timestamp.fromDate(createdAt),
      'replyToCommentId': 'comment-1',
      'replyToAuthorId': 'account-a',
      'replyToAuthor': 'Member A',
    });
    final restored = CommunityComment.fromJson(comment.toJson());
    expect(restored.isReply, isTrue);
    expect(restored.replyToCommentId, 'comment-1');
    expect(restored.replyToAuthorId, 'account-a');
    expect(restored.replyToAuthor, 'Member A');
    expect(restored.body, comment.body);
    expect(restored.createdAt, comment.createdAt);
  });

  test('reply codec rejects an incomplete target identity', () {
    expect(
      () => communityCommentFromFirestore('reply-1', <String, dynamic>{
        'authorId': 'account-b',
        'author': 'Member B',
        'body': 'Thank you for the update.',
        'createdAt': Timestamp.fromDate(createdAt),
        'replyToCommentId': 'comment-1',
      }),
      throwsA(isA<CommunityException>()),
    );
  });

  test('private activity decodes without a retained comment preview', () {
    final notification =
        communityNotificationFromFirestore('post-1_reply-1', <String, dynamic>{
          'recipientId': 'account-a',
          'actorId': 'account-b',
          'actorName': 'Member B',
          'postId': 'post-1',
          'commentId': 'reply-1',
          'replyToCommentId': 'comment-1',
          'createdAt': Timestamp.fromDate(createdAt),
          'isRead': false,
        });
    expect(notification.id, 'post-1_reply-1');
    expect(notification.recipientId, 'account-a');
    expect(notification.actorId, 'account-b');
    expect(notification.actorName, 'Member B');
    expect(notification.postId, 'post-1');
    expect(notification.commentId, 'reply-1');
    expect(notification.replyToCommentId, 'comment-1');
    expect(notification.isReply, isTrue);
    expect(notification.isRead, isFalse);
    expect(notification.createdAt.toUtc(), createdAt);
    final read = notification.copyWith(isRead: true);
    expect(read.isRead, isTrue);
    expect(read.commentId, notification.commentId);
    expect(read.replyToCommentId, notification.replyToCommentId);
    expect(notification.isRead, isFalse);
  });

  test(
    'post activity differs from reply activity and needs a real read flag',
    () {
      final data = <String, dynamic>{
        'recipientId': 'account-a',
        'actorId': 'account-b',
        'actorName': 'Member B',
        'postId': 'post-1',
        'commentId': 'comment-1',
        'replyToCommentId': null,
        'createdAt': Timestamp.fromDate(createdAt),
        'isRead': true,
      };
      expect(
        communityNotificationFromFirestore('post-1_comment-1', data).isReply,
        isFalse,
      );
      data['isRead'] = 'false';
      expect(
        () => communityNotificationFromFirestore('post-1_comment-1', data),
        throwsA(isA<CommunityException>()),
      );
    },
  );

  test('activity with an unconfirmed timestamp does not invent a date', () {
    expect(
      () => communityNotificationFromFirestore(
        'post-1_comment-1',
        <String, dynamic>{
          'recipientId': 'account-a',
          'actorId': 'account-b',
          'actorName': 'Member B',
          'postId': 'post-1',
          'commentId': 'comment-1',
          'replyToCommentId': null,
          'createdAt': null,
          'isRead': false,
        },
      ),
      throwsA(isA<CommunityException>()),
    );
  });

  test('legacy local JSON stays local and derives its own comment count', () {
    final post = CommunityPost.fromJson(<String, Object?>{
      'id': 'old-local-post',
      'authorId': 'account-a',
      'author': 'Member A',
      'location': 'Your area',
      'createdAt': createdAt.toIso8601String(),
      'possibleMatch': 'Mosquito',
      'body': 'An older device-only entry.',
      'guideId': 'mosquito',
      'tags': <Object?>['Itchy'],
      'comments': <Object?>[
        <String, Object?>{
          'id': 'local-comment',
          'authorId': 'account-a',
          'author': 'Member A',
          'body': 'Updated observation.',
          'createdAt': createdAt.toIso8601String(),
        },
      ],
    });
    expect(post.imagePath, isNull);
    expect(post.remoteCommentCount, isNull);
    expect(post.publishedPostId, isNull);
    expect(post.totalComments, 1);
    final publishedArchive = post.copyWith(publishedPostId: 'cloud-copy');
    final restored = CommunityPost.fromJson(publishedArchive.toJson());
    expect(restored.publishedPostId, 'cloud-copy');
    expect(restored.comments.single.id, 'local-comment');
    expect(restored.comments.single.isReply, isFalse);
    expect(
      restored.comments.single.toJson().containsKey('replyToCommentId'),
      isFalse,
    );
    expect(restored.copyWith(liked: true).publishedPostId, 'cloud-copy');
  });

  test('cloud metadata round-trips without embedding photo bytes', () {
    final original = communityPostFromFirestore('post-1', remotePost());
    final json = original.toJson();
    expect(json.containsKey('imageBase64'), isFalse);
    final restored = CommunityPost.fromJson(json);
    expect(restored.imagePath, original.imagePath);
    expect(restored.totalComments, 74);
  });

  test('only authenticated community photo paths are accepted', () {
    expect(
      isCommunityPhotoPath('communityPhotos/member_1/post-2/photo.jpg'),
      isTrue,
    );
    for (final path in <String>[
      'https://example.com/photo.jpg',
      'gs://other-bucket/photo.jpg',
      'communityPhotos/member_1/../photo.jpg',
      'communityPhotos/member_1/post-2/photo.jpg?token=public',
      'privateProfiles/member_1/photo.jpg',
    ]) {
      expect(isCommunityPhotoPath(path), isFalse, reason: path);
    }
  });

  test('picked photo is resized, oriented, JPEG encoded and GPS removed', () {
    final original = img.Image(width: 1600, height: 800);
    original.exif.imageIfd.orientation = 6;
    original.exif.gpsIfd.gpsLatitude = 37.77;
    original.exif.gpsIfd.gpsLongitude = -122.42;
    final input = Uint8List.fromList(img.encodeJpg(original));
    final result = prepareCommunityPhoto(input);
    final decoded = img.decodeJpg(result)!;
    expect(result.take(2), <int>[0xff, 0xd8]);
    expect(decoded.width, 640);
    expect(decoded.height, 1280);
    expect(decoded.exif.gpsIfd.gpsLatitude, isNull);
    expect(decoded.exif.gpsIfd.gpsLongitude, isNull);
    expect(decoded.exif.imageIfd.orientation, isNull);
    expect(result.length, lessThan(5 * 1024 * 1024));
  });

  test('invalid or oversized picked files have user-safe errors', () {
    for (final bytes in <Uint8List>[
      Uint8List(0),
      Uint8List.fromList(<int>[1, 2, 3, 4]),
      Uint8List(20 * 1024 * 1024 + 1),
    ]) {
      expect(
        () => prepareCommunityPhoto(bytes),
        throwsA(isA<CommunityException>()),
      );
    }
  });

  test('unconfirmed writes are distinguishable from definite failures', () {
    expect(
      const CommunityException(
        'Wait for confirmation.',
        code: 'pending',
      ).isPending,
      isTrue,
    );
    expect(
      const CommunityException(
        'No access.',
        code: 'permission-denied',
      ).isPending,
      isFalse,
    );
  });
}
