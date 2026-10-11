import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_bugbite/data/models/community_post.dart';
import 'package:project_bugbite/data/services/app_persistence_service.dart';
import 'package:project_bugbite/data/services/user_data_store.dart';
import 'package:project_bugbite/state/app_controller.dart';
import 'package:project_bugbite/state/persistence_providers.dart';

import 'support/memory_user_data_store.dart';

void main() {
  test('new app state has no guides saved on the user behalf', () {
    expect(AppState.initial().savedGuideIds, isEmpty);
  });

  test('round-trips posts, comments, photos, saves, and settings', () async {
    final store = MemoryUserDataStore();
    final service = AppPersistenceService(store);
    final createdAt = DateTime.utc(2026, 8, 30, 12);
    final post = CommunityPost(
      id: 'post-1',
      authorId: 'user-a',
      author: 'Alex',
      location: 'Your area',
      createdAt: createdAt,
      possibleMatch: 'Possible mosquito',
      body: 'A persistent test experience.',
      guideId: 'mosquito',
      tags: const <String>['Itchy'],
      imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      comments: <CommunityComment>[
        CommunityComment(
          id: 'comment-1',
          authorId: 'user-a',
          author: 'Alex',
          body: 'A kind reply.',
          createdAt: createdAt,
        ),
      ],
    );

    await service.save(
      'user-a',
      PersistedAppData(
        posts: <CommunityPost>[post],
        savedGuideIds: const <String>{'mosquito', 'bedbug'},
        gentleReminders: false,
        stripPhotoMetadata: true,
      ),
    );
    final restored = await service.load('user-a');

    expect(restored, isNotNull);
    expect(restored!.posts.single.body, post.body);
    expect(restored.posts.single.imageBytes, orderedEquals(<int>[1, 2, 3]));
    expect(restored.posts.single.comments.single.body, 'A kind reply.');
    expect(restored.savedGuideIds, <String>{'mosquito', 'bedbug'});
    expect(restored.gentleReminders, isFalse);
    expect(await service.load('user-b'), isNull);
  });

  test(
    'app controller restores data after reconstruction and isolates users',
    () async {
      final store = MemoryUserDataStore();

      Future<ProviderContainer> createContainer() async {
        final container = ProviderContainer(
          overrides: [userDataStoreProvider.overrideWithValue(store)],
        );
        await container
            .read(appControllerProvider.notifier)
            .syncAuthenticatedUser(
              userId: 'user-a',
              displayName: 'Alex',
              email: 'alex@example.com',
            );
        return container;
      }

      final firstContainer = await createContainer();
      final firstController = firstContainer.read(
        appControllerProvider.notifier,
      );
      expect(
        await firstController.addCommunityPost(
          possibleMatch: 'Possible black fly',
          body: 'Unique persisted item for the cold-start test.',
          guideId: 'black-fly',
          tags: const <String>['Outdoors'],
        ),
        isTrue,
      );
      expect(await firstController.toggleSavedGuide('black-fly'), isTrue);
      expect(await firstController.setGentleReminders(false), isTrue);
      expect(
        await firstController.addCommunityPost(
          possibleMatch: 'Possible Assassin bug',
          body: 'An author-suggested bug outside the guide catalog.',
          guideId: null,
          tags: const <String>['Outdoors'],
        ),
        isTrue,
      );
      final customPostId = firstContainer
          .read(appControllerProvider)
          .posts
          .first
          .id;
      expect(
        await firstController.addComment(
          postId: customPostId,
          body: 'Thanks for sharing your experience.',
        ),
        isTrue,
      );
      firstContainer.dispose();

      final restoredContainer = await createContainer();
      final restored = restoredContainer.read(appControllerProvider);
      expect(
        restored.posts.any(
          (post) => post.body.contains('Unique persisted item'),
        ),
        isTrue,
      );
      expect(restored.savedGuideIds, contains('black-fly'));
      expect(restored.gentleReminders, isFalse);
      final customPost = restored.posts.singleWhere(
        (post) => post.id == customPostId,
      );
      expect(customPost.possibleMatch, 'Possible Assassin bug');
      expect(customPost.guideId, isNull);
      expect(customPost.imageBytes, isNull);
      expect(
        customPost.comments.single.body,
        'Thanks for sharing your experience.',
      );
      expect(
        restored.posts
            .singleWhere((post) => post.body.contains('Unique persisted item'))
            .guideId,
        'black-fly',
      );

      final controller = restoredContainer.read(appControllerProvider.notifier);
      controller.signOut();
      await controller.syncAuthenticatedUser(
        userId: 'user-b',
        displayName: 'Blair',
        email: 'blair@example.com',
      );
      final otherUser = restoredContainer.read(appControllerProvider);
      expect(
        otherUser.posts.any(
          (post) => post.body.contains('Unique persisted item'),
        ),
        isFalse,
      );
      expect(otherUser.savedGuideIds, isNot(contains('black-fly')));
      expect(otherUser.posts.any((post) => post.id == customPostId), isFalse);
      restoredContainer.dispose();
    },
  );

  test('restores custom and legacy catalog matches together', () async {
    const userId = 'existing-user';
    final createdAt = DateTime.utc(2026, 9, 13);
    final customPost = CommunityPost(
      id: 'custom-post',
      authorId: userId,
      author: 'Alex',
      location: 'Your area',
      createdAt: createdAt,
      possibleMatch: 'Possible Assassin bug',
      body: 'A possible match suggested by the author.',
      guideId: null,
      tags: const <String>[],
      comments: <CommunityComment>[
        CommunityComment(
          id: 'custom-comment',
          authorId: userId,
          author: 'Alex',
          body: 'A saved comment.',
          createdAt: createdAt,
        ),
      ],
    );
    final legacyCatalogPost = <String, Object?>{
      ...customPost.toJson(),
      'id': 'legacy-post',
      'possibleMatch': 'Possible mosquito',
      'guideId': 'mosquito',
    }..remove('comments');
    final store = MemoryUserDataStore(
      values: <String, String>{
        userScopedStorageKey('app', userId): jsonEncode(<String, Object?>{
          'version': 2,
          'posts': <Object?>[customPost.toJson(), legacyCatalogPost],
          'savedGuideIds': <String>[],
          'gentleReminders': true,
          'stripPhotoMetadata': true,
        }),
      },
    );

    final restored = await AppPersistenceService(store).load(userId);

    expect(restored!.posts, hasLength(2));
    expect(restored.posts.first.possibleMatch, 'Possible Assassin bug');
    expect(restored.posts.first.guideId, isNull);
    expect(restored.posts.first.comments.single.body, 'A saved comment.');
    expect(restored.posts.last.guideId, 'mosquito');
    expect(restored.posts.last.comments, isEmpty);
  });

  test('does not save comments for missing posts or short replies', () async {
    final store = MemoryUserDataStore();
    final container = ProviderContainer(
      overrides: [userDataStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    await controller.syncAuthenticatedUser(
      userId: 'user-a',
      displayName: 'Alex',
    );
    final previousStorage = Map<String, String>.of(store.values);
    final existingPostId = container.read(appControllerProvider).posts.first.id;

    expect(
      await controller.addComment(postId: 'missing-post', body: 'A reply.'),
      isFalse,
    );
    expect(
      await controller.addComment(postId: existingPostId, body: ' x '),
      isFalse,
    );
    expect(store.values, previousStorage);
  });

  test('storage failures become readable persistence state', () async {
    final store = MemoryUserDataStore(failReads: true);
    final container = ProviderContainer(
      overrides: [userDataStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await container
        .read(appControllerProvider.notifier)
        .syncAuthenticatedUser(
          userId: 'user-a',
          displayName: 'Alex',
          email: 'alex@example.com',
        );

    final state = container.read(appControllerProvider);
    expect(state.isHydrating, isFalse);
    expect(state.persistenceReadFailed, isTrue);
    expect(state.persistenceError, contains('could not be loaded'));
  });

  test('migrates the exact legacy default bookmarks to empty', () async {
    const userId = 'legacy-user';
    final key = userScopedStorageKey('app', userId);
    final store = MemoryUserDataStore(
      values: <String, String>{
        key: jsonEncode(<String, Object?>{
          'version': 1,
          'posts': <Object?>[],
          'savedGuideIds': <String>['mosquito', 'bedbug'],
          'gentleReminders': true,
          'stripPhotoMetadata': true,
        }),
      },
    );

    final restored = await AppPersistenceService(store).load(userId);

    expect(restored?.savedGuideIds, isEmpty);
    expect((jsonDecode(store.values[key]!) as Map)['version'], 2);
  });

  test('removes injected bookmarks but preserves real legacy saves', () async {
    const userId = 'legacy-user';
    final key = userScopedStorageKey('app', userId);
    final store = MemoryUserDataStore(
      values: <String, String>{
        key: jsonEncode(<String, Object?>{
          'version': 1,
          'posts': <Object?>[],
          'savedGuideIds': <String>['mosquito', 'bedbug', 'black-fly'],
          'gentleReminders': true,
          'stripPhotoMetadata': true,
        }),
      },
    );

    final restored = await AppPersistenceService(store).load(userId);

    expect(restored?.savedGuideIds, <String>{'black-fly'});
    expect((jsonDecode(store.values[key]!) as Map)['version'], 2);
  });
}
