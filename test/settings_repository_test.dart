import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tilapiavision/core/constants.dart';
import 'package:tilapiavision/data/repositories/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('operating threshold defaults to 0.60 when nothing is saved', () async {
    expect(SettingsRepository.defaultOperatingThreshold, 0.60);
    expect(await SettingsRepository().getOperatingThreshold(), 0.60);
  });

  test('the live detection threshold starts at the repository default', () {
    expect(DetectionConfig.operatingThreshold,
        SettingsRepository.defaultOperatingThreshold);
  });

  test('developer options are hidden by default', () async {
    expect(await SettingsRepository().getDeveloperOptions(), isFalse);
    expect(SettingsRepository.defaultDeveloperOptions, isFalse);
  });

  test('developer options persist once unlocked, and can be hidden again',
      () async {
    final repo = SettingsRepository();

    await repo.setDeveloperOptions(true);
    expect(await SettingsRepository().getDeveloperOptions(), isTrue);

    await repo.setDeveloperOptions(false);
    expect(await SettingsRepository().getDeveloperOptions(), isFalse);
  });

  test('unlocking developer options leaves the saved thresholds alone',
      () async {
    final repo = SettingsRepository();
    await repo.setVerifierThreshold(0.6);
    await repo.setOperatingThreshold(0.4);

    await repo.setDeveloperOptions(true);

    expect(await repo.getVerifierThreshold(), 0.6);
    expect(await repo.getOperatingThreshold(), 0.4);
  });
}
