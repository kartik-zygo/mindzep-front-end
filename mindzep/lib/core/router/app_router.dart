import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/user/home/presentation/bloc/psychologist_list_bloc.dart';
import '../../features/user/home/presentation/pages/psychologist_detail_page.dart';
import '../../features/user/home/presentation/pages/user_home_page.dart';
import '../../features/user/appointments/presentation/pages/appointments_page.dart';
import '../../features/user/booking/presentation/pages/booking_confirmed_page.dart';
import '../../features/user/booking/presentation/pages/payment_page.dart';
import '../../features/user/booking/presentation/pages/slot_booking_page.dart';
import '../../features/user/call/presentation/bloc/call_bloc.dart';
import '../../features/user/call/presentation/pages/active_call_screen.dart';
import '../../features/user/call/presentation/pages/post_call_summary_screen.dart';
import '../../features/user/call/presentation/pages/pre_call_screen.dart';
import '../../features/user/profile/presentation/pages/user_profile_page.dart';
import '../../features/user/consult/presentation/pages/consult_page.dart';
import '../../features/user/wallet/presentation/pages/user_wallet_page.dart';
import '../../features/user/broadcast/presentation/pages/broadcast_call_page.dart';
import '../../features/user/blog/presentation/pages/blog_list_page.dart';
import '../../features/user/blog/presentation/pages/blog_detail_page.dart';
import '../../features/user/notifications/presentation/pages/notifications_page.dart';
import '../../features/psychologist/blog/presentation/pages/psych_blog_page.dart';
import '../../features/psychologist/blog/presentation/pages/psych_blog_detail_page.dart';
import '../../features/psychologist/dashboard/presentation/pages/psych_dashboard_page.dart';
import '../../features/psychologist/profile/presentation/pages/psych_profile_page.dart';
import '../../features/psychologist/sessions/presentation/pages/psych_sessions_page.dart';
import '../../features/psychologist/slots/presentation/pages/psych_slots_page.dart';
import '../../features/admin/appointments/presentation/pages/admin_appointments_page.dart';
import '../../features/admin/dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/psychologists/presentation/pages/admin_psych_management_page.dart';
import '../../features/admin/settings/presentation/pages/admin_settings_page.dart';
import '../../features/admin/users/presentation/pages/admin_user_management_page.dart';
import '../../core/entities/entities.dart';
import 'route_names.dart';

final appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  redirect: (context, state) async {
    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;
    final location = state.matchedLocation;

    final publicRoutes = [
      RouteNames.splash,
      RouteNames.onboarding,
      RouteNames.login,
      RouteNames.register,
      RouteNames.forgotPassword,
    ];

    final isPublic = publicRoutes.contains(location);

    if (authState is AuthAuthenticated) {
      if (isPublic) {
        switch (authState.user.role) {
          case UserRole.user:
            return RouteNames.userHome;
          case UserRole.psychologist:
            return RouteNames.psychDashboard;
          case UserRole.admin:
            return RouteNames.adminDashboard;
        }
      }
    } else if (authState is AuthUnauthenticated) {
      if (!isPublic) return RouteNames.login;
    }
    return null;
  },
  routes: [
    // ─── Auth ─────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.splash,
      builder: (_, __) => const SplashPage(),
    ),
    GoRoute(
      path: RouteNames.onboarding,
      builder: (_, __) => const OnboardingPage(),
    ),
    GoRoute(
      path: RouteNames.login,
      builder: (_, __) => const LoginPage(),
    ),
    GoRoute(
      path: RouteNames.register,
      builder: (_, __) => const RegisterPage(),
    ),
    GoRoute(
      path: RouteNames.forgotPassword,
      builder: (_, __) => const ForgotPasswordPage(),
    ),

    // ─── User Shell ────────────────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          UserShell(navigationShell: navigationShell),
      branches: [
        // 0 — Home
        StatefulShellBranch(routes: [
          GoRoute(
            path: RouteNames.userHome,
            builder: (_, __) => BlocProvider(
              create: (_) => PsychologistListBloc(),
              child: const UserHomePage(),
            ),
          ),
        ]),
        // 1 — Consult
        StatefulShellBranch(routes: [
          GoRoute(
            path: RouteNames.userConsult,
            builder: (_, __) => BlocProvider(
              create: (_) => PsychologistListBloc(),
              child: const ConsultPage(),
            ),
          ),
        ]),
        // 2 — Sessions
        StatefulShellBranch(routes: [
          GoRoute(
            path: RouteNames.userAppointments,
            builder: (_, __) => const AppointmentsPage(),
          ),
        ]),
        // 3 — Wallet
        StatefulShellBranch(routes: [
          GoRoute(
            path: RouteNames.userWallet,
            builder: (_, __) => const UserWalletPage(),
          ),
        ]),
        // 4 — Profile
        StatefulShellBranch(routes: [
          GoRoute(
            path: RouteNames.userProfile,
            builder: (_, __) => const UserProfilePage(),
          ),
        ]),
      ],
    ),

    // ─── Psychologist Shell ────────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          PsychShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: RouteNames.psychDashboard,
            builder: (_, __) => const PsychDashboardPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: RouteNames.psychSlots,
            builder: (_, __) => const PsychSlotsPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: RouteNames.psychSessions,
            builder: (_, __) => const PsychSessionsPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: RouteNames.psychBlogs,
            builder: (_, __) => const PsychBlogPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: RouteNames.psychProfile,
            builder: (_, __) => const PsychProfilePage(),
          ),
        ]),
      ],
    ),

    // ─── Admin Shell ───────────────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AdminShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: RouteNames.adminDashboard,
            builder: (_, __) => const AdminDashboardPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: RouteNames.adminPsychologists,
            builder: (_, __) => const AdminPsychManagementPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: RouteNames.adminUsers,
            builder: (_, __) => const AdminUserManagementPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: RouteNames.adminAppointments,
            builder: (_, __) => const AdminAppointmentsPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: RouteNames.adminSettings,
            builder: (_, __) => const AdminSettingsPage(),
          ),
        ]),
      ],
    ),

    // ─── Outside-shell routes ──────────────────────────────────────────────
    GoRoute(
      path: RouteNames.userBroadcast,
      builder: (_, __) => const BroadcastCallPage(),
    ),
    GoRoute(
      path: RouteNames.userNotifications,
      builder: (_, __) => const NotificationsPage(),
    ),
    GoRoute(
      path: RouteNames.userBlogList,
      builder: (_, __) => const BlogListPage(),
    ),
    GoRoute(
      path: RouteNames.userBlogDetail,
      builder: (_, state) => BlogDetailPage(blog: state.extra as BlogEntity),
    ),
    GoRoute(
      path: RouteNames.psychBlogDetail,
      builder: (_, state) => PsychBlogDetailPage(blog: state.extra as BlogEntity),
    ),
    GoRoute(
      path: RouteNames.psychologistDetail,
      builder: (_, state) => PsychologistDetailPage(
          psychologist: state.extra as PsychologistEntity),
    ),
    GoRoute(
      path: RouteNames.slotBooking,
      builder: (_, state) => SlotBookingPage(
          psychologist: state.extra as PsychologistEntity),
    ),
    GoRoute(
      path: RouteNames.payment,
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return PaymentPage(
          psychologist: extra['psychologist'] as PsychologistEntity,
          slot: extra['slot'] as SlotEntity,
          sessionType: extra['sessionType'] as String,
        );
      },
    ),
    GoRoute(
      path: RouteNames.bookingConfirmed,
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return BookingConfirmedPage(
          psychologist: extra['psychologist'] as PsychologistEntity,
          slot: extra['slot'] as SlotEntity,
          sessionType: extra['sessionType'] as String,
        );
      },
    ),
    GoRoute(
      path: RouteNames.preCall,
      builder: (_, state) => BlocProvider(
        create: (_) => CallBloc(),
        child:
            PreCallScreen(psychologist: state.extra as PsychologistEntity),
      ),
    ),
    GoRoute(
      path: RouteNames.activeCall,
      builder: (_, state) =>
          ActiveCallScreen(psychologist: state.extra as PsychologistEntity),
    ),
    GoRoute(
      path: RouteNames.callSummary,
      builder: (_, state) =>
          PostCallSummaryScreen(callEnded: state.extra as CallEnded),
    ),
  ],
);

// ─── Shell Scaffolds ──────────────────────────────────────────────────────────

class UserShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const UserShell({super.key, required this.navigationShell});

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _TabItem(icon: Icons.headphones_outlined, activeIcon: Icons.headphones_rounded, label: 'Consult'),
    _TabItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Sessions'),
    _TabItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: 'Wallet'),
    _TabItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(RouteNames.login);
        }
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: _UserBottomNav(
          currentIndex: navigationShell.currentIndex,
          onTap: navigationShell.goBranch,
          tabs: _tabs,
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem({required this.icon, required this.activeIcon, required this.label});
}

class _UserBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final List<_TabItem> tabs;

  const _UserBottomNav({required this.currentIndex, required this.onTap, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE5E5EA), width: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF5E5CE6).withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          active ? tab.activeIcon : tab.icon,
                          size: 22,
                          color: active ? const Color(0xFF5E5CE6) : const Color(0xFF8E8E93),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            color: active ? const Color(0xFF5E5CE6) : const Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class PsychShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const PsychShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(RouteNames.login);
        }
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.calendar_view_week_outlined),
              selectedIcon: Icon(Icons.calendar_view_week_rounded),
              label: 'Slots'),
          NavigationDestination(
              icon: Icon(Icons.video_call_outlined),
              selectedIcon: Icon(Icons.video_call_rounded),
              label: 'Sessions'),
          NavigationDestination(
              icon: Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article_rounded),
              label: 'Blogs'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
      ),
    );
  }
}

class AdminShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AdminShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(RouteNames.login);
        }
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.speed_outlined),
              selectedIcon: Icon(Icons.speed_rounded),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.psychology_outlined),
              selectedIcon: Icon(Icons.psychology_rounded),
              label: 'Psychologists'),
          NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Users'),
          NavigationDestination(
              icon: Icon(Icons.event_outlined),
              selectedIcon: Icon(Icons.event_rounded),
              label: 'Appointments'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings'),
        ],
      ),
      ),
    );
  }
}
