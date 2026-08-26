import 'package:flutter/material.dart';

/// Keys attached to the widgets a guided tour highlights.
///
/// They live here rather than inside each page because some targets sit in the
/// navigation shell while the tour is driven from the page inside it. Every
/// keyed widget is a singleton in the tree (one shell, one home page, one
/// dashboard), so a shared key is never mounted twice.
class WalkthroughKeys {
  WalkthroughKeys._();

  // ── User home ──────────────────────────────────────────────────────────────
  static final userMenu = GlobalKey(debugLabel: 'walkthrough_user_menu');
  static final userNotifications = GlobalKey(
    debugLabel: 'walkthrough_user_notifications',
  );
  static final userWallet = GlobalKey(debugLabel: 'walkthrough_user_wallet');
  static final userMood = GlobalKey(debugLabel: 'walkthrough_user_mood');
  static final userQuickActions = GlobalKey(
    debugLabel: 'walkthrough_user_quick_actions',
  );
  static final userBroadcast = GlobalKey(
    debugLabel: 'walkthrough_user_broadcast',
  );
  static final userTherapists = GlobalKey(
    debugLabel: 'walkthrough_user_therapists',
  );

  // ── User shell bottom navigation ───────────────────────────────────────────
  static final userNavBar = GlobalKey(debugLabel: 'walkthrough_user_nav_bar');

  // ── Psychologist dashboard ─────────────────────────────────────────────────
  static final psychMenu = GlobalKey(debugLabel: 'walkthrough_psych_menu');
  static final psychAvailability = GlobalKey(
    debugLabel: 'walkthrough_psych_availability',
  );
  static final psychQuickActions = GlobalKey(
    debugLabel: 'walkthrough_psych_quick_actions',
  );
  static final psychNavBar = GlobalKey(debugLabel: 'walkthrough_psych_nav_bar');
}
