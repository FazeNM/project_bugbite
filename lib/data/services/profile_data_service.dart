import 'dart:async';
import 'dart:convert';

import '../models/bite_guide.dart';
import '../models/profile_bite_data.dart';
import '../seed/seed_data.dart';
import 'user_data_store.dart';

class ProfileDataException implements Exception {
  const ProfileDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Manages the profile's bite-view history and personalized suggestions.
///
/// Data is stored locally under the authenticated user's ID. New accounts start
/// with empty activity; only guides the user actually opens are recorded.
class ProfileDataService {
  ProfileDataService({
    this.loadDelay = const Duration(milliseconds: 900),
    this.operationDelay = const Duration(milliseconds: 120),
    this.failRequests = false,
    this.userId,
    this.store,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration loadDelay;
  final Duration operationDelay;
  final bool failRequests;
  final String? userId;
  final DateTime Function() _clock;
  final UserDataStore? store;
  final List<_BiteHistoryRecord> _history = <_BiteHistoryRecord>[];
  static const _storageVersion = 4;
  bool _initialized = false;
  Future<void>? _initialization;
  Future<void> _mutationQueue = Future<void>.value();

  Future<ProfileBiteData> loadProfileData() async {
    await Future<void>.delayed(loadDelay);
    _throwIfUnavailable();
    await _ensureLoaded();
    return _buildSnapshot();
  }

  Future<ProfileBiteData> recordGuideOpened(String guideId) =>
      _serialize(() async {
        await Future<void>.delayed(operationDelay);
        _throwIfUnavailable();
        await _ensureLoaded();
        _requireGuide(guideId);

        final existingIndex = _history.indexWhere(
          (item) => item.guideId == guideId,
        );
        final existing = existingIndex < 0
            ? null
            : _history.removeAt(existingIndex);
        final nextProgress = existing == null
            ? .25
            : existing.progress >= 1
            ? 1.0
            : existing.progress.clamp(.35, .9).toDouble();

        _history.add(
          _BiteHistoryRecord(
            guideId: guideId,
            lastViewedAt: _clock(),
            progress: nextProgress,
          ),
        );
        await _persist();
        return _buildSnapshot();
      });

  Future<ProfileBiteData> markGuideCompleted(String guideId) =>
      _serialize(() async {
        await Future<void>.delayed(operationDelay);
        _throwIfUnavailable();
        await _ensureLoaded();
        _requireGuide(guideId);

        _history.removeWhere((item) => item.guideId == guideId);
        _history.add(
          _BiteHistoryRecord(
            guideId: guideId,
            lastViewedAt: _clock(),
            progress: 1,
          ),
        );
        await _persist();
        return _buildSnapshot();
      });

  Future<void> _ensureLoaded() async {
    if (_initialized) return;

    final inFlight = _initialization;
    if (inFlight != null) return inFlight;

    final initialization = _loadInitialData();
    _initialization = initialization;
    try {
      await initialization;
    } finally {
      if (identical(_initialization, initialization)) _initialization = null;
    }
  }

  Future<void> _loadInitialData() async {
    final store = this.store;
    final activeUserId = userId;
    if (store == null || activeUserId == null) {
      _history.clear();
      _initialized = true;
      return;
    }

    final storageKey = userScopedStorageKey('guide-history', activeUserId);
    try {
      final raw = await store.read(storageKey);
      if (raw == null) {
        _history.clear();
        await _persist();
        _initialized = true;
        return;
      }

      final decoded = _decodeHistory(raw);
      final legacyDemoGuideIds = decoded.version < _storageVersion
          ? _legacyDemoGuideIds(decoded.records)
          : const <String>{};
      _history
        ..clear()
        ..addAll(
          decoded.records.where(
            (record) => !legacyDemoGuideIds.contains(record.guideId),
          ),
        );
      if (decoded.version < _storageVersion) await _persist();
      _initialized = true;
    } on FormatException {
      try {
        _history.clear();
        await _persist();
        _initialized = true;
      } catch (_) {
        throw const ProfileDataException(
          'Your saved bite activity could not be repaired. Please try again.',
        );
      }
    } on ProfileDataException {
      rethrow;
    } catch (_) {
      throw const ProfileDataException(
        'Your saved bite activity could not be loaded. Please try again.',
      );
    }
  }

  _DecodedHistory _decodeHistory(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Invalid saved history.');
      }
      final version = decoded['version'];
      if (version is! int || version < 1) {
        throw const FormatException('Unsupported history format.');
      }
      if (version > _storageVersion) {
        throw const _UnsupportedHistoryVersionException();
      }
      final restored = <_BiteHistoryRecord>[];
      for (final value in decoded['history']! as List<Object?>) {
        if (value is! Map<String, Object?>) continue;
        final guideId = value['guideId'];
        final lastViewedAt = value['lastViewedAt'];
        final progress = value['progress'];
        if (guideId is! String ||
            guideById(guideId) == null ||
            lastViewedAt is! String ||
            progress is! num) {
          continue;
        }
        final parsedLastViewedAt = DateTime.tryParse(lastViewedAt);
        if (parsedLastViewedAt == null) continue;
        restored.add(
          _BiteHistoryRecord(
            guideId: guideId,
            lastViewedAt: parsedLastViewedAt,
            progress: progress.toDouble().clamp(0, 1).toDouble(),
          ),
        );
      }
      return _DecodedHistory(version: version, records: restored);
    } on _UnsupportedHistoryVersionException {
      rethrow;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid saved history.');
    }
  }

  Set<String> _legacyDemoGuideIds(List<_BiteHistoryRecord> records) {
    final byGuideId = <String, _BiteHistoryRecord>{
      for (final record in records) record.guideId: record,
    };

    // The removed prototype seed was the only code path that wrote 45% for
    // Bed bug or 80% for Mosquito. Those values remain reliable provenance
    // even if a user later opened the seeded guide and changed its timestamp.
    const epsilon = .000000001;
    final legacyMarkers = <String>{};
    final bedBug = byGuideId['bedbug'];
    if (bedBug != null && (bedBug.progress - .45).abs() < epsilon) {
      legacyMarkers.add('bedbug');
    }
    final mosquito = byGuideId['mosquito'];
    if (mosquito != null && (mosquito.progress - .8).abs() < epsilon) {
      legacyMarkers.add('mosquito');
    }

    final flea = byGuideId['flea'];
    final hasSeededFlea = flea != null && (flea.progress - 1).abs() < epsilon;
    if (legacyMarkers.length < 2) {
      // With one marker, require the untouched timestamp relationship to a
      // seeded Flea record. This prevents an isolated similar record from
      // being deleted while still repairing partial legacy cohorts.
      if (!hasSeededFlea) return const <String>{};
      final marker = legacyMarkers.singleOrNull;
      if (marker == null) return const <String>{};
      final markerRecord = byGuideId[marker]!;
      final markerSeededAt = marker == 'bedbug'
          ? markerRecord.lastViewedAt.add(const Duration(minutes: 18))
          : markerRecord.lastViewedAt.add(const Duration(hours: 3));
      final fleaSeededAt = flea.lastViewedAt.add(const Duration(days: 1));
      if (!markerSeededAt.isAtSameMomentAs(fleaSeededAt)) {
        return const <String>{};
      }
    }

    final legacyIds = <String>{...legacyMarkers};
    // A completed Flea guide can be genuine, so remove it only when an
    // unambiguous record from the same retired demo seed is also present.
    if (hasSeededFlea) {
      legacyIds.add('flea');
    }
    return legacyIds;
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _mutationQueue = _mutationQueue.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  Future<void> _persist() async {
    final store = this.store;
    final activeUserId = userId;
    if (store == null || activeUserId == null) return;

    try {
      await store.write(
        userScopedStorageKey('guide-history', activeUserId),
        jsonEncode(<String, Object?>{
          'version': _storageVersion,
          'history': _history
              .map(
                (record) => <String, Object?>{
                  'guideId': record.guideId,
                  'lastViewedAt': record.lastViewedAt.toIso8601String(),
                  'progress': record.progress,
                },
              )
              .toList(growable: false),
        }),
      );
    } catch (_) {
      throw const ProfileDataException(
        'Your bite activity changed, but it could not be saved on this device.',
      );
    }
  }

  ProfileBiteData _buildSnapshot() {
    final sortedRecords = List<_BiteHistoryRecord>.from(_history)
      ..sort((a, b) => b.lastViewedAt.compareTo(a.lastViewedAt));
    final recentBites = sortedRecords
        .map(
          (record) => BiteHistoryItem(
            guide: _requireGuide(record.guideId),
            lastViewedAt: record.lastViewedAt,
            progress: record.progress,
          ),
        )
        .toList(growable: false);

    return ProfileBiteData(
      recentBites: List<BiteHistoryItem>.unmodifiable(recentBites),
      recommendations: List<BiteGuide>.unmodifiable(
        _buildRecommendations(recentBites),
      ),
    );
  }

  List<BiteGuide> _buildRecommendations(List<BiteHistoryItem> recentBites) {
    if (recentBites.isEmpty) return const <BiteGuide>[];

    final viewedIds = recentBites.map((item) => item.guide.id).toSet();
    final tagWeights = <String, int>{};
    final categoryWeights = <String, int>{};

    for (var index = 0; index < recentBites.length; index++) {
      final weight = recentBites.length - index;
      final guide = recentBites[index].guide;
      categoryWeights.update(
        guide.category,
        (value) => value + weight,
        ifAbsent: () => weight,
      );
      for (final tag in guide.filterTags) {
        tagWeights.update(
          tag,
          (value) => value + weight,
          ifAbsent: () => weight,
        );
      }
    }

    final candidates = guides
        .where((guide) => !viewedIds.contains(guide.id))
        .toList(growable: true);
    candidates.sort((a, b) {
      final scoreComparison = _similarityScore(
        b,
        tagWeights,
        categoryWeights,
      ).compareTo(_similarityScore(a, tagWeights, categoryWeights));
      if (scoreComparison != 0) return scoreComparison;
      return a.title.compareTo(b.title);
    });
    return candidates.take(3).toList(growable: false);
  }

  int _similarityScore(
    BiteGuide guide,
    Map<String, int> tagWeights,
    Map<String, int> categoryWeights,
  ) {
    var score = categoryWeights[guide.category] ?? 0;
    for (final tag in guide.filterTags) {
      score += tagWeights[tag] ?? 0;
    }
    return score;
  }

  BiteGuide _requireGuide(String guideId) {
    for (final guide in guides) {
      if (guide.id == guideId) return guide;
    }
    throw ProfileDataException('Unknown bite guide: $guideId');
  }

  void _throwIfUnavailable() {
    if (failRequests) {
      throw const ProfileDataException(
        'Your bite activity could not be loaded. Please try again.',
      );
    }
  }
}

class _DecodedHistory {
  const _DecodedHistory({required this.version, required this.records});

  final int version;
  final List<_BiteHistoryRecord> records;
}

class _UnsupportedHistoryVersionException implements Exception {
  const _UnsupportedHistoryVersionException();
}

class _BiteHistoryRecord {
  const _BiteHistoryRecord({
    required this.guideId,
    required this.lastViewedAt,
    required this.progress,
  });

  final String guideId;
  final DateTime lastViewedAt;
  final double progress;
}
