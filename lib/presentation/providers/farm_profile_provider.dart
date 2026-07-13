import 'package:flutter/foundation.dart';

import '../../data/models/farm_profile.dart';
import '../../data/repositories/farm_profile_repository.dart';

/// Exposes the local Farm Profile to the widget tree and decides
/// whether onboarding has already run.
class FarmProfileProvider extends ChangeNotifier {
  FarmProfileProvider({FarmProfileRepository? repository}) : _repository = repository ?? FarmProfileRepository();

  final FarmProfileRepository _repository;

  FarmProfile? profile;
  bool loading = true;

  bool get hasProfile => profile != null;

  Future<void> load() async {
    profile = await _repository.getProfile();
    loading = false;
    notifyListeners();
  }

  Future<void> createProfile(String name) async {
    final newProfile = FarmProfile(
      name: name,
      createdAt: DateTime.now(),
      acknowledgedStorageNotice: true,
    );
    await _repository.saveProfile(newProfile);
    profile = newProfile;
    notifyListeners();
  }
}
