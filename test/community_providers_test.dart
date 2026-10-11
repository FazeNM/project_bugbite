import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_bugbite/data/models/community_post.dart';
import 'package:project_bugbite/data/services/auth_service.dart';
import 'package:project_bugbite/data/services/community_repository.dart';
import 'package:project_bugbite/state/auth_controller.dart';
import 'package:project_bugbite/state/community_providers.dart';

import 'support/memory_community_repository.dart';

const _accountA = AuthUser(
  id: 'account-a',
  email: 'a@example.com',
  displayName: 'Member A',
  photoUrl: null,
  isEmailVerified: true,
);
const _accountB = AuthUser(
  id: 'account-b',
  email: 'b@example.com',
  displayName: 'Member B',
  photoUrl: null,
  isEmailVerified: true,
);
const _unverified = AuthUser(
  id: 'new-account',
  email: 'new@example.com',
  displayName: 'New member',
  photoUrl: null,
  isEmailVerified: false,
);

final _sessionProvider = NotifierProvider<_Session, AuthUser?>(_Session.new);

class _Session extends Notifier<AuthUser?> {
  @override
  AuthUser? build() => _accountA;

  void choose(AuthUser? user) => state = user;
}

CommunityPost _existingPost() => CommunityPost(
  id: 'shared-post',
  authorId: _accountA.id,
  author: _accountA.displayName!,
  location: 'Your area',
  createdAt: DateTime.utc(2026, 9, 13),
  possibleMatch: 'Mosquito',
  body: 'An observation shared with the community.',
  guideId: 'mosquito',
  tags: const ['itchy', 'outdoors'],
  comments: [
    CommunityComment(
      id: 'original-comment',
      authorId: _accountA.id,
      author: _accountA.displayName!,
      body: 'An update from the author.',
      createdAt: DateTime.utc(2026, 9, 13, 1),
    ),
  ],
);

ProviderContainer _container(MemoryCommunityRepository repository) {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      currentUserProvider.overrideWith((ref) => ref.watch(_sessionProvider)),
      communityRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await repository.dispose();
  });
  return container;
}

Future<void> _settle(ProviderContainer container) async {
  await container.pump();
  await Future<void>.delayed(Duration.zero);
  await container.pump();
}

Future<String?> _publish(CommunityActions actions, String id) =>
    actions.publishPost(
      draftId: id,
      possibleMatch: 'Other garden insect',
      body: 'An observation shared by the current account.',
      guideId: null,
      tags: const ['itchy'],
    );

void main() {
  test(
    'reply notifies only its recipient and inbox clears on account changes',
    () async {
      final repository = MemoryCommunityRepository(posts: [_existingPost()]);
      final container = _container(repository);
      final inbox = container.listen(
        communityNotificationsProvider(50),
        (_, _) {},
      );
      final count = container.listen(
        communityUnreadNotificationCountProvider,
        (_, _) {},
      );
      await _settle(container);
      container.read(_sessionProvider.notifier).choose(_accountB);
      await _settle(container);
      expect(
        await container
            .read(communityActionsProvider.notifier)
            .addComment(
              postId: 'shared-post',
              body: 'Thank you for the update.',
              replyToCommentId: 'original-comment',
            ),
        isTrue,
      );
      await _settle(container);
      expect(inbox.read().requireValue, isEmpty);
      expect(count.read().requireValue, 0);
      final reply = repository.comments['shared-post']!.last;
      expect(reply.replyToAuthorId, _accountA.id);
      expect(reply.replyToAuthor, _accountA.displayName);
      expect(reply.replyToCommentId, 'original-comment');

      container.read(_sessionProvider.notifier).choose(_accountA);
      await _settle(container);
      final notification = inbox.read().requireValue.single;
      expect(notification.commentId, reply.id);
      expect(notification.isReply, isTrue);
      expect(notification.actorId, _accountB.id);
      expect(count.read().requireValue, 1);
      expect(
        await container
            .read(communityActionsProvider.notifier)
            .markNotificationRead(notificationId: notification.id),
        isTrue,
      );
      await _settle(container);
      expect(count.read().requireValue, 0);
      expect(inbox.read().requireValue.single.isRead, isTrue);
      // Acknowledgement is idempotent and persists in the shared server boundary.
      expect(
        await container
            .read(communityActionsProvider.notifier)
            .markNotificationRead(notificationId: notification.id),
        isTrue,
      );
      container.read(_sessionProvider.notifier).choose(null);
      await _settle(container);
      expect(inbox.read().requireValue, isEmpty);
      expect(count.read().requireValue, 0);
      container.read(_sessionProvider.notifier).choose(_accountA);
      await _settle(container);
      expect(inbox.read().requireValue.single.isRead, isTrue);
    },
  );

  test(
    'root comments notify post owner but self replies do not notify',
    () async {
      final repository = MemoryCommunityRepository(posts: [_existingPost()]);
      final container = _container(repository);
      expect(
        await container
            .read(communityActionsProvider.notifier)
            .addComment(
              postId: 'shared-post',
              body: 'My own additional observation.',
              replyToCommentId: 'original-comment',
            ),
        isTrue,
      );
      expect(repository.notifications, isEmpty);
      container.read(_sessionProvider.notifier).choose(_accountB);
      await _settle(container);
      expect(
        await container
            .read(communityActionsProvider.notifier)
            .addComment(
              postId: 'shared-post',
              body: 'A new top-level comment.',
            ),
        isTrue,
      );
      final notification = repository.notifications[_accountA.id]!.single;
      expect(notification.isReply, isFalse);
      expect(notification.actorId, _accountB.id);
    },
  );

  test(
    'missing reply target and failed notification acknowledgement are readable',
    () async {
      final repository = MemoryCommunityRepository(posts: [_existingPost()]);
      final container = _container(repository);
      expect(
        await container
            .read(communityActionsProvider.notifier)
            .addComment(
              postId: 'shared-post',
              body: 'This must not become an unrelated comment.',
              replyToCommentId: 'missing',
            ),
        isFalse,
      );
      expect(repository.comments['shared-post'], hasLength(1));
      expect(repository.notifications, isEmpty);
      expect(
        container.read(communityActionsProvider).errorMessage,
        contains('no longer available'),
      );
      repository.failWrites = true;
      expect(
        await container
            .read(communityActionsProvider.notifier)
            .markNotificationRead(notificationId: 'missing'),
        isFalse,
      );
      expect(
        container.read(communityActionsProvider).errorMessage,
        MemoryCommunityRepository.failureMessage,
      );
    },
  );

  test(
    'unverified accounts cannot read private notifications or mark them read',
    () async {
      final repository = MemoryCommunityRepository(posts: [_existingPost()]);
      final container = _container(repository);
      container.read(_sessionProvider.notifier).choose(_unverified);
      final inbox = container.listen(
        communityNotificationsProvider(50),
        (_, _) {},
      );
      final unread = container.listen(
        communityUnreadNotificationCountProvider,
        (_, _) {},
      );
      await _settle(container);
      expect(inbox.read().requireValue, isEmpty);
      expect(unread.read().requireValue, 0);
      expect(
        await container
            .read(communityActionsProvider.notifier)
            .markNotificationRead(notificationId: 'missing'),
        isFalse,
      );
      expect(
        container.read(communityActionsProvider).errorMessage,
        contains('verified account'),
      );
    },
  );

  test(
    'accounts see the same shared posts and comments while likes stay personal',
    () async {
      final repository = MemoryCommunityRepository(posts: [_existingPost()]);
      final container = _container(repository);
      final feed = communityFeedProvider((
        tag: null,
        authorId: null,
        limit: 50,
      ));
      final comments = communityCommentsProvider((
        postId: 'shared-post',
        limit: 50,
      ));
      final liked = communityLikedProvider('shared-post');
      container.listen(feed, (_, _) {});
      container.listen(comments, (_, _) {});
      container.listen(liked, (_, _) {});

      expect((await container.read(feed.future)).single.id, 'shared-post');
      expect(
        (await container.read(comments.future)).single.authorId,
        _accountA.id,
      );
      expect(
        await container
            .read(communityActionsProvider.notifier)
            .setLiked(postId: 'shared-post', liked: true),
        isTrue,
      );
      await _settle(container);
      expect(container.read(liked).requireValue, isTrue);

      container.read(_sessionProvider.notifier).choose(_accountB);
      await _settle(container);
      expect((await container.read(feed.future)).single.authorId, _accountA.id);
      expect(
        (await container.read(comments.future)).single.id,
        'original-comment',
      );
      expect(await container.read(liked.future), isFalse);
      expect(
        await container
            .read(communityActionsProvider.notifier)
            .addComment(
              postId: 'shared-post',
              body: 'A reply from another account.',
            ),
        isTrue,
      );
      await _settle(container);

      container.read(_sessionProvider.notifier).choose(_accountA);
      await _settle(container);
      final replies = await container.read(comments.future);
      expect(replies, hasLength(2));
      expect(
        replies.any((comment) => comment.authorId == _accountB.id),
        isTrue,
      );
      expect((await container.read(feed.future)).single.totalComments, 2);
      expect(await container.read(liked.future), isTrue);
      expect(repository.posts, hasLength(1));
    },
  );

  test(
    'sign-out clears all watched community streams and ignores later server updates',
    () async {
      final repository = MemoryCommunityRepository(posts: [_existingPost()]);
      final container = _container(repository);
      final feed = communityFeedProvider((
        tag: null,
        authorId: null,
        limit: 50,
      ));
      final comments = communityCommentsProvider((
        postId: 'shared-post',
        limit: 50,
      ));
      final post = communityPostProvider('shared-post');
      final liked = communityLikedProvider('shared-post');
      container.listen(feed, (_, _) {});
      container.listen(comments, (_, _) {});
      container.listen(post, (_, _) {});
      container.listen(liked, (_, _) {});
      await container.read(feed.future);
      await container.read(comments.future);
      await container.read(post.future);
      await container.read(liked.future);

      container.read(_sessionProvider.notifier).choose(null);
      await _settle(container);
      expect(await container.read(feed.future), isEmpty);
      expect(await container.read(comments.future), isEmpty);
      expect(await container.read(post.future), isNull);
      expect(await container.read(liked.future), isFalse);

      await repository.publishPost(
        author: _accountB,
        possibleMatch: 'Mosquito',
        body: 'Another account posts while this device is signed out.',
        guideId: 'mosquito',
        tags: const [],
      );
      await _settle(container);
      expect(container.read(feed).requireValue, isEmpty);
      expect(container.read(comments).requireValue, isEmpty);
      expect(repository.posts, hasLength(2));
    },
  );

  test(
    'unverified accounts cannot read community data or perform any mutation',
    () async {
      final repository = MemoryCommunityRepository(posts: [_existingPost()]);
      final container = _container(repository);
      container.read(_sessionProvider.notifier).choose(_unverified);
      final feed = communityFeedProvider((
        tag: null,
        authorId: null,
        limit: 50,
      ));
      container.listen(feed, (_, _) {});
      expect(await container.read(feed.future), isEmpty);
      final actions = container.read(communityActionsProvider.notifier);
      expect(await _publish(actions, 'not-published'), isNull);
      expect(
        await actions.addComment(postId: 'shared-post', body: 'Not saved.'),
        isFalse,
      );
      expect(
        await actions.setLiked(postId: 'shared-post', liked: true),
        isFalse,
      );
      expect(await actions.deletePost(postId: 'shared-post'), isFalse);
      expect(
        await actions.deleteComment(
          postId: 'shared-post',
          commentId: 'original-comment',
        ),
        isFalse,
      );
      expect(
        await actions.reportPost(postId: 'shared-post', reason: 'Not sent.'),
        isFalse,
      );
      expect(
        container.read(communityActionsProvider).errorMessage,
        contains('verified account'),
      );
      expect(container.read(communityActionsProvider).isLoading, isFalse);
      expect(repository.posts.single.id, 'shared-post');
      expect(repository.comments['shared-post'], hasLength(1));
      expect(repository.likedBy, isEmpty);
      expect(repository.reports, isEmpty);
    },
  );

  test(
    'failed publishing is readable and never reports success or inserts a post',
    () async {
      final repository = MemoryCommunityRepository()..failWrites = true;
      final container = _container(repository);
      final actions = container.read(communityActionsProvider.notifier);
      expect(await _publish(actions, 'retryable-draft'), isNull);
      expect(
        container.read(communityActionsProvider).errorMessage,
        MemoryCommunityRepository.failureMessage,
      );
      expect(container.read(communityActionsProvider).isLoading, isFalse);
      expect(repository.posts, isEmpty);

      repository.failWrites = false;
      expect(await _publish(actions, 'retryable-draft'), 'retryable-draft');
      expect(container.read(communityActionsProvider).errorMessage, isNull);
      expect(repository.posts.single.authorId, _accountA.id);
    },
  );

  test(
    'read failures remain readable and a later live event recovers the feed',
    () async {
      final repository = MemoryCommunityRepository(posts: [_existingPost()])
        ..failReads = true;
      final container = _container(repository);
      final feed = communityFeedProvider((
        tag: null,
        authorId: null,
        limit: 50,
      ));
      container.listen(feed, (_, _) {});
      await expectLater(
        container.read(feed.future),
        throwsA(isA<CommunityException>()),
      );
      expect(
        container.read(feed).error.toString(),
        MemoryCommunityRepository.failureMessage,
      );
      repository.failReads = false;
      repository.emit();
      await _settle(container);
      expect(container.read(feed).requireValue.single.id, 'shared-post');
    },
  );

  test(
    'loading state blocks duplicate actions until publication is confirmed',
    () async {
      final repository = _DelayedRepository();
      final container = _container(repository);
      final actions = container.read(communityActionsProvider.notifier);
      final pending = _publish(actions, 'one-draft');
      await repository.started.future;
      expect(container.read(communityActionsProvider).isLoading, isTrue);
      expect(repository.posts, isEmpty);
      expect(await _publish(actions, 'second-tap'), isNull);
      repository.release.complete();
      expect(await pending, 'one-draft');
      expect(container.read(communityActionsProvider).isLoading, isFalse);
      expect(repository.posts.single.id, 'one-draft');
    },
  );

  test(
    'late previous-account success cannot clear the new account action state',
    () async {
      final repository = _DelayedRepository();
      final container = _container(repository);
      final actions = container.read(communityActionsProvider.notifier);
      final previousAction = _publish(actions, 'account-a-draft');
      await repository.started.future;
      container.read(_sessionProvider.notifier).choose(_accountB);
      await _settle(container);
      expect(container.read(communityActionsProvider).isLoading, isFalse);
      repository.failWrites = true;
      expect(
        await _publish(
          container.read(communityActionsProvider.notifier),
          'account-b-draft',
        ),
        isNull,
      );
      final newError = container.read(communityActionsProvider).errorMessage;
      expect(newError, MemoryCommunityRepository.failureMessage);

      repository.failWrites = false;
      repository.release.complete();
      expect(await previousAction, isNull);
      expect(container.read(currentUserProvider)?.id, _accountB.id);
      expect(container.read(communityActionsProvider).errorMessage, newError);
      expect(repository.posts.single.authorId, _accountA.id);
    },
  );

  test(
    'late previous-account errors are not shown after switching accounts',
    () async {
      final repository = _DelayedRepository();
      final container = _container(repository);
      final previousAction = _publish(
        container.read(communityActionsProvider.notifier),
        'old-draft',
      );
      await repository.started.future;
      container.read(_sessionProvider.notifier).choose(_accountB);
      await _settle(container);
      repository.failWrites = true;
      repository.release.complete();
      expect(await previousAction, isNull);
      expect(container.read(communityActionsProvider).errorMessage, isNull);
      expect(container.read(communityActionsProvider).isLoading, isFalse);
      expect(repository.posts, isEmpty);
    },
  );

  test(
    'returning to the same account does not revive an earlier session action',
    () async {
      final repository = _DelayedRepository();
      final container = _container(repository);
      container.listen(communityActionsProvider, (_, _) {});
      final previousAction = _publish(
        container.read(communityActionsProvider.notifier),
        'first-session-draft',
      );
      await repository.started.future;
      container.read(_sessionProvider.notifier).choose(_accountB);
      await _settle(container);
      container.read(_sessionProvider.notifier).choose(_accountA);
      await _settle(container);

      repository.failWrites = true;
      expect(
        await _publish(
          container.read(communityActionsProvider.notifier),
          'new-session-draft',
        ),
        isNull,
      );
      final newError = container.read(communityActionsProvider).errorMessage;
      expect(newError, MemoryCommunityRepository.failureMessage);

      repository.failWrites = false;
      repository.release.complete();
      expect(await previousAction, isNull);
      expect(container.read(currentUserProvider)?.id, _accountA.id);
      expect(container.read(communityActionsProvider).errorMessage, newError);
      expect(repository.posts.single.id, 'first-session-draft');
    },
  );
}

class _DelayedRepository extends MemoryCommunityRepository {
  final started = Completer<void>();
  final release = Completer<void>();
  bool _hasDelayed = false;

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
    if (!_hasDelayed) {
      _hasDelayed = true;
      started.complete();
      await release.future;
    }
    return super.publishPost(
      author: author,
      possibleMatch: possibleMatch,
      body: body,
      guideId: guideId,
      tags: tags,
      imageBytes: imageBytes,
      draftId: draftId,
    );
  }
}
