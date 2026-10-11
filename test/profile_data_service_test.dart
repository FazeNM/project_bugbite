import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_bugbite/data/services/profile_data_service.dart';
import 'package:project_bugbite/data/services/user_data_store.dart';

import 'support/memory_user_data_store.dart';

void main() {
  final now = DateTime.utc(2026, 9, 6, 12);

  ProfileDataService createService(
    MemoryUserDataStore store, {
    String userId = 'user-a',
    bool failRequests = false,
  }) => ProfileDataService(
    userId: userId,
    store: store,
    loadDelay: Duration.zero,
    operationDelay: Duration.zero,
    failRequests: failRequests,
    clock: () => now,
  );

  test('a new account starts with honest empty activity', () async {
    final store = MemoryUserDataStore();

    final data = await createService(store).loadProfileData();

    expect(data.recentBites, isEmpty);
    expect(data.continueBite, isNull);
    expect(data.recommendations, isEmpty);
    final stored = _storedHistory(store, 'user-a');
    expect(stored['version'], 4);
    expect(stored['history'], isEmpty);
  });

  test('loads real recent bite guides newest first', () async {
    final store = _storeWithHistory('user-a', <Map<String, Object?>>[
      _record('bedbug', now.subtract(const Duration(hours: 3)), .45),
      _record('mosquito', now.subtract(const Duration(hours: 1)), .8),
      _record('flea', now.subtract(const Duration(hours: 2)), 1),
    ]);

    final data = await createService(store).loadProfileData();

    expect(data.recentBites.map((item) => item.guide.id), <String>[
      'mosquito',
      'flea',
      'bedbug',
    ]);
  });

  test('selects the newest unfinished real guide to continue', () async {
    final store = _storeWithHistory('user-a', <Map<String, Object?>>[
      _record('flea', now.subtract(const Duration(minutes: 5)), 1),
      _record('black-fly', now.subtract(const Duration(minutes: 20)), .6),
      _record('mosquito', now.subtract(const Duration(hours: 1)), .4),
    ]);

    final data = await createService(store).loadProfileData();

    expect(data.continueBite?.guide.id, 'black-fly');
    expect(data.continueBite?.isComplete, isFalse);
  });

  test('recommendations derive from actual viewed guides', () async {
    final store = _storeWithHistory('user-a', <Map<String, Object?>>[
      _record('mosquito', now.subtract(const Duration(minutes: 10)), .5),
    ]);

    final data = await createService(store).loadProfileData();
    final viewedIds = data.recentBites.map((item) => item.guide.id).toSet();

    expect(data.recommendations, isNotEmpty);
    expect(
      data.recommendations.every((guide) => !viewedIds.contains(guide.id)),
      isTrue,
    );
  });

  test(
    'reopening a completed guide keeps it completed and moves it up',
    () async {
      final store = _storeWithHistory('user-a', <Map<String, Object?>>[
        _record('flea', now.subtract(const Duration(days: 3)), 1),
        _record('mosquito', now.subtract(const Duration(days: 1)), .4),
      ]);
      final service = createService(store);

      final data = await service.recordGuideOpened('flea');

      expect(data.recentBites.first.guide.id, 'flea');
      expect(data.recentBites.first.isComplete, isTrue);
    },
  );

  test('returns a useful failure when profile loading fails', () async {
    final service = createService(MemoryUserDataStore(), failRequests: true);

    expect(service.loadProfileData(), throwsA(isA<ProfileDataException>()));
  });

  test(
    'persists history across service reconstruction and isolates users',
    () async {
      final store = MemoryUserDataStore();
      await createService(store).recordGuideOpened('black-fly');

      final restoredData = await createService(store).loadProfileData();
      expect(restoredData.recentBites.first.guide.id, 'black-fly');

      final otherUserData = await createService(
        store,
        userId: 'user-b',
      ).loadProfileData();
      expect(otherUserData.recentBites, isEmpty);
    },
  );

  test(
    'serializes concurrent history updates without adding demo records',
    () async {
      final store = MemoryUserDataStore();
      final service = createService(store);

      await Future.wait(<Future<Object>>[
        service.recordGuideOpened('black-fly'),
        service.recordGuideOpened('fire-ant'),
      ]);
      final data = await createService(store).loadProfileData();

      expect(data.recentBites.map((item) => item.guide.id).toSet(), <String>{
        'black-fly',
        'fire-ant',
      });
    },
  );

  for (final legacyVersion in <int>[1, 2, 3]) {
    test(
      'migrates version $legacyVersion legacy demo history to empty version 4 data',
      () async {
        final seededAt = now.subtract(const Duration(days: 2));
        final store = _storeWithHistory('user-a', <Map<String, Object?>>[
          _record('mosquito', seededAt.subtract(const Duration(hours: 3)), .8),
          _record('flea', seededAt.subtract(const Duration(days: 1)), 1),
          _record(
            'bedbug',
            seededAt.subtract(const Duration(minutes: 18)),
            .45,
          ),
        ], version: legacyVersion);

        final data = await createService(store).loadProfileData();

        expect(data.recentBites, isEmpty);
        final migrated = _storedHistory(store, 'user-a');
        expect(migrated['version'], 4);
        expect(migrated['history'], isEmpty);
      },
    );
  }

  for (final legacyVersion in <int>[1, 2, 3]) {
    test(
      'preserves genuine version $legacyVersion history while upgrading',
      () async {
        final store = _storeWithHistory('user-a', <Map<String, Object?>>[
          _record('black-fly', now.subtract(const Duration(hours: 2)), .25),
        ], version: legacyVersion);

        final data = await createService(store).loadProfileData();

        expect(data.recentBites.single.guide.id, 'black-fly');
        expect(_storedHistory(store, 'user-a')['version'], 4);
      },
    );
  }

  test(
    'removes the legacy demo trio but preserves additional real history',
    () async {
      final seededAt = now.subtract(const Duration(days: 2));
      final store = _storeWithHistory('user-a', <Map<String, Object?>>[
        _record('black-fly', now.subtract(const Duration(minutes: 5)), .25),
        _record('bedbug', seededAt.subtract(const Duration(minutes: 18)), .45),
        _record('mosquito', seededAt.subtract(const Duration(hours: 3)), .8),
        _record('flea', seededAt.subtract(const Duration(days: 1)), 1),
      ], version: 1);

      final data = await createService(store).loadProfileData();

      expect(data.recentBites, hasLength(1));
      expect(data.recentBites.single.guide.id, 'black-fly');
      expect(_storedHistory(store, 'user-a')['version'], 4);
    },
  );

  test(
    'version 3 migration removes demo records after timestamps change',
    () async {
      final seededAt = now.subtract(const Duration(days: 2));
      final store = _storeWithHistory('user-a', <Map<String, Object?>>[
        _record('bedbug', seededAt.subtract(const Duration(minutes: 18)), .45),
        _record('mosquito', now.subtract(const Duration(minutes: 5)), .8),
        _record('flea', seededAt.subtract(const Duration(days: 1)), 1),
      ], version: 3);

      final data = await createService(store).loadProfileData();

      expect(data.recentBites, isEmpty);
      expect(_storedHistory(store, 'user-a')['version'], 4);
    },
  );

  test('does not clear an isolated demo-like record', () async {
    final store = _storeWithHistory('user-a', <Map<String, Object?>>[
      _record('flea', now.subtract(const Duration(days: 1)), 1),
    ], version: 2);

    final data = await createService(store).loadProfileData();

    expect(data.recentBites.single.guide.id, 'flea');
  });

  test('does not clear an isolated legacy progress marker', () async {
    final store = _storeWithHistory('user-a', <Map<String, Object?>>[
      _record('bedbug', now.subtract(const Duration(hours: 1)), .45),
    ], version: 3);

    final data = await createService(store).loadProfileData();

    expect(data.recentBites.single.guide.id, 'bedbug');
  });

  test('skips a malformed record while preserving valid history', () async {
    final store = _storeWithHistory('user-a', <Map<String, Object?>>[
      <String, Object?>{
        'guideId': 'flea',
        'lastViewedAt': 'not-a-date',
        'progress': 1,
      },
      _record('black-fly', now.subtract(const Duration(hours: 2)), .25),
    ]);

    final data = await createService(store).loadProfileData();

    expect(data.recentBites.single.guide.id, 'black-fly');
  });

  test('does not overwrite history from a newer app version', () async {
    final key = userScopedStorageKey('guide-history', 'user-a');
    final raw = jsonEncode(<String, Object?>{
      'version': 5,
      'history': <Map<String, Object?>>[
        _record('black-fly', now.subtract(const Duration(hours: 2)), .25),
      ],
    });
    final store = MemoryUserDataStore(values: <String, String>{key: raw});

    await expectLater(
      createService(store).loadProfileData(),
      throwsA(isA<ProfileDataException>()),
    );

    expect(store.values[key], raw);
  });

  test(
    'failed legacy migration remains readable and keeps version 1 data',
    () async {
      final seededAt = now.subtract(const Duration(days: 2));
      final store = _storeWithHistory('user-a', <Map<String, Object?>>[
        _record('bedbug', seededAt.subtract(const Duration(minutes: 18)), .45),
        _record('mosquito', seededAt.subtract(const Duration(hours: 3)), .8),
        _record('flea', seededAt.subtract(const Duration(days: 1)), 1),
      ], version: 1)..failWrites = true;

      await expectLater(
        createService(store).loadProfileData(),
        throwsA(isA<ProfileDataException>()),
      );
      expect(_storedHistory(store, 'user-a')['version'], 1);
    },
  );
}

MemoryUserDataStore _storeWithHistory(
  String userId,
  List<Map<String, Object?>> history, {
  int version = 4,
}) => MemoryUserDataStore(
  values: <String, String>{
    userScopedStorageKey('guide-history', userId): jsonEncode(<String, Object?>{
      'version': version,
      'history': history,
    }),
  },
);

Map<String, Object?> _record(
  String guideId,
  DateTime lastViewedAt,
  double progress,
) => <String, Object?>{
  'guideId': guideId,
  'lastViewedAt': lastViewedAt.toIso8601String(),
  'progress': progress,
};

Map<String, Object?> _storedHistory(MemoryUserDataStore store, String userId) =>
    jsonDecode(store.values[userScopedStorageKey('guide-history', userId)]!)
        as Map<String, Object?>;
