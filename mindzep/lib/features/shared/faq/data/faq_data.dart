import 'package:flutter/material.dart';

/// One question-and-answer pair in the in-app FAQ library.
class FaqEntry {
  const FaqEntry({
    required this.question,
    required this.answer,
    required this.category,
    this.keywords = const <String>[],
    this.isPopular = false,
  });

  final String question;
  final String answer;
  final FaqCategory category;

  /// Extra search terms that do not appear verbatim in the text, so a search
  /// for "refund" still finds the cancellation answer.
  final List<String> keywords;

  /// Surfaced in the "Popular questions" shortcut on Help & Support.
  final bool isPopular;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return question.toLowerCase().contains(q) ||
        answer.toLowerCase().contains(q) ||
        category.label.toLowerCase().contains(q) ||
        keywords.any((keyword) => keyword.toLowerCase().contains(q));
  }
}

/// Groups the FAQ library into browsable sections.
enum FaqCategory {
  gettingStarted('Getting Started', Icons.rocket_launch_rounded),
  booking('Booking & Sessions', Icons.event_available_rounded),
  payments('Payments & Wallet', Icons.account_balance_wallet_rounded),
  privacy('Privacy & Safety', Icons.shield_rounded),
  technical('Technical Help', Icons.build_rounded),
  account('Account', Icons.person_rounded);

  const FaqCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// The FAQ library. Content lives in code so the section works offline and
/// needs no backend round-trip.
class FaqLibrary {
  FaqLibrary._();

  static const List<FaqEntry> all = <FaqEntry>[
    // ── Getting Started ──────────────────────────────────────────────────────
    FaqEntry(
      category: FaqCategory.gettingStarted,
      question: 'What is MindZep?',
      answer:
          'MindZep connects you with qualified psychologists for private, '
          'one-on-one sessions by voice or video. You can talk to someone '
          'immediately, or schedule a session with a therapist you choose. '
          'Alongside sessions you get daily mood check-ins and articles '
          'written by practising psychologists.',
      keywords: ['about', 'what is', 'introduction', 'overview'],
      isPopular: true,
    ),
    FaqEntry(
      category: FaqCategory.gettingStarted,
      question: 'How do I take the app tour again?',
      answer:
          'Open Settings or Help & Support and tap "Replay app tour". The '
          'guided walkthrough restarts from the beginning and highlights each '
          'part of the home screen. You can skip out of it at any point.',
      keywords: ['walkthrough', 'tutorial', 'guide', 'tour', 'onboarding'],
    ),
    FaqEntry(
      category: FaqCategory.gettingStarted,
      question: 'Do I need to complete my profile before booking?',
      answer:
          'Add at least your name and age so your psychologist has some '
          'context before the session begins. Everything else — your photo, '
          'preferences, and background — is optional and can be filled in '
          'later from the Profile tab.',
      keywords: ['profile', 'setup', 'details'],
    ),
    FaqEntry(
      category: FaqCategory.gettingStarted,
      question: 'What are the mood check-ins for?',
      answer:
          'Tapping a mood on the home screen takes two seconds and builds a '
          'record of how you have been feeling between sessions. It helps you '
          'spot patterns, and gives your psychologist a starting point rather '
          'than beginning from scratch each time.',
      keywords: ['mood', 'check in', 'tracking', 'feelings'],
    ),

    // ── Booking & Sessions ───────────────────────────────────────────────────
    FaqEntry(
      category: FaqCategory.booking,
      question: 'How do I book a session with a psychologist?',
      answer:
          'Tap "Book Later" on the home screen or open the Consult tab. Browse '
          'the psychologists, open a profile to read their specialities and '
          'experience, then pick an available slot and confirm. Your booking '
          'appears immediately under the Sessions tab.',
      keywords: ['book', 'appointment', 'schedule', 'slot'],
      isPopular: true,
    ),
    FaqEntry(
      category: FaqCategory.booking,
      question: 'Can I talk to someone right now?',
      answer:
          'Yes. "Talk Now" on the home screen shows psychologists who are '
          'online this minute. If you would rather not choose, use "Connect '
          'Instantly" — one request goes out and the first available '
          'psychologist answers, usually within a couple of minutes.',
      keywords: ['instant', 'now', 'urgent', 'broadcast', 'immediate'],
      isPopular: true,
    ),
    FaqEntry(
      category: FaqCategory.booking,
      question: 'How do video and voice calls work?',
      answer:
          'When your session is due you get a notification — tap it to join, '
          'or open the Sessions tab and tap Join on the appointment. Grant '
          'camera and microphone permission the first time. You can switch '
          'your camera off mid-call if you would rather talk by voice only.',
      keywords: ['video', 'call', 'join', 'camera', 'microphone', 'audio'],
      isPopular: true,
    ),
    FaqEntry(
      category: FaqCategory.booking,
      question: 'Can I reschedule or cancel a session?',
      answer:
          'Open the Sessions tab, find the upcoming appointment, and choose '
          'reschedule or cancel. Cancelling well in advance returns the full '
          'amount to your wallet; cancellations very close to the start time '
          'may be charged, since the slot can no longer be offered to someone '
          'else.',
      keywords: ['cancel', 'reschedule', 'change', 'refund', 'move'],
      isPopular: true,
    ),
    FaqEntry(
      category: FaqCategory.booking,
      question: 'What happens if my psychologist does not join?',
      answer:
          'If nobody joins within a few minutes of the start time, leave the '
          'call and the session is marked as missed. Anything you paid goes '
          'back to your wallet automatically, and you can rebook with the same '
          'psychologist or a different one.',
      keywords: ['no show', 'missed', 'did not join', 'absent'],
    ),
    FaqEntry(
      category: FaqCategory.booking,
      question: 'How long does a session last?',
      answer:
          'Session length is shown on the slot before you book — most run '
          'between 30 and 60 minutes. The remaining time is visible during the '
          'call so neither side is caught off guard by the end.',
      keywords: ['duration', 'length', 'minutes', 'time'],
    ),
    FaqEntry(
      category: FaqCategory.booking,
      question: 'Can I choose the same psychologist again?',
      answer:
          'Yes, and continuity usually helps. Open the Sessions tab, tap a '
          'past session to reach that psychologist\'s profile, and book '
          'another slot with them directly.',
      keywords: ['same therapist', 'again', 'repeat', 'continue'],
    ),

    // ── Payments & Wallet ────────────────────────────────────────────────────
    FaqEntry(
      category: FaqCategory.payments,
      question: 'How do I add money to my wallet?',
      answer:
          'Open the Wallet tab and tap Add Money, then choose an amount. '
          'Payments are processed by Cashfree and support UPI, cards, net '
          'banking and popular wallets. Your balance updates as soon as the '
          'payment is confirmed.',
      keywords: ['add money', 'top up', 'recharge', 'upi', 'card', 'cashfree'],
      isPopular: true,
    ),
    FaqEntry(
      category: FaqCategory.payments,
      question: 'Why is my payment still showing as pending?',
      answer:
          'Bank confirmations occasionally take a minute or two. Leave the '
          'Wallet screen open or pull down to refresh — if the money left your '
          'account but the balance has not moved after about ten minutes, '
          'email support@mindzep.com with the payment reference and it will be '
          'reconciled.',
      keywords: ['pending', 'stuck', 'failed', 'not credited', 'processing'],
    ),
    FaqEntry(
      category: FaqCategory.payments,
      question: 'How do refunds work?',
      answer:
          'Refunds for cancelled or missed sessions go back to your MindZep '
          'wallet, where they are available immediately for the next booking. '
          'Refunds to the original payment method can be requested from '
          'support and typically settle in 5–7 working days.',
      keywords: ['refund', 'money back', 'reversal', 'return'],
    ),
    FaqEntry(
      category: FaqCategory.payments,
      question: 'Is my payment information stored in the app?',
      answer:
          'No. Card and UPI details are handled entirely by our PCI-compliant '
          'payment gateway and are never stored on MindZep servers or on your '
          'device by the app.',
      keywords: ['card details', 'secure', 'stored', 'pci', 'safety'],
    ),
    FaqEntry(
      category: FaqCategory.payments,
      question: 'Do you offer any free or discounted sessions?',
      answer:
          'Promotional credits appear in your wallet automatically when they '
          'apply, and pricing varies between psychologists — each profile '
          'lists the rate before you book, so there are no surprises at '
          'checkout.',
      keywords: ['free', 'discount', 'offer', 'coupon', 'price', 'cost'],
    ),

    // ── Privacy & Safety ─────────────────────────────────────────────────────
    FaqEntry(
      category: FaqCategory.privacy,
      question: 'Are my sessions confidential?',
      answer:
          'Yes. Sessions are private between you and your psychologist, who is '
          'bound by professional confidentiality. Calls are never recorded by '
          'the app, and session notes are visible only to the psychologist you '
          'spoke with.',
      keywords: ['confidential', 'private', 'recorded', 'secret'],
      isPopular: true,
    ),
    FaqEntry(
      category: FaqCategory.privacy,
      question: 'Who can see my data?',
      answer:
          'Your profile details are shared only with psychologists you '
          'actually book. Mood check-ins are yours; a psychologist sees them '
          'only in the context of a session with you. Data is encrypted in '
          'transit and never sold to advertisers.',
      keywords: ['data', 'privacy', 'gdpr', 'share', 'personal information'],
    ),
    FaqEntry(
      category: FaqCategory.privacy,
      question: 'Can I delete my account and data?',
      answer:
          'Yes. Email support@mindzep.com from your registered address and '
          'your account, along with the personal data attached to it, is '
          'removed. Some transaction records are retained where financial '
          'regulations require it.',
      keywords: ['delete', 'remove account', 'erase', 'close account'],
    ),
    FaqEntry(
      category: FaqCategory.privacy,
      question: 'Is MindZep a substitute for emergency care?',
      answer:
          'No. MindZep supports ongoing emotional wellbeing, but it is not an '
          'emergency service. If you or someone else is in immediate danger, '
          'contact your local emergency number or a crisis helpline right '
          'away.',
      keywords: [
        'emergency',
        'crisis',
        'suicide',
        'helpline',
        'urgent help',
        'danger',
      ],
      isPopular: true,
    ),
    FaqEntry(
      category: FaqCategory.privacy,
      question: 'Are the psychologists verified?',
      answer:
          'Every psychologist on MindZep is reviewed before going live — '
          'qualifications, registration and practising experience are all '
          'checked. Their credentials and specialities are listed on their '
          'profile.',
      keywords: ['verified', 'qualified', 'licensed', 'credentials', 'genuine'],
    ),

    // ── Technical Help ───────────────────────────────────────────────────────
    FaqEntry(
      category: FaqCategory.technical,
      question: 'The other person cannot hear or see me. What now?',
      answer:
          'Check that MindZep has camera and microphone permission in your '
          'phone settings, and that no other app is holding the microphone. '
          'Toggling your mic or camera off and on inside the call re-negotiates '
          'the stream and clears most cases; if not, leave and rejoin.',
      keywords: [
        'no audio',
        'no video',
        'cannot hear',
        'black screen',
        'permission',
        'mic',
      ],
      isPopular: true,
    ),
    FaqEntry(
      category: FaqCategory.technical,
      question: 'My call quality is poor.',
      answer:
          'Video needs a steady connection. Move closer to your router or '
          'somewhere with better signal, close heavy apps running in the '
          'background, and switch the camera off to continue on voice only — '
          'audio holds up on much weaker connections.',
      keywords: ['lag', 'freezing', 'quality', 'network', 'slow', 'buffering'],
    ),
    FaqEntry(
      category: FaqCategory.technical,
      question: 'I am not receiving notifications.',
      answer:
          'Allow notifications for MindZep in your phone settings and exclude '
          'the app from battery optimisation or deep-sleep restrictions, which '
          'on many Android phones silence background delivery. Then reopen the '
          'app once so it can refresh its notification token.',
      keywords: [
        'notification',
        'alerts',
        'push',
        'reminder',
        'battery optimisation',
      ],
    ),
    FaqEntry(
      category: FaqCategory.technical,
      question: 'The app is slow or unresponsive.',
      answer:
          'Force-close and reopen the app first. If the problem stays, check '
          'the Play Store for an update — most performance fixes ship in the '
          'newest build. Still stuck? Email support@mindzep.com with your '
          'phone model and Android version.',
      keywords: ['slow', 'crash', 'freeze', 'hang', 'bug', 'not working'],
    ),

    // ── Account ──────────────────────────────────────────────────────────────
    FaqEntry(
      category: FaqCategory.account,
      question: 'How do I change my password?',
      answer:
          'Go to Settings › Change Password. You receive a verification code '
          'on your registered email or phone, and you can set the new password '
          'once it is confirmed.',
      keywords: ['password', 'reset', 'forgot', 'change', 'login'],
    ),
    FaqEntry(
      category: FaqCategory.account,
      question: 'Can I sign in on more than one device?',
      answer:
          'Yes, your account works on any device you sign in to. Sessions and '
          'wallet balance stay in sync. For your own privacy, sign out on any '
          'shared device when you are done.',
      keywords: ['devices', 'multiple', 'login', 'sign in', 'sync'],
    ),
    FaqEntry(
      category: FaqCategory.account,
      question: 'How do I update my email or phone number?',
      answer:
          'Open the Profile tab and tap Edit Profile. Changing an email or '
          'phone number requires verifying the new one before it replaces the '
          'old, so the account stays recoverable.',
      keywords: ['email', 'phone', 'mobile', 'update', 'edit profile'],
    ),
  ];

  static List<FaqEntry> get popular =>
      all.where((entry) => entry.isPopular).toList();

  static List<FaqEntry> byCategory(FaqCategory category) =>
      all.where((entry) => entry.category == category).toList();

  static List<FaqEntry> search(String query, {FaqCategory? category}) {
    return all
        .where((entry) => category == null || entry.category == category)
        .where((entry) => entry.matches(query))
        .toList();
  }

  /// Categories that actually hold at least one entry, in declaration order.
  static List<FaqCategory> get categories => FaqCategory.values
      .where((category) => byCategory(category).isNotEmpty)
      .toList();

  static const String supportEmail = 'support@mindzep.com';
}
