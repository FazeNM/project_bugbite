import 'dart:convert';

import '../models/community_post.dart';
import '../seed/seed_data.dart';
import 'user_data_store.dart';

class AppPersistenceException implements Exception {
  const AppPersistenceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PersistedAppData {
  const PersistedAppData({
    required this.posts,
    required this.savedGuideIds,
    required this.gentleReminders,
    required this.stripPhotoMetadata,
  });

  final List<CommunityPost> posts;
  final Set<String> savedGuideIds;
  final bool gentleReminders;
  final bool stripPhotoMetadata;
}

class AppPersistenceService {
  const AppPersistenceService(this._store);

  static const _storageVersion = 2;
  static const _legacyDefaultSavedGuideIds = <String>{'mosquito', 'bedbug'};

  final UserDataStore _store;

  Future<PersistedAppData?> load(String userId) async {
    try {
      final raw = await _store.read(userScopedStorageKey('app', userId));
      if (raw == null) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Invalid saved-data format.');
      }
      final version = decoded['version'];
      if (version != 1 && version != _storageVersion) {
        throw const FormatException('Unsupported saved-data format.');
      }

      final knownGuideIds = guides.map((guide) => guide.id).toSet();
      final posts = <CommunityPost>[];
      for (final value in decoded['posts']! as List<Object?>) {
        if (value is! Map<String, Object?>) continue;
        try {
          final post = CommunityPost.fromJson(value);
          if (post.guideId == null || knownGuideIds.contains(post.guideId)) {
            posts.add(post);
          }
        } on Object {
          // One damaged post must not prevent the rest of the profile loading.
        }
      }

      final savedGuideIds = (decoded['savedGuideIds']! as List<Object?>)
          .whereType<String>()
          .where(knownGuideIds.contains)
          .toSet();

      // Version 1 gave every account these two bookmarks before the user made
      // a choice. Remove those injected defaults once while preserving every
      // other bookmark the user added.
      if (version == 1) {
        savedGuideIds.removeAll(_legacyDefaultSavedGuideIds);
      }

      final result = PersistedAppData(
        posts: List<CommunityPost>.unmodifiable(posts),
        savedGuideIds: Set<String>.unmodifiable(savedGuideIds),
        gentleReminders: decoded['gentleReminders'] as bool? ?? true,
        stripPhotoMetadata: decoded['stripPhotoMetadata'] as bool? ?? true,
      );
      if (version == 1) await save(userId, result);
      return result;
    } on AppPersistenceException {
      rethrow;
    } catch (_) {
      throw const AppPersistenceException(
        'Saved app data could not be loaded on this device.',
      );
    }
  }

  Future<void> save(String userId, PersistedAppData data) async {
    try {
      final payload = jsonEncode(<String, Object?>{
        'version': _storageVersion,
        'posts': data.posts
            .map((post) => post.toJson())
            .toList(growable: false),
        'savedGuideIds': data.savedGuideIds.toList(growable: false)..sort(),
        'gentleReminders': data.gentleReminders,
        'stripPhotoMetadata': data.stripPhotoMetadata,
      });
      await _store.write(userScopedStorageKey('app', userId), payload);
    } catch (_) {
      throw const AppPersistenceException(
        'Changes could not be saved on this device.',
      );
    }
  }
}
