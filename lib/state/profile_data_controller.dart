import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/profile_bite_data.dart';
import '../data/services/profile_data_service.dart';
import 'auth_controller.dart';
import 'persistence_providers.dart';

final profileDataServiceProvider = Provider<ProfileDataService>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  return ProfileDataService(
    userId: userId,
    store: ref.watch(userDataStoreProvider),
    loadDelay: userId == null
        ? Duration.zero
        : const Duration(milliseconds: 900),
  );
});

class ProfileDataController extends AsyncNotifier<ProfileBiteData> {
  ProfileDataService get _service => ref.read(profileDataServiceProvider);

  @override
  Future<ProfileBiteData> build() =>
      ref.watch(profileDataServiceProvider).loadProfileData();

  Future<void> reload() async {
    state = const AsyncLoading<ProfileBiteData>();
    state = await AsyncValue.guard(_service.loadProfileData);
  }

  Future<void> recordGuideOpened(String guideId) async {
    try {
      state = AsyncData(await _service.recordGuideOpened(guideId));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<bool> markGuideCompleted(String guideId) async {
    try {
      state = AsyncData(await _service.markGuideCompleted(guideId));
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final profileDataProvider =
    AsyncNotifierProvider<ProfileDataController, ProfileBiteData>(
      ProfileDataController.new,
    );
