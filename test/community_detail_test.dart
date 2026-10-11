import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:project_bugbite/app/app.dart';
import 'package:project_bugbite/app/app_router.dart';
import 'package:project_bugbite/core/config/community_config.dart';
import 'package:project_bugbite/features/community/widgets/add_bite_widgets.dart';
import 'package:project_bugbite/data/models/community_post.dart';
import 'package:project_bugbite/data/models/community_notification.dart';
import 'package:project_bugbite/data/services/app_persistence_service.dart';
import 'package:project_bugbite/data/services/auth_service.dart';
import 'package:project_bugbite/data/services/profile_data_service.dart';
import 'package:project_bugbite/state/auth_controller.dart';
import 'package:project_bugbite/state/community_providers.dart';
import 'package:project_bugbite/state/persistence_providers.dart';
import 'package:project_bugbite/state/profile_data_controller.dart';

import 'support/memory_user_data_store.dart';
import 'support/memory_community_repository.dart';

const _user = AuthUser(
  id: 'community-test-user',
  email: 'community@example.com',
  displayName: 'Community Tester',
  photoUrl: null,
  isEmailVerified: true,
);

const _postBody = 'A shared experience with a complete discussion to read.';

void main() {
  testWidgets('Reply targets a comment and notifies its author', (
    tester,
  ) async {
    final target = CommunityComment(
      id: 'target-comment',
      authorId: 'alice',
      author: 'Alice',
      body: 'Thanks for sharing your experience.',
      createdAt: DateTime(2026, 9, 1),
    );
    final app = await _pumpCommunity(tester, post: _post(comments: [target]));
    app.router.go('/community/post/discussion-post');
    await tester.pumpAndSettle();
    await _reveal(
      tester,
      find.byKey(const ValueKey('reply-to-target-comment')),
    );
    await tester.tap(find.byKey(const ValueKey('reply-to-target-comment')));
    await tester.pumpAndSettle();

    expect(find.text('Reply to Alice'), findsOneWidget);
    expect(find.text('Alice wrote'), findsOneWidget);
    const response = 'I appreciate you sharing your own experience too.';
    await tester.enterText(find.byType(TextFormField), response);
    await tester.tap(find.text('Post reply'));
    await tester.pumpAndSettle();

    final reply = app.community.comments['discussion-post']!.last;
    expect(reply.body, response);
    expect(reply.replyToCommentId, target.id);
    expect(reply.replyToAuthorId, target.authorId);
    expect(reply.replyToAuthor, target.author);
    expect(app.community.notifications['alice']!.single.commentId, reply.id);
    expect(app.community.notifications['another-member'], isNull);
    await _reveal(tester, find.text('Replying to Alice'));
    expect(find.text('Replying to Alice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a removed reply target leaves the draft and a readable error', (
    tester,
  ) async {
    final target = CommunityComment(
      id: 'removed-target',
      authorId: 'alice',
      author: 'Alice',
      body: 'An experience I later remove.',
      createdAt: DateTime(2026, 9, 1),
    );
    final app = await _pumpCommunity(tester, post: _post(comments: [target]));
    app.router.go('/community/post/discussion-post');
    await tester.pumpAndSettle();
    await _reveal(
      tester,
      find.byKey(const ValueKey('reply-to-removed-target')),
    );
    await tester.tap(find.byKey(const ValueKey('reply-to-removed-target')));
    await tester.pumpAndSettle();
    const draft = 'Thank you for writing about your experience.';
    await tester.enterText(find.byType(TextFormField), draft);
    app.community.comments['discussion-post']!.clear();
    app.community.emit();
    await tester.tap(find.text('Post reply'));
    await tester.pumpAndSettle();

    expect(find.text('Reply to Alice'), findsOneWidget);
    expect(
      find.text(
        'This comment is no longer available. Choose another comment to reply to.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      draft,
    );
    expect(app.community.comments['discussion-post'], isEmpty);
    expect(app.community.notifications, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'profile notification opens an older comment outside the first 50',
    (tester) async {
      final comments = List.generate(
        60,
        (index) => CommunityComment(
          id: 'reply-$index',
          authorId: 'another-member',
          author: 'Another Member',
          body: 'A distinct conversation response $index.',
          createdAt: DateTime(2026, 9, 1, 12, index),
          replyToCommentId: 'my-original-comment',
          replyToAuthorId: _user.id,
          replyToAuthor: _user.displayName,
        ),
      );
      final app = await _pumpCommunity(tester, post: _post(comments: comments));
      app.community.notifications[_user.id] = [
        CommunityNotification(
          id: 'an-unread-notification',
          recipientId: _user.id,
          actorId: 'another-member',
          actorName: 'Another Member',
          postId: 'discussion-post',
          commentId: 'reply-0',
          replyToCommentId: 'my-original-comment',
          createdAt: DateTime(2026, 9, 2),
          isRead: false,
        ),
      ];
      app.community.emit();
      app.router.go('/profile');
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('profile-unread-notification-count')),
        findsOneWidget,
      );
      expect(
        find.text('Another Member replied to your comment'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('notification-an-unread-notification')),
      );
      await tester.pumpAndSettle();

      expect(app.community.notifications[_user.id]!.single.isRead, isTrue);
      expect(_path(app.router), '/community/post/discussion-post');
      expect(app.router.state.uri.queryParameters['comment'], 'reply-0');
      expect(find.text('Selected comment'), findsOneWidget);
      expect(find.text('A distinct conversation response 0.'), findsOneWidget);
      expect(find.text('Original post'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(_path(app.router), '/profile');
      expect(
        find.byKey(const ValueKey('profile-unread-notification-count')),
        findsNothing,
      );
    },
  );

  testWidgets('notification inbox shows loading, error, and recovery states', (
    tester,
  ) async {
    final app = await _pumpCommunity(tester);
    app.community.holdReads = true;
    app.router.go('/profile');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CircularProgressIndicator &&
            widget.semanticsLabel == 'Loading notifications',
      ),
      findsOneWidget,
    );
    app.community.holdReads = false;
    app.community.failReads = true;
    app.community.emit();
    await tester.pumpAndSettle();
    expect(find.text('Notifications could not load'), findsOneWidget);
    app.community.failReads = false;
    app.community.emit();
    await tester.pumpAndSettle();
    expect(find.text('You’re all caught up'), findsOneWidget);
    expect(find.text('Notifications could not load'), findsNothing);
    expect(
      find.text(
        'Replies appear here when you open the app. Phone notifications are coming soon.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected comment is not duplicated in the conversation list', (
    tester,
  ) async {
    final app = await _pumpCommunity(
      tester,
      post: _post(
        comments: [
          CommunityComment(
            id: 'selected-reply',
            authorId: 'someone',
            author: 'Member',
            body: 'This selected reply should only appear once.',
            createdAt: DateTime(2026, 9, 2),
          ),
        ],
      ),
    );
    app.router.go('/community/post/discussion-post?comment=selected-reply');
    await tester.pumpAndSettle();
    expect(
      find.text('This selected reply should only appear once.'),
      findsOneWidget,
    );
    await _reveal(tester, find.text('Comments (1)'));
    expect(
      find.text('This selected reply should only appear once.'),
      findsOneWidget,
    );
    app.router.go('/community/post/discussion-post?comment=missing-reply');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 1200));
    await tester.pumpAndSettle();
    expect(find.text('Comment no longer available'), findsOneWidget);
    expect(find.text('Original post'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'legacy photo note stays private until reviewed and explicitly published as text',
    (tester) async {
      final photo = File(
        'assets/images/bites/mosquito_bite.jpg',
      ).readAsBytesSync();
      final localPost = _post(
        authorId: _user.id,
        imageBytes: photo,
        comments: [
          CommunityComment(
            id: 'old-private-comment',
            authorId: 'someone',
            author: 'Member',
            body: 'This old local comment must not be copied.',
            createdAt: DateTime(2026, 9, 1),
          ),
        ],
      ).copyWith(likes: 12);
      final app = await _pumpCommunity(tester, localPosts: [localPost]);
      expect(app.community.posts, hasLength(1));
      app.router.go('/profile');
      await tester.pumpAndSettle();
      await _reveal(tester, find.text('Review & publish'));
      await tester.tap(find.text('Review & publish'));
      await tester.pumpAndSettle();
      await _reveal(tester, find.text('Share carefully'));
      await tester.tap(find.text('Share carefully'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Photo uploads are coming soon. Remove the photo to publish a text experience; the original private note keeps its photo.',
        ),
        findsOneWidget,
      );
      expect(app.community.posts, hasLength(1));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _reveal(tester, find.byTooltip('Remove photo'));
      await tester.tap(find.byTooltip('Remove photo'));
      await _reveal(tester, find.text('Share carefully'));
      await tester.tap(find.text('Share carefully'));
      await tester.pumpAndSettle();
      expect(
        find.text('Please acknowledge the safety note before sharing.'),
        findsOneWidget,
      );
      expect(app.community.posts, hasLength(1));
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await _reveal(tester, find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await _reveal(tester, find.text('Share carefully'));
      await tester.tap(find.text('Share carefully'));
      await tester.pumpAndSettle();
      final published = app.community.posts.firstWhere(
        (post) => post.authorId == _user.id,
      );
      expect(published.id, 'legacy-${_user.id}-${localPost.id}');
      expect(published.body, localPost.body);
      expect(published.likes, 0);
      expect(published.imagePath, isNull);
      expect(app.community.comments[published.id], isEmpty);
      final privateData = await AppPersistenceService(app.store).load(_user.id);
      expect(privateData!.posts.single.publishedPostId, published.id);
      expect(privateData.posts.single.imageBytes, photo);
      expect(privateData.posts.single.comments, hasLength(1));
      app.router.go('/profile');
      await tester.pumpAndSettle();
      expect(find.text('Review & publish'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('photo uploads show Coming soon without enabling the picker', (
    tester,
  ) async {
    final app = await _pumpCommunity(tester);
    await tester.tap(find.text('Add your experience'));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsOneWidget);
    expect(communityPhotoUploadsEnabled, isFalse);
    expect(find.text('You can still share a text experience.'), findsOneWidget);
    expect(find.text('Add a photo from your library'), findsNothing);
    expect(find.byType(PhotoAttachment), findsNothing);
    expect(
      find.textContaining('I have permission to share this photo.'),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('photo-coming-soon')));
    await tester.pumpAndSettle();
    expect(_path(app.router), '/add-bite');
    expect(app.community.posts, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Coming soon card fits a narrow screen with larger text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: PhotoComingSoon(),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Coming soon'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('own post removal requires confirmation and leaves the feed', (
    tester,
  ) async {
    final app = await _pumpCommunity(tester, post: _post(authorId: _user.id));
    await _reveal(tester, find.text(_postBody));
    await tester.tap(find.text(_postBody));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Post options'));
    await tester.pumpAndSettle();
    expect(find.text('Report post'), findsNothing);
    await tester.tap(find.text('Remove post'));
    await tester.pumpAndSettle();
    expect(app.community.posts, hasLength(1));
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(app.community.posts, isEmpty);
    expect(_path(app.router), '/community');
  });

  testWidgets('own comment can be removed and live count updates', (
    tester,
  ) async {
    final app = await _pumpCommunity(
      tester,
      post: _post(
        comments: [
          CommunityComment(
            id: 'owned-comment',
            authorId: _user.id,
            author: 'Me',
            body: 'A reply I later want to remove.',
            createdAt: DateTime(2026, 9, 2),
          ),
        ],
      ),
    );
    app.router.go('/community/post/discussion-post');
    await tester.pumpAndSettle();
    await _reveal(tester, find.byTooltip('Remove your comment'));
    await tester.tap(find.byTooltip('Remove your comment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(app.community.comments['discussion-post'], isEmpty);
    await _reveal(tester, find.text('Comments (0)'));
    expect(find.text('Comments (0)'), findsOneWidget);
  });

  testWidgets('another member post can be reported but not deleted', (
    tester,
  ) async {
    final app = await _pumpCommunity(tester);
    await _reveal(tester, find.byTooltip('Post options'));
    await tester.tap(find.byTooltip('Post options'));
    await tester.pumpAndSettle();
    expect(find.text('Remove post'), findsNothing);
    await tester.tap(find.text('Report post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spam or unrelated content'));
    await tester.pumpAndSettle();
    expect(app.community.reports.single.reason, 'Spam or unrelated content');
    expect(app.community.reports.single.userId, _user.id);
    expect(app.community.posts, hasLength(1));
  });

  testWidgets('conversation loads older replies beyond the first 50', (
    tester,
  ) async {
    final app = await _pumpCommunity(
      tester,
      post: _post(
        comments: List.generate(
          52,
          (index) => CommunityComment(
            id: 'reply-$index',
            authorId: 'someone',
            author: 'Member',
            body: 'Paginated response $index',
            createdAt: DateTime(2026, 9, 2, 12, index),
          ),
        ),
      ),
    );
    app.router.go('/community/post/discussion-post');
    await tester.pumpAndSettle();
    await _reveal(tester, find.byKey(const ValueKey('load-more-comments')));
    expect(find.text('Paginated response 0'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('load-more-comments')));
    await tester.pumpAndSettle();
    await _reveal(tester, find.text('Paginated response 0'));
    expect(find.text('Paginated response 0'), findsOneWidget);
    expect(find.byKey(const ValueKey('load-more-comments')), findsNothing);
  });

  testWidgets('post body opens all comments newest first', (tester) async {
    final comments = List<CommunityComment>.generate(
      6,
      (index) => CommunityComment(
        id: 'comment-$index',
        authorId: 'member-$index',
        author: 'Member ${index + 1}',
        body: 'Supportive reply number ${index + 1}.',
        createdAt: DateTime(2026, 9, 1, 12, index),
      ),
    );
    final app = await _pumpCommunity(
      tester,
      post: _post(comments: comments.reversed.toList()),
    );

    await _reveal(tester, find.text(_postBody));
    await tester.tap(find.text(_postBody));
    await tester.pumpAndSettle();

    expect(_path(app.router), '/community/post/discussion-post');
    await _reveal(tester, find.text('Comments (6)'));
    expect(find.text('Comments (6)'), findsOneWidget);
    await _reveal(tester, find.text('Supportive reply number 6.'));
    await _reveal(tester, find.text('Supportive reply number 5.'));
    expect(
      tester.getTopLeft(find.text('Supportive reply number 6.')).dy,
      lessThan(tester.getTopLeft(find.text('Supportive reply number 5.')).dy),
    );
    await _reveal(tester, find.text('Supportive reply number 1.'));
    expect(find.text('Supportive reply number 1.'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_path(app.router), '/community');
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('post photo and comment action both open the full post', (
    tester,
  ) async {
    final app = await _pumpCommunity(tester);

    await _reveal(tester, find.text('Possible mosquito'));
    await tester.tap(find.text('Possible mosquito'));
    await tester.pumpAndSettle();
    expect(_path(app.router), '/community/post/discussion-post');

    await _reveal(tester, find.text('No comments yet'));
    expect(find.text('No comments yet'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await _reveal(tester, find.text('Comment'));
    await tester.tap(find.text('Comment'));
    await tester.pumpAndSettle();
    expect(_path(app.router), '/community/post/discussion-post');
    expect(find.text('Add a supportive comment'), findsNothing);
    expect(find.text('Add a comment'), findsOneWidget);
  });

  testWidgets('missing post offers a safe return to the community', (
    tester,
  ) async {
    final app = await _pumpCommunity(tester);
    app.router.go('/community/post/missing-post');
    await tester.pumpAndSettle();

    expect(find.text('Post not found'), findsOneWidget);
    await tester.tap(find.text('Back to community'));
    await tester.pumpAndSettle();

    expect(_path(app.router), '/community');
    expect(find.text('Shared experiences'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed comment save keeps the draft and supports retry', (
    tester,
  ) async {
    final app = await _pumpCommunity(tester);
    await _reveal(tester, find.text(_postBody));
    await tester.tap(find.text(_postBody));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a comment'));
    await tester.pumpAndSettle();
    const draft = 'Thank you for sharing your experience so carefully.';
    await tester.enterText(find.byType(TextFormField), draft);
    app.community.failWrites = true;
    await tester.tap(find.text('Post comment'));
    await tester.pumpAndSettle();

    expect(find.text('Add a supportive comment'), findsOneWidget);
    expect(find.text(MemoryCommunityRepository.failureMessage), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      draft,
    );
    expect(app.community.comments['discussion-post'], isEmpty);

    app.community.failWrites = false;
    await tester.tap(find.text('Post comment'));
    await tester.pumpAndSettle();
    expect(find.text('Add a supportive comment'), findsNothing);
    expect(_path(app.router), '/community/post/discussion-post');
    await _reveal(tester, find.text('Comments (1)'));
    await _reveal(tester, find.text(draft));
    expect(find.text(draft), findsOneWidget);
    expect(app.community.comments['discussion-post']!.single.body, draft);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Other bug requires a name and persists the custom match', (
    tester,
  ) async {
    final app = await _pumpCommunity(tester);
    await tester.tap(find.text('Add your experience'));
    await tester.pumpAndSettle();

    await _reveal(tester, find.byKey(const Key('possible-match')));
    await tester.tap(find.byKey(const Key('possible-match')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Other bug').last,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Other bug').last);
    await tester.pumpAndSettle();

    await _reveal(tester, find.byKey(const Key('experience-details')));
    await tester.enterText(
      find.byKey(const Key('experience-details')),
      'I noticed an unfamiliar insect while working outside.',
    );
    await _reveal(tester, find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await _reveal(tester, find.text('Share carefully'));
    await tester.tap(find.text('Share carefully'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 900));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a bug name between 2 and 60 characters.'),
      findsOneWidget,
    );

    await _reveal(tester, find.byKey(const Key('custom-bug-name')));
    await tester.enterText(
      find.byKey(const Key('custom-bug-name')),
      '  Assassin bug  ',
    );
    await _reveal(tester, find.text('Share carefully'));
    await tester.tap(find.text('Share carefully'));
    await tester.pumpAndSettle();

    expect(_path(app.router), '/community');
    await _reveal(tester, find.text('Possible Assassin bug'));
    expect(find.text('Possible Assassin bug'), findsOneWidget);
    final saved = app.community.posts.firstWhere(
      (post) => post.possibleMatch == 'Possible Assassin bug',
    );
    expect(saved.guideId, isNull);
    expect(saved.authorId, _user.id);
    expect(saved.body, 'I noticed an unfamiliar insect while working outside.');

    await tester.tap(find.text('Possible Assassin bug'));
    await tester.pumpAndSettle();
    expect(_path(app.router), '/community/post/${saved.id}');
    expect(tester.takeException(), isNull);
  });
}

CommunityPost _post({
  List<CommunityComment> comments = const [],
  String authorId = 'another-member',
  Uint8List? imageBytes,
}) => CommunityPost(
  id: 'discussion-post',
  authorId: authorId,
  author: 'Another Member',
  location: 'A nearby garden',
  createdAt: DateTime(2026, 9, 1),
  possibleMatch: 'Possible mosquito',
  body: _postBody,
  guideId: 'mosquito',
  tags: const ['Itchy'],
  comments: comments,
  imageBytes: imageBytes,
);

Future<
  ({
    GoRouter router,
    MemoryUserDataStore store,
    MemoryCommunityRepository community,
  })
>
_pumpCommunity(
  WidgetTester tester, {
  CommunityPost? post,
  List<CommunityPost> localPosts = const [],
}) async {
  final store = MemoryUserDataStore();
  if (localPosts.isNotEmpty) {
    await AppPersistenceService(store).save(
      _user.id,
      PersistedAppData(
        posts: localPosts,
        savedGuideIds: {},
        gentleReminders: true,
        stripPhotoMetadata: true,
      ),
    );
  }
  final community = MemoryCommunityRepository(posts: [post ?? _post()]);
  addTearDown(community.dispose);
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(_AuthenticatedAuthService()),
        communityRepositoryProvider.overrideWithValue(community),
        userDataStoreProvider.overrideWithValue(store),
        profileDataServiceProvider.overrideWithValue(
          ProfileDataService(
            loadDelay: Duration.zero,
            operationDelay: Duration.zero,
          ),
        ),
      ],
      child: const BiteWiseApp(),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(BiteWiseApp)),
  );
  final router = container.read(appRouterProvider);
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Community'),
    ),
  );
  await tester.pumpAndSettle();
  return (router: router, store: store, community: community);
}

// Imperatively pushed native routes need not change the browser URL provider.
String _path(GoRouter router) => router.state.uri.path;

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 150,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

class _AuthenticatedAuthService extends Fake implements AuthService {
  @override
  AuthUser get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(_user);
}
