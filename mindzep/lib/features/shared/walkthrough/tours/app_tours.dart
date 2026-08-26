import 'package:flutter/material.dart';

import '../domain/walkthrough_step.dart';
import '../walkthrough_keys.dart';

/// Tour identifiers used as the SharedPreferences "seen" keys. Bump the suffix
/// when a tour changes materially and should run again for existing users.
class TourIds {
  TourIds._();

  static const userHome = 'user_home_v1';
  static const psychDashboard = 'psych_dashboard_v1';
}

/// Step definitions for the guided walkthroughs.
class AppTours {
  AppTours._();

  static const userAccent = Color(0xFF5E5CE6);
  static const userSecondary = Color(0xFF8B7CF6);
  static const psychAccent = Color(0xFF30B0C7);
  static const psychSecondary = Color(0xFF34C7A3);

  /// First-run tour for someone booking therapy.
  static List<WalkthroughStep> userHome() => [
    const WalkthroughStep(
      title: 'Welcome to MindZep',
      description:
          'A quick 30-second tour of the essentials — booking a session, '
          'talking to someone right now, and where to find your money and '
          'appointments. You can skip it at any point.',
      icon: Icons.spa_rounded,
    ),
    WalkthroughStep(
      targetKey: WalkthroughKeys.userMood,
      title: 'Check in with yourself',
      description:
          'Tap the mood that fits how you feel today. Your check-ins build a '
          'picture over time and help your psychologist start from the right '
          'place.',
      icon: Icons.mood_rounded,
      spotlightPadding: 10,
      borderRadius: 22,
    ),
    WalkthroughStep(
      targetKey: WalkthroughKeys.userQuickActions,
      title: 'Talk now, or book for later',
      description:
          '"Talk Now" connects you with a psychologist who is online this '
          'minute. "Book Later" lets you pick a specific therapist and a slot '
          'that suits your day.',
      icon: Icons.bolt_rounded,
      spotlightPadding: 10,
      borderRadius: 20,
    ),
    WalkthroughStep(
      targetKey: WalkthroughKeys.userBroadcast,
      title: 'Connect instantly',
      description:
          'Not sure who to pick? Send one request and the first available '
          'psychologist answers — usually within a couple of minutes.',
      icon: Icons.radio_rounded,
      spotlightPadding: 10,
      borderRadius: 24,
    ),
    WalkthroughStep(
      targetKey: WalkthroughKeys.userTherapists,
      title: 'Browse psychologists',
      description:
          'Read profiles, specialities and availability before you book. Tap '
          'anyone to see their full profile and open slots.',
      icon: Icons.psychology_rounded,
      spotlightPadding: 10,
      borderRadius: 20,
    ),
    WalkthroughStep(
      targetKey: WalkthroughKeys.userWallet,
      title: 'Your wallet',
      description:
          'Sessions are paid from your MindZep wallet. Top it up here in a few '
          'taps — payments are handled securely and refunds land back in the '
          'same place.',
      icon: Icons.account_balance_wallet_rounded,
      spotlightPadding: 6,
      borderRadius: 20,
    ),
    WalkthroughStep(
      targetKey: WalkthroughKeys.userNotifications,
      title: 'Never miss a session',
      description:
          'Reminders, session invites and psychologist replies all land here. '
          'Keep notifications on so you get the nudge when a call starts.',
      icon: Icons.notifications_rounded,
      shape: WalkthroughShape.circle,
      spotlightPadding: 6,
    ),
    WalkthroughStep(
      targetKey: WalkthroughKeys.userMenu,
      title: 'Menu and help',
      description:
          'Everything else lives behind this menu — your blogs, settings and '
          'the FAQs. Stuck at any point? Help & Support is one tap away.',
      icon: Icons.menu_rounded,
      shape: WalkthroughShape.circle,
      spotlightPadding: 6,
    ),
    WalkthroughStep(
      targetKey: WalkthroughKeys.userNavBar,
      title: 'Your five tabs',
      description:
          'Home, Consult, Sessions, Wallet and Profile. Sessions is where your '
          'upcoming and past appointments live — that is where you join a '
          'call.',
      icon: Icons.dashboard_rounded,
      spotlightPadding: 4,
      borderRadius: 22,
    ),
    const WalkthroughStep(
      title: 'That is the whole app',
      description:
          'You can replay this tour any time from Settings or Help & Support, '
          'and the FAQs there answer the most common questions about booking, '
          'payments and privacy.',
      icon: Icons.check_circle_rounded,
    ),
  ];

  /// First-run tour for a psychologist landing on their dashboard.
  static List<WalkthroughStep> psychDashboard() => [
    const WalkthroughStep(
      title: 'Welcome to your practice',
      description:
          'A quick tour of your dashboard — going online, opening slots and '
          'keeping track of your sessions. Skip whenever you like.',
      icon: Icons.waving_hand_rounded,
    ),
    WalkthroughStep(
      targetKey: WalkthroughKeys.psychAvailability,
      title: 'Go online to take calls',
      description:
          'This switch controls whether clients can reach you right now. Turn '
          'it on and instant-call requests start ringing on your device.',
      icon: Icons.podcasts_rounded,
      spotlightPadding: 8,
      borderRadius: 20,
    ),
    WalkthroughStep(
      targetKey: WalkthroughKeys.psychQuickActions,
      title: 'Slots and blogs',
      description:
          '"Add Slot" opens bookable time in your calendar — clients can only '
          'book what you publish here. "Write Blog" shares your insights with '
          'the whole community.',
      icon: Icons.event_available_rounded,
      spotlightPadding: 10,
      borderRadius: 20,
    ),
    WalkthroughStep(
      targetKey: WalkthroughKeys.psychMenu,
      title: 'Menu and help',
      description:
          'Your profile, earnings and settings sit behind this menu, together '
          'with Help & Support and the FAQs.',
      icon: Icons.menu_rounded,
      shape: WalkthroughShape.circle,
      spotlightPadding: 6,
    ),
    WalkthroughStep(
      targetKey: WalkthroughKeys.psychNavBar,
      title: 'Your five tabs',
      description:
          'Dashboard, Slots, Sessions, Blogs and Profile. Sessions is where '
          'you join scheduled calls and review past ones.',
      icon: Icons.dashboard_rounded,
      spotlightPadding: 4,
      borderRadius: 22,
    ),
    const WalkthroughStep(
      title: 'You are all set',
      description:
          'Replay this tour any time from Help & Support, where the FAQs also '
          'cover payouts, cancellations and client privacy.',
      icon: Icons.check_circle_rounded,
    ),
  ];
}
