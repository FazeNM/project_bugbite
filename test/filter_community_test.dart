import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:project_bugbite/app/app.dart';
import 'package:project_bugbite/app/app_router.dart';
import 'package:project_bugbite/data/models/bite_filters.dart';
import 'package:project_bugbite/data/models/community_post.dart';
import 'package:project_bugbite/data/services/auth_service.dart';
import 'package:project_bugbite/data/services/community_filter_service.dart';
import 'package:project_bugbite/data/services/profile_data_service.dart';
import 'package:project_bugbite/data/seed/seed_data.dart';
import 'package:project_bugbite/core/theme/app_theme.dart';
import 'package:project_bugbite/features/community/widgets/add_bite_widgets.dart';
import 'package:project_bugbite/features/community/widgets/community_post_results.dart';
import 'package:project_bugbite/features/find/widgets/match_card.dart';
import 'package:project_bugbite/state/auth_controller.dart';
import 'package:project_bugbite/state/community_providers.dart';
import 'package:project_bugbite/state/persistence_providers.dart';
import 'package:project_bugbite/state/profile_data_controller.dart';

import 'support/memory_user_data_store.dart';
import 'support/memory_community_repository.dart';

const _user = AuthUser(
  id: 'filter-test-user',
  email: 'filters@example.com',
  displayName: 'Filter Tester',
  photoUrl: null,
  isEmailVerified: true,
);

void main() {
  testWidgets('filtered feed can find a match beyond the first 50 posts', (
    tester,
  ) async {
    final router = await _pumpApp(
      tester,
      posts: [
        _post('older-match', ['red', 'stinger'], day: 1),
        for (var index = 0; index < 50; index++)
          _post('partial-$index', ['red'], day: index + 2),
      ],
    );
    router.go('/community?tag=red&tag=stinger');
    await tester.pumpAndSettle();
    await _reveal(tester, find.text('No matches in loaded posts'));
    expect(
      find.byKey(const ValueKey('community-post-older-match')),
      findsNothing,
    );
    await _reveal(tester, find.byKey(const ValueKey('load-more-community')));
    await tester.tap(find.byKey(const ValueKey('load-more-community')));
    await tester.pumpAndSettle();
    await _reveal(
      tester,
      find.byKey(const ValueKey('community-post-older-match')),
    );
    expect(
      find.byKey(const ValueKey('community-post-older-match')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('community-post-partial-1')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('long match titles fit on narrow screens with larger text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: BiteWiseTheme.light(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: guides
                    .map((guide) => MatchCard(guide: guide))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('legacy observation tags normalize to the shared vocabulary', () {
    expect(
      BiteFilters.normalizeAll(['Itchy', ' Red ', 'Cluster', 'Clustered']),
      {'itchy', 'red', 'cluster'},
    );
    expect(BiteFilters.labelFor('lower-leg'), 'Ankles or lower legs');
    expect(BiteFilters.normalize('unknown observation'), isNull);
    expect(
      BiteFilters.normalizeAll([
        'Outdoors',
        'Improving',
        'Checked with clinician',
      ]),
      {'outdoors', 'improving', 'checked-with-clinician'},
    );
  });

  test('matching requires all explicit post tags, never a linked guide', () {
    final posts = [
      _post('partial', ['itchy']),
      _post('explicit', ['Itchy', 'Red', 'Cluster']),
      _post('guide-only', [], guideId: 'mosquito'),
      _post('custom-bug', ['red', 'itchy'], day: 2),
    ];

    expect(
      filterCommunityPosts(posts, {'itchy', 'red'}).map((post) => post.id),
      ['custom-bug', 'explicit'],
    );
    expect(filterCommunityPosts(posts, {'stinger'}), isEmpty);
  });

  test('unfiltered posts are newest first without mutating their source', () {
    final posts = [_post('old', [], day: 1), _post('new', [], day: 4)];
    expect(filterCommunityPosts(posts, {}).map((post) => post.id), [
      'new',
      'old',
    ]);
    expect(posts.first.id, 'old');
  });

  test('filter links preserve every selected tag and discard unknown tags', () {
    final uri = Uri.parse(
      BiteFilters.communityLocation({'stinger', 'scalp', 'red'}),
    );
    expect(uri.path, '/community');
    expect(uri.queryParametersAll['tag'], ['red', 'scalp', 'stinger']);
    expect(BiteFilters.fromUri(uri), {'red', 'scalp', 'stinger'});
    expect(
      BiteFilters.fromUri(
        Uri.parse('/community?tag=Red&tag=Itchy&tag=nope&tag=Itchy'),
      ),
      {'red', 'itchy'},
    );
    expect(BiteFilters.communityLocation({}), '/community');
  });

  testWidgets(
    'post tags offer every Find observation and existing context tags',
    (tester) async {
      String? changedTag;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BiteTagSelector(
              selected: const {'Itchy'},
              onChanged: (tag, selected) => changedTag = tag,
            ),
          ),
        ),
      );
      for (final option in BiteFilters.postOptions) {
        expect(find.byKey(ValueKey('post-tag-${option.id}')), findsOneWidget);
      }
      expect(
        tester
            .widget<FilterChip>(find.byKey(const ValueKey('post-tag-itchy')))
            .selected,
        isTrue,
      );
      await tester.tap(find.byKey(const ValueKey('post-tag-stinger')));
      expect(changedTag, 'stinger');
    },
  );

  testWidgets(
    'no guide match previews posts and preserves filters in community',
    (tester) async {
      final router = await _pumpApp(
        tester,
        posts: [
          _post('matching', ['scalp', 'stinger']),
          _post('partial', ['scalp']),
        ],
      );
      router.go('/find');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('find-tag-scalp')));
      await tester.pumpAndSettle();
      await _reveal(tester, find.byKey(const ValueKey('find-tag-stinger')));
      await tester.tap(find.byKey(const ValueKey('find-tag-stinger')));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/find');
      await _reveal(tester, find.text('No close visual guide'));
      await _reveal(
        tester,
        find.byKey(const ValueKey('community-post-matching')),
      );
      expect(
        find.byKey(const ValueKey('community-post-matching')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('community-post-partial')),
        findsNothing,
      );
      await _reveal(
        tester,
        find.byKey(const ValueKey('view-matching-community')),
      );
      await tester.tap(find.byKey(const ValueKey('view-matching-community')));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/community');
      expect(BiteFilters.fromUri(router.state.uri), {'scalp', 'stinger'});
      expect(
        find.byKey(const ValueKey('community-filter-scalp')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('community-filter-stinger')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('clear-community-filters')));
      await tester.pumpAndSettle();
      expect(router.state.uri.query, isEmpty);
      expect(find.text('Your selected filters'), findsNothing);
      await _reveal(
        tester,
        find.byKey(const ValueKey('community-post-partial')),
      );
      expect(
        find.byKey(const ValueKey('community-post-partial')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unmatched community query shows honest empty state and removable chips',
    (tester) async {
      final router = await _pumpApp(
        tester,
        posts: [
          _post('red-only', ['Red']),
        ],
      );
      router.go('/community?tag=red&tag=stinger&tag=unrecognized');
      await tester.pumpAndSettle();

      expect(find.byType(InputChip), findsNWidgets(2));
      await _reveal(
        tester,
        find.text('No loaded posts match all these filters'),
      );
      expect(
        find.byKey(const ValueKey('community-post-red-only')),
        findsNothing,
      );
      await tester.drag(find.byType(ListView), const Offset(0, 700));
      await tester.pumpAndSettle();
      final stingerChip = tester.widget<InputChip>(
        find.byKey(const ValueKey('community-filter-stinger')),
      );
      stingerChip.onDeleted!();
      await tester.pumpAndSettle();
      expect(BiteFilters.fromUri(router.state.uri), {'red'});
      await _reveal(
        tester,
        find.byKey(const ValueKey('community-post-red-only')),
      );
      expect(
        find.byKey(const ValueKey('community-post-red-only')),
        findsOneWidget,
      );
    },
  );

  testWidgets('community results show loading, not stale matching posts', (
    tester,
  ) async {
    await _pumpResults(
      tester,
      MemoryCommunityRepository(
        posts: [
          _post('stale', ['red']),
        ],
      )..holdReads = true,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading community experiences…'), findsOneWidget);
    expect(find.byKey(const ValueKey('community-post-stale')), findsNothing);
  });

  testWidgets('community read error is visible and does not claim no matches', (
    tester,
  ) async {
    await _pumpResults(tester, MemoryCommunityRepository()..failReads = true);
    await tester.pumpAndSettle();
    expect(find.text('Community experiences could not load'), findsOneWidget);
    expect(find.text(MemoryCommunityRepository.failureMessage), findsOneWidget);
    expect(find.text('No loaded posts match all these filters'), findsNothing);
  });
}

CommunityPost _post(
  String id,
  List<String> tags, {
  int day = 1,
  String? guideId,
}) => CommunityPost(
  id: id,
  authorId: 'another-member',
  author: 'Another Member',
  location: 'Nearby',
  createdAt: DateTime(2026, 9, day),
  possibleMatch: 'Possible custom bug',
  body: 'Shared observations for the $id experience.',
  guideId: guideId,
  tags: tags,
);

Future<GoRouter> _pumpApp(
  WidgetTester tester, {
  required List<CommunityPost> posts,
}) async {
  final store = MemoryUserDataStore();
  final community = MemoryCommunityRepository(posts: posts);
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
  return ProviderScope.containerOf(
    tester.element(find.byType(BiteWiseApp)),
  ).read(appRouterProvider);
}

Future<void> _pumpResults(
  WidgetTester tester,
  MemoryCommunityRepository community,
) {
  addTearDown(community.dispose);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(_AuthenticatedAuthService()),
        communityRepositoryProvider.overrideWithValue(community),
      ],
      child: const MaterialApp(
        home: Scaffold(body: CommunityPostResults(selectedTags: {'red'})),
      ),
    ),
  );
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

class _AuthenticatedAuthService extends Fake implements AuthService {
  @override
  AuthUser get currentUser => _user;
  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(_user);
}
