import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_localizations.dart';

/// Persists and exposes the currently selected [AppLocale].
/// Follows the same load/notify pattern as [SettingsProvider].
class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_locale';

  AppLocale _locale = AppLocale.english;
  bool loading = true;

  AppLocale get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      _locale = AppLocale.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => AppLocale.english,
      );
    }
    loading = false;
    notifyListeners();
  }

  Future<void> setLocale(AppLocale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.name);
  }
}
