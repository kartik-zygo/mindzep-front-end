import 'package:shared_preferences/shared_preferences.dart';

import '../../../../injection/injection_container.dart';

/// Tracks which guided tours a user has already been through.
///
/// Backed by the [SharedPreferences] singleton registered in the injection
/// container, so reads are synchronous once the app has booted.
class WalkthroughPrefs {
  WalkthroughPrefs._();

  static const _prefix = 'walkthrough_seen_';

  static SharedPreferences? get _prefs =>
      sl.isRegistered<SharedPreferences>() ? sl<SharedPreferences>() : null;

  static String _key(String tourId) => '$_prefix$tourId';

  /// Whether the tour identified by [tourId] has already been completed or
  /// skipped.
  ///
  /// An unset flag means the user has not seen it yet. If preferences are not
  /// available at all the answer is `true`, so a tour never pops up
  /// unexpectedly on a half-initialised app — and, more importantly, is never
  /// shown again and again because the "seen" write had nowhere to land.
  static bool hasSeen(String tourId) {
    final prefs = _prefs;
    if (prefs == null) return true;
    return prefs.getBool(_key(tourId)) ?? false;
  }

  static Future<void> markSeen(String tourId) async {
    await _prefs?.setBool(_key(tourId), true);
  }

  /// Clears the "seen" flag so the tour runs again on the next opportunity.
  static Future<void> reset(String tourId) async {
    await _prefs?.remove(_key(tourId));
  }
}
