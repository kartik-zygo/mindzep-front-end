import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../shared/walkthrough/presentation/walkthrough_coach.dart';
import '../../../../shared/walkthrough/tours/app_tours.dart';

class UserSettingsPage extends StatelessWidget {
  const UserSettingsPage({super.key});

  /// Sends the user back Home and replays the guided tour there, since the
  /// tour highlights widgets that live on the home screen.
  Future<void> _replayTour(BuildContext context) async {
    context.go(RouteNames.userHome);

    // Give Home a moment to build before its targets are measured.
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!context.mounted) return;

    await WalkthroughCoach.replay(
      context,
      tourId: TourIds.userHome,
      steps: AppTours.userHome(),
      accentColor: AppTours.userAccent,
      secondaryColor: AppTours.userSecondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5E5CE6), Color(0xFF8B7CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            context.go(RouteNames.userProfile);
                          }
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
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
                      const Text(
                        'Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingsSection(
                    title: 'Account',
                    items: [
                      _SettingsItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Edit Profile',
                        onTap: () => context.push(RouteNames.userProfile),
                      ),
                      _SettingsItem(
                        icon: Icons.lock_outline_rounded,
                        label: 'Change Password',
                        onTap: () => context.push(RouteNames.forgotPassword),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: 'Notifications',
                    items: [
                      _SettingsItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notification Preferences',
                        onTap: () => context.push(RouteNames.userNotifications),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: 'Support',
                    items: [
                      _SettingsItem(
                        icon: Icons.quiz_outlined,
                        label: 'FAQs',
                        onTap: () => context.push(RouteNames.faqs),
                      ),
                      _SettingsItem(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & Support',
                        onTap: () => context.push(RouteNames.helpSupport),
                      ),
                      _SettingsItem(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Replay app tour',
                        onTap: () => _replayTour(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: 'About',
                    items: [
                      _SettingsItem(
                        icon: Icons.info_outline_rounded,
                        label: 'About MindZep',
                        trailing: const Text(
                          'v1.0.0',
                          style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                        ),
                        onTap: null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isLast = i == items.length - 1;
              return Column(
                children: [
                  _buildRow(item),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      indent: 52,
                      color: Color(0xFFF2F2F7),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(_SettingsItem item) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 17, color: const Color(0xFF5E5CE6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(fontSize: 15, color: Color(0xFF1C1C1E)),
              ),
            ),
            if (item.trailing != null) item.trailing!,
            if (item.onTap != null)
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

class _SettingsItem {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });
}
