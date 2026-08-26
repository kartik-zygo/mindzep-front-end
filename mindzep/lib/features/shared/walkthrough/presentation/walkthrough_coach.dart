import 'package:flutter/material.dart';

import '../data/walkthrough_prefs.dart';
import '../domain/walkthrough_step.dart';
import 'widgets/walkthrough_overlay.dart';

/// Entry point for running a guided product tour.
///
/// The overlay is pushed on the root navigator as a transparent route, so the
/// screen being explained stays mounted and every target stays measurable.
class WalkthroughCoach {
  WalkthroughCoach._();

  /// True while a tour is on screen — guards against a second tour being
  /// launched by a rebuild or a lifecycle callback.
  static bool _running = false;

  static bool get isRunning => _running;

  /// Runs [steps] immediately and records [tourId] as seen when it ends.
  static Future<void> start(
    BuildContext context, {
    required String tourId,
    required List<WalkthroughStep> steps,
    Color accentColor = const Color(0xFF5E5CE6),
    Color secondaryColor = const Color(0xFF8B7CF6),
  }) async {
    if (_running || steps.isEmpty || !context.mounted) return;
    _running = true;

    try {
      await Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder<void>(
          opaque: false,
          barrierColor: Colors.transparent,
          barrierDismissible: false,
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (_, __, ___) => WalkthroughOverlay(
            steps: steps,
            accentColor: accentColor,
            secondaryColor: secondaryColor,
          ),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } finally {
      _running = false;
    }

    await WalkthroughPrefs.markSeen(tourId);
  }

  /// Runs the tour only the first time a user reaches this screen.
  ///
  /// Call from `initState` or right after the screen's data has loaded; the
  /// [delay] gives the layout a moment to settle so targets can be measured.
  static Future<void> startIfFirstTime(
    BuildContext context, {
    required String tourId,
    required List<WalkthroughStep> steps,
    Duration delay = const Duration(milliseconds: 600),
    Color accentColor = const Color(0xFF5E5CE6),
    Color secondaryColor = const Color(0xFF8B7CF6),
  }) async {
    if (_running || WalkthroughPrefs.hasSeen(tourId)) return;

    await Future<void>.delayed(delay);
    if (!context.mounted) return;

    // A route pushed on top in the meantime (an incoming call, a deep link)
    // means this screen is no longer what the user is looking at.
    if (ModalRoute.of(context)?.isCurrent == false) return;

    await start(
      context,
      tourId: tourId,
      steps: steps,
      accentColor: accentColor,
      secondaryColor: secondaryColor,
    );
  }

  /// Clears the "seen" flag and replays the tour — used by the
  /// "Replay app tour" entries in Settings and Help & Support.
  static Future<void> replay(
    BuildContext context, {
    required String tourId,
    required List<WalkthroughStep> steps,
    Color accentColor = const Color(0xFF5E5CE6),
    Color secondaryColor = const Color(0xFF8B7CF6),
  }) async {
    await WalkthroughPrefs.reset(tourId);
    if (!context.mounted) return;
    await start(
      context,
      tourId: tourId,
      steps: steps,
      accentColor: accentColor,
      secondaryColor: secondaryColor,
    );
  }
}
