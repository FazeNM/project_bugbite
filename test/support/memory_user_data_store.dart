import 'package:project_bugbite/data/services/user_data_store.dart';

class MemoryUserDataStore implements UserDataStore {
  MemoryUserDataStore({
    Map<String, String>? values,
    this.failReads = false,
    this.failWrites = false,
  }) : values = values ?? <String, String>{};

  final Map<String, String> values;
  bool failReads;
  bool failWrites;

  @override
  Future<String?> read(String key) async {
    if (failReads) throw StateError('Read failed');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('Write failed');
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}
