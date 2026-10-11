import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Small key-value boundary used by user-scoped local repositories.
///
/// Keeping the platform plugin behind this contract makes persistence easy to
/// test and replace with Firestore or an encrypted store later.
abstract interface class UserDataStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);
}

class SharedPreferencesUserDataStore implements UserDataStore {
  SharedPreferencesUserDataStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) async {
    await _preferences.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }
}

String userScopedStorageKey(String namespace, String userId) {
  final encodedUser = base64Url.encode(utf8.encode(userId)).replaceAll('=', '');
  return 'bitewise.v1.$namespace.$encodedUser';
}
