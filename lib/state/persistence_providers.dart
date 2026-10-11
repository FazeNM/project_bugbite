import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/app_persistence_service.dart';
import '../data/services/user_data_store.dart';

final userDataStoreProvider = Provider<UserDataStore>(
  (ref) => SharedPreferencesUserDataStore(),
);

final appPersistenceServiceProvider = Provider<AppPersistenceService>(
  (ref) => AppPersistenceService(ref.watch(userDataStoreProvider)),
);
