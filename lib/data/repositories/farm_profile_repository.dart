import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/farm_profile.dart';

/// Local-only Farm Profile storage — no accounts, no cloud, no
/// passwords. See the No-Login Architecture note in the UI/UX design
/// philosophy. A single lightweight key-value pair is enough here, so
/// this deliberately uses SharedPreferences rather than adding a
/// second SQLite table for one record.
class FarmProfileRepository {
  static const _key = 'farm_profile';

  Future<FarmProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return FarmProfile.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  Future<void> saveProfile(FarmProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  Future<bool> hasProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }
}
