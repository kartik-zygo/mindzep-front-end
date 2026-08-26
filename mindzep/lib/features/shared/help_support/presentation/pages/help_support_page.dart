import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../auth/domain/entities/user_entity.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_state.dart';
import '../../../faq/data/faq_data.dart';
import '../../../walkthrough/presentation/walkthrough_coach.dart';
import '../../../walkthrough/tours/app_tours.dart';

/// Support hub: contact routes, a shortcut into the FAQ library, the most
/// asked questions, and a way to replay the guided app tour.
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static const _accent = Color(0xFF5E5CE6);
  static const _secondary = Color(0xFF8B7CF6);

  Future<void> _emailSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: FaqLibrary.supportEmail,
      queryParameters: const {'subject': 'MindZep — Help request'},
    );

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (launched || !context.mounted) return;

    await Clipboard.setData(const ClipboardData(text: FaqLibrary.supportEmail));
    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      message: 'Support email copied: ${FaqLibrary.supportEmail}',
      type: SnackbarType.info,
    );
  }

  /// Replays the tour for whichever home screen this user belongs on. The tour
  /// highlights widgets on that screen, so we send them there first.
  Future<void> _replayTour(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    final role = authState is AuthAuthenticated
        ? authState.user.role
        : UserRole.user;

    if (role == UserRole.admin) {
      AppSnackbar.show(
        context,
        message: 'The guided tour is available on the user and psychologist '
            'apps.',
        type: SnackbarType.info,
      );
      return;
    }

    final isPsych = role == UserRole.psychologist;

    // Leave Help & Support and land on the screen the tour describes.
    context.go(isPsych ? RouteNames.psychDashboard : RouteNames.userHome);

    // Give the destination a moment to build before measuring its targets.
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!context.mounted) return;

    await WalkthroughCoach.replay(
      context,
      tourId: isPsych ? TourIds.psychDashboard : TourIds.userHome,
      steps: isPsych ? AppTours.psychDashboard() : AppTours.userHome(),
      accentColor: isPsych ? AppTours.psychAccent : AppTours.userAccent,
      secondaryColor: isPsych ? AppTours.psychSecondary : AppTours.userSecondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final popular = FaqLibrary.popular.take(4).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Browse the FAQ library ─────────────────────────────────
                  _BrowseFaqsCard(
                    onTap: () => context.push(RouteNames.faqs),
                    count: FaqLibrary.all.length,
                  ),
                  const SizedBox(height: 12),

                  // ── Quick actions ──────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.play_circle_outline_rounded,
                          title: 'Replay app tour',
                          subtitle: 'Walk through the basics again',
                          onTap: () => _replayTour(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.mail_outline_rounded,
                          title: 'Email support',
                          subtitle: 'We reply within 24 hours',
                          onTap: () => _emailSupport(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Popular questions ──────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'POPULAR QUESTIONS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E8E93),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push(RouteNames.faqs),
                        child: const Row(
                          children: [
                            Text(
                              'See all',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _accent,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: _accent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      children: List.generate(popular.length, (i) {
                        return Column(
                          children: [
                            _PopularFaqRow(
                              entry: popular[i],
                              onTap: () => context.push(
                                RouteNames.faqs,
                                extra: popular[i].category,
                              ),
                            ),
                            if (i != popular.length - 1)
                              const Divider(
                                height: 1,
                                indent: 16,
                                color: Color(0xFFF2F2F7),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Browse by topic ────────────────────────────────────────
                  const Text(
                    'BROWSE BY TOPIC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8E8E93),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: FaqLibrary.categories
                        .map(
                          (category) => _TopicChip(
                            category: category,
                            count: FaqLibrary.byCategory(category).length,
                            onTap: () => context.push(
                              RouteNames.faqs,
                              extra: category,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Contact card ───────────────────────────────────────────
                  _ContactCard(onTap: () => _emailSupport(context)),
                  const SizedBox(height: 12),
                  const _CrisisNote(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, _secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Help & Support',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Answers, guides and a way to reach us',
                      style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _BrowseFaqsCard extends StatelessWidget {
  const _BrowseFaqsCard({required this.onTap, required this.count});

  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5E5CE6), Color(0xFF8B7CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5E5CE6).withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Search $count answers on booking, payments, privacy and '
                    'calls',
                    style: const TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0FF),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF5E5CE6)),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularFaqRow extends StatelessWidget {
  const _PopularFaqRow({required this.entry, required this.onTap});

  final FaqEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(entry.category.icon, size: 16, color: const Color(0xFF5E5CE6)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.question,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: Color(0xFF1C1C1E),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFFC7C7CC),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.category,
    required this.count,
    required this.onTap,
  });

  final FaqCategory category;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 14, color: const Color(0xFF5E5CE6)),
            const SizedBox(width: 7),
            Text(
              category.label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: const TextStyle(fontSize: 11, color: Color(0xFFAEAEB2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.email_outlined,
                color: Color(0xFF5E5CE6),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Support',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    FaqLibrary.supportEmail,
                    style: TextStyle(fontSize: 13, color: Color(0xFF5E5CE6)),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFFC7C7CC),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrisisNote extends StatelessWidget {
  const _CrisisNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD9A8)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFB26A00),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'MindZep is not an emergency service. If you or someone else is '
              'in immediate danger, contact your local emergency number or a '
              'crisis helpline straight away.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF8A5200),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
