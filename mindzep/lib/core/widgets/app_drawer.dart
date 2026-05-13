import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../mock/mock_data.dart';
import '../router/route_names.dart';
import '../widgets/app_avatar.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';

// ── Nav item model ────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  final String? badge;
  const _NavItem({required this.label, required this.icon, required this.route, this.badge});
}

const _mainNav = [
  _NavItem(label: 'Home', icon: Icons.home_rounded, route: RouteNames.userHome),
  _NavItem(label: 'Consult Now', icon: Icons.headphones_rounded, route: RouteNames.userConsult),
  _NavItem(label: 'My Sessions', icon: Icons.calendar_today_rounded, route: RouteNames.userAppointments),
  _NavItem(label: 'Wallet', icon: Icons.account_balance_wallet_rounded, route: RouteNames.userWallet),
];

const _accountNav = [
  _NavItem(label: 'My Profile', icon: Icons.person_rounded, route: RouteNames.userProfile),
  _NavItem(label: 'Notifications', icon: Icons.notifications_rounded, route: RouteNames.userNotifications, badge: '3'),
  _NavItem(label: 'Settings', icon: Icons.settings_rounded, route: ''),
];

// ── Drawer widget ─────────────────────────────────────────────────────────────

class AppUserDrawer extends StatelessWidget {
  const AppUserDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentUser;
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final sessions = MockData.appointments.length;
    final streak = '7d';
    const wallet = '₹415';

    return Drawer(
      width: 300,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0B2B), Color(0xFF1A1060), Color(0xFF0D2040)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Glowing orbs
            Positioned(
              top: -50, left: -50,
              child: Container(
                width: 220, height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0x305E5CE6), Colors.transparent]),
                ),
              ),
            ),
            Positioned(
              bottom: 80, right: -30,
              child: Container(
                width: 160, height: 160,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0x2630B0C7), Colors.transparent]),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
                    child: Row(children: [
                      // Logo
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF5E5CE6), Color(0xFF8B7CF6)]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.favorite_rounded, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3),
                          children: [
                            TextSpan(text: 'Mind'),
                            TextSpan(text: 'Zep', style: TextStyle(color: Color(0xFF30B0C7))),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.close_rounded, color: Color(0xB3FFFFFF), size: 18),
                        ),
                      ),
                    ]),
                  ),

                  // ── Profile card ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(children: [
                        Row(children: [
                          Stack(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AppAvatar(
                                imageUrl: user.avatarUrl,
                                radius: 28,
                                initials: _initials(user.name),
                              ),
                            ),
                            Positioned(
                              bottom: -2, right: -2,
                              child: Container(
                                width: 20, height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5E5CE6),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF0D0B2B), width: 2),
                                ),
                                child: const Icon(Icons.verified_rounded, size: 11, color: Colors.white),
                              ),
                            ),
                          ]),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              const Text('Mental Wellness Member', style: TextStyle(fontSize: 11, color: Color(0x80FFFFFF))),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5E5CE6).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.auto_awesome_rounded, size: 10, color: Color(0xFF5E5CE6)),
                                  SizedBox(width: 3),
                                  Text('Member', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF5E5CE6))),
                                ]),
                              ),
                            ],
                          )),
                        ]),
                        const SizedBox(height: 12),
                        // Stats row
                        Row(children: [
                          _StatsCell(label: 'Sessions', value: '$sessions'),
                          const SizedBox(width: 8),
                          _StatsCell(label: 'Streak', value: streak),
                          const SizedBox(width: 8),
                          _StatsCell(label: 'Wallet', value: wallet),
                        ]),
                      ]),
                    ),
                  ),

                  // ── Scrollable nav content ───────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Navigate section
                          const _SectionLabel('Navigate'),
                          const SizedBox(height: 6),
                          ..._mainNav.map((item) => _NavTile(
                            item: item,
                            isActive: currentRoute == item.route,
                            activeGradient: const [Color(0xFF5E5CE6), Color(0xFF8B7CF6)],
                            onTap: () {
                              Navigator.of(context).pop();
                              if (item.route.isNotEmpty) context.go(item.route);
                            },
                          )),

                          const SizedBox(height: 12),
                          Divider(color: Colors.white.withOpacity(0.07), height: 1),
                          const SizedBox(height: 12),

                          // Account section
                          const _SectionLabel('Account'),
                          const SizedBox(height: 6),
                          ..._accountNav.map((item) => _NavTile(
                            item: item,
                            isActive: currentRoute == item.route && item.route.isNotEmpty,
                            activeGradient: const [Color(0xFF5E5CE6), Color(0xFF8B7CF6)],
                            onTap: () {
                              Navigator.of(context).pop();
                              if (item.route.isNotEmpty) context.go(item.route);
                            },
                          )),

                          const SizedBox(height: 12),
                          Divider(color: Colors.white.withOpacity(0.07), height: 1),
                          const SizedBox(height: 6),

                          // Help
                          _PlainNavTile(
                            icon: Icons.help_outline_rounded,
                            label: 'Help & Support',
                            onTap: () => Navigator.of(context).pop(),
                          ),

                          const SizedBox(height: 12),
                          Divider(color: Colors.white.withOpacity(0.07), height: 1),
                          const SizedBox(height: 12),

                          // Logout
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              Future.microtask(() {
                                if (context.mounted) {
                                  context.read<AuthBloc>().add(const LogoutRequested());
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF3B30).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFFF3B30)),
                                ),
                                const SizedBox(width: 12),
                                const Text('Sign Out', style: TextStyle(fontSize: 14, color: Color(0xFFFF3B30), fontWeight: FontWeight.w500)),
                              ]),
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Center(
                            child: Text('MindZep v1.0.0 · © 2026',
                              style: TextStyle(fontSize: 11, color: Color(0x33FFFFFF))),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _StatsCell extends StatelessWidget {
  final String label, value;
  const _StatsCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0x73FFFFFF))),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0x4DFFFFFF), letterSpacing: 1.2),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final List<Color> activeGradient;
  final VoidCallback onTap;
  const _NavTile({required this.item, required this.isActive, required this.activeGradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [activeGradient[0].withOpacity(0.22), activeGradient[1].withOpacity(0.14)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? activeGradient[0].withOpacity(0.35) : Colors.transparent,
          ),
        ),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: isActive ? activeGradient[0].withOpacity(0.25) : Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 16, color: isActive ? activeGradient[0] : const Color(0x80FFFFFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.white : const Color(0x99FFFFFF),
              ),
            ),
          ),
          if (item.badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFFF3B30), borderRadius: BorderRadius.circular(10)),
              child: Text(item.badge!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          if (isActive)
            Icon(Icons.chevron_right_rounded, size: 14, color: activeGradient[0]),
        ]),
      ),
    );
  }
}

class _PlainNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PlainNavTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: const Color(0x80FFFFFF)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0x99FFFFFF)))),
          const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0x40FFFFFF)),
        ]),
      ),
    );
  }
}

// ── Psychologist Drawer ───────────────────────────────────────────────────────

const _psychMainNav = [
  _NavItem(label: 'Dashboard', icon: Icons.dashboard_rounded, route: RouteNames.psychDashboard),
  _NavItem(label: 'My Sessions', icon: Icons.video_call_rounded, route: RouteNames.psychSessions),
  _NavItem(label: 'Manage Slots', icon: Icons.calendar_view_week_rounded, route: RouteNames.psychSlots),
  _NavItem(label: 'My Blog', icon: Icons.article_rounded, route: RouteNames.psychBlogs),
];

const _psychAccountNav = [
  _NavItem(label: 'My Profile', icon: Icons.person_rounded, route: RouteNames.psychProfile),
];

class AppPsychDrawer extends StatelessWidget {
  const AppPsychDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final psych = MockData.psychologists.first;
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final sessions = MockData.psychSessions.length;

    return Drawer(
      width: 300,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF052530), Color(0xFF0B3D47), Color(0xFF082535)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Glowing orbs
            Positioned(
              top: -50, left: -50,
              child: Container(
                width: 220, height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0x3030B0C7), Colors.transparent]),
                ),
              ),
            ),
            Positioned(
              bottom: 80, right: -30,
              child: Container(
                width: 160, height: 160,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0x2634C7A3), Colors.transparent]),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 16),
                    child: Row(children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.psychology_rounded, size: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3),
                          children: [
                            TextSpan(text: 'Mind'),
                            TextSpan(text: 'Zep', style: TextStyle(color: Color(0xFF34C7A3))),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.close_rounded, color: Color(0xB3FFFFFF), size: 18),
                        ),
                      ),
                    ]),
                  ),

                  // ── Profile card ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(children: [
                        Row(children: [
                          Stack(children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF30B0C7), Color(0xFF34C7A3)]),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  _initials(psych.name),
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -2, right: -2,
                              child: Container(
                                width: 20, height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34C759),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF052530), width: 2),
                                ),
                                child: const Icon(Icons.check_rounded, size: 11, color: Colors.white),
                              ),
                            ),
                          ]),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(psych.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(psych.specialization, style: const TextStyle(fontSize: 11, color: Color(0x80FFFFFF)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF30B0C7).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.verified_rounded, size: 10, color: Color(0xFF30B0C7)),
                                  SizedBox(width: 3),
                                  Text('Verified Expert', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF30B0C7))),
                                ]),
                              ),
                            ],
                          )),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          _StatsCell(label: 'Sessions', value: '${sessions + 230}'),
                          const SizedBox(width: 8),
                          _StatsCell(label: 'Rating', value: '${psych.ratingAverage.toStringAsFixed(1)}★'),
                          const SizedBox(width: 8),
                          _StatsCell(label: 'Experience', value: '${psych.yearsExperience}y'),
                        ]),
                      ]),
                    ),
                  ),

                  // ── Scrollable nav content ──────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel('Navigate'),
                          const SizedBox(height: 6),
                          ..._psychMainNav.map((item) => _NavTile(
                            item: item,
                            isActive: currentRoute == item.route,
                            activeGradient: const [Color(0xFF30B0C7), Color(0xFF34C7A3)],
                            onTap: () {
                              Navigator.of(context).pop();
                              if (item.route.isNotEmpty) context.go(item.route);
                            },
                          )),

                          const SizedBox(height: 12),
                          Divider(color: Colors.white.withOpacity(0.07), height: 1),
                          const SizedBox(height: 12),

                          const _SectionLabel('Account'),
                          const SizedBox(height: 6),
                          ..._psychAccountNav.map((item) => _NavTile(
                            item: item,
                            isActive: currentRoute == item.route,
                            activeGradient: const [Color(0xFF30B0C7), Color(0xFF34C7A3)],
                            onTap: () {
                              Navigator.of(context).pop();
                              if (item.route.isNotEmpty) context.go(item.route);
                            },
                          )),

                          const SizedBox(height: 12),
                          Divider(color: Colors.white.withOpacity(0.07), height: 1),
                          const SizedBox(height: 6),

                          _PlainNavTile(
                            icon: Icons.help_outline_rounded,
                            label: 'Help & Support',
                            onTap: () => Navigator.of(context).pop(),
                          ),

                          const SizedBox(height: 12),
                          Divider(color: Colors.white.withOpacity(0.07), height: 1),
                          const SizedBox(height: 12),

                          // Logout
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              Future.microtask(() {
                                if (context.mounted) {
                                  context.read<AuthBloc>().add(const LogoutRequested());
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF3B30).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFFF3B30)),
                                ),
                                const SizedBox(width: 12),
                                const Text('Sign Out', style: TextStyle(fontSize: 14, color: Color(0xFFFF3B30), fontWeight: FontWeight.w500)),
                              ]),
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Center(
                            child: Text('MindZep v1.0.0 · © 2026',
                              style: TextStyle(fontSize: 11, color: Color(0x33FFFFFF))),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}

