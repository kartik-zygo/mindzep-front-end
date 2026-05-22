import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/verify_otp_page.dart';
import '../../features/user/home/presentation/bloc/psychologist_list_bloc.dart';
import '../../features/user/home/presentation/pages/psychologist_detail_page.dart';
import '../../features/user/home/presentation/pages/user_home_page.dart';
import '../../features/user/appointments/presentation/pages/appointments_page.dart';
import '../../features/user/booking/presentation/pages/booking_confirmed_page.dart';
import '../../features/user/booking/presentation/pages/payment_page.dart';
import '../../features/user/booking/presentation/pages/slot_booking_page.dart';
import '../../features/user/call/presentation/bloc/call_bloc.dart';
import '../../features/user/call/presentation/models/call_route_payload.dart';
import '../../features/user/call/presentation/pages/active_call_screen.dart';
import '../../features/user/call/presentation/pages/post_call_summary_screen.dart';
import '../../features/user/call/presentation/pages/pre_call_screen.dart';
import '../../features/user/profile/presentation/pages/user_profile_page.dart';
import '../../features/user/consult/presentation/pages/consult_page.dart';
import '../../features/user/wallet/presentation/pages/user_wallet_page.dart';
import '../../features/user/broadcast/presentation/bloc/broadcast_bloc.dart';
import '../../features/user/broadcast/presentation/pages/broadcast_call_page.dart';
import '../../features/user/blog/presentation/pages/blog_list_page.dart';
import '../../features/user/blog/presentation/pages/blog_detail_page.dart';
import '../../features/user/notifications/presentation/pages/notifications_page.dart';
import '../../features/psychologist/blog/presentation/pages/psych_blog_page.dart';
import '../../features/psychologist/blog/presentation/pages/psych_blog_detail_page.dart';
import '../../features/psychologist/call/data/models/incoming_call_data.dart';
import '../../features/psychologist/call/data/repositories/psych_call_repository.dart';
import '../../features/psychologist/call/data/socket/psych_call_socket_service.dart';
import '../../features/psychologist/call/presentation/bloc/psych_call_bloc.dart';
import '../../features/psychologist/call/presentation/pages/psych_incoming_call_screen.dart';
import '../../features/psychologist/call/presentation/pages/psych_active_call_screen.dart';
import '../../features/psychologist/dashboard/presentation/pages/psych_dashboard_page.dart';
import '../../features/psychologist/profile/presentation/pages/psych_profile_page.dart';
import '../../features/psychologist/sessions/presentation/pages/psych_sessions_page.dart';
import '../../features/psychologist/slots/presentation/pages/psych_slots_page.dart';
import '../../features/admin/appointments/presentation/pages/admin_appointments_page.dart';
import '../../features/admin/blogs/presentation/pages/admin_blog_management_page.dart';
import '../../features/admin/dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/psychologists/presentation/pages/admin_psych_management_page.dart';
import '../../features/admin/settings/presentation/pages/admin_settings_page.dart';
import '../../features/admin/users/presentation/pages/admin_user_management_page.dart';
import '../../core/entities/entities.dart';
import '../../injection/injection_container.dart';
import 'route_names.dart';

GoRouter createAppRouter(AuthBloc authBloc) => GoRouter(
  initialLocation: RouteNames.splash,
  refreshListenable: _GoRouterAuthRefreshStream(authBloc.stream),
  redirect: (context, state) async {
    final authState = authBloc.state;
    final location = state.matchedLocation;

    final publicRoutes = [
      RouteNames.splash,
      RouteNames.onboarding,
      RouteNames.login,
      RouteNames.register,
      RouteNames.verifyOtp,
      RouteNames.forgotPassword,
    ];

    final isPublic = publicRoutes.contains(location);

    if (authState is AuthAuthenticated) {
      final roleHome = _homeForRole(authState.user.role);

      if (isPublic) {
        return roleHome;
      }

      if (_isRoleMismatch(authState.user.role, location)) {
        return roleHome;
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
      path: RouteNames.verifyOtp,
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return VerifyOtpPage(
          identifier: (extra['identifier'] ?? '').toString(),
          purpose: (extra['purpose'] ?? 'registration').toString(),
        );
      },
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
              create: (_) => sl<PsychologistListBloc>(),
              child: const UserHomePage(),
            ),
          ),
        ]),
        // 1 — Consult
        StatefulShellBranch(routes: [
          GoRoute(
            path: RouteNames.userConsult,
            builder: (_, __) => BlocProvider(
              create: (_) => sl<PsychologistListBloc>(),
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
            path: RouteNames.adminBlogs,
            builder: (_, __) => const AdminBlogManagementPage(),
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
      builder: (_, __) => BlocProvider(
        create: (_) => sl<BroadcastCallBloc>(),
        child: const BroadcastCallPage(),
      ),
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
      path: RouteNames.psychIncomingCall,
      builder: (_, state) => PsychIncomingCallScreen(
        callData: state.extra as IncomingCallData,
      ),
    ),
    GoRoute(
      path: RouteNames.psychActiveCall,
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return BlocProvider(
          create: (_) => sl<PsychCallBloc>(),
          child: PsychActiveCallScreen(
            callData: extra['callData'] as IncomingCallData,
            enableVideo: extra['enableVideo'] as bool? ?? true,
          ),
        );
      },
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
      builder: (_, state) {
        final extra = state.extra;
        late final CallRoutePayload payload;

        if (extra is CallRoutePayload) {
          payload = extra;
        } else if (extra is PsychologistEntity) {
          payload = CallRoutePayload.fromPsychologist(extra);
        } else if (extra is AppointmentEntity) {
          payload = CallRoutePayload.fromAppointment(extra);
        } else if (extra is Map<String, dynamic>) {
          final appointmentId = (extra['appointmentId'] ?? '').toString();
          final preferredSessionType =
              extra['sessionType'] is SessionType
                  ? extra['sessionType'] as SessionType
                  : SessionType.video;

          final psychologist = extra['psychologist'];
          final appointment = extra['appointment'];
          if (appointment is AppointmentEntity) {
            payload = CallRoutePayload.fromAppointment(appointment);
          } else if (psychologist is PsychologistEntity) {
            payload = CallRoutePayload.fromPsychologist(
              psychologist,
              appointmentId: appointmentId,
              preferredSessionType: preferredSessionType,
            );
          } else {
            throw ArgumentError('Invalid extra for pre-call route.');
          }
        } else {
          throw ArgumentError('Invalid extra for pre-call route.');
        }

        return BlocProvider(
          create: (_) => sl<CallBloc>(),
          child: PreCallScreen(payload: payload),
        );
      },
    ),
    GoRoute(
      path: RouteNames.activeCall,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is! Map<String, dynamic>) {
          throw ArgumentError('Missing call route data for active call.');
        }

        final payload = extra['payload'];
        final callBloc = extra['callBloc'];
        if (payload is! CallRoutePayload || callBloc is! CallBloc) {
          throw ArgumentError('Invalid call route data for active call.');
        }

        return BlocProvider.value(
          value: callBloc,
          child: ActiveCallScreen(payload: payload),
        );
      },
    ),
    GoRoute(
      path: RouteNames.callSummary,
      builder: (_, state) =>
          PostCallSummaryScreen(callEnded: state.extra as CallEnded),
    ),
  ],
);

String _homeForRole(UserRole role) {
  switch (role) {
    case UserRole.user:
      return RouteNames.userHome;
    case UserRole.psychologist:
      return RouteNames.psychDashboard;
    case UserRole.admin:
      return RouteNames.adminDashboard;
  }
}

bool _isRoleMismatch(UserRole role, String location) {
  final onUserPath = location.startsWith('/user/');
  final onPsychPath = location.startsWith('/psych/');
  final onAdminPath = location.startsWith('/admin/');

  switch (role) {
    case UserRole.user:
      return onPsychPath || onAdminPath;
    case UserRole.psychologist:
      return onUserPath || onAdminPath;
    case UserRole.admin:
      return onUserPath || onPsychPath;
  }
}

class _GoRouterAuthRefreshStream extends ChangeNotifier {
  _GoRouterAuthRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

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

class PsychShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const PsychShell({super.key, required this.navigationShell});

  @override
  State<PsychShell> createState() => _PsychShellState();
}

class _PsychShellState extends State<PsychShell> {
  StreamSubscription<IncomingCallData>? _callSub;
  Timer? _pollTimer;

  /// Tracks the call ID (or appointment ID as fallback) of the call we have
  /// already pushed to the incoming-call screen.  Prevents duplicate pushes
  /// when both the socket event and the polling response carry the same call.
  String? _activeCallKey;

  @override
  void initState() {
    super.initState();
    _initCallSocket();
  }

  Future<void> _initCallSocket() async {
    try {
      final service = sl<PsychCallSocketService>();
      await service.connect();
      _callSub = service.onIncomingCall.listen(_onIncomingCall);
      // Socket is live — start the HTTP-polling fallback.
      _startPolling();
    } catch (e) {
      debugPrint('[PsychShell] Failed to connect call socket: $e');
      // Retry after 5 seconds — handles transient startup network issues.
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) _initCallSocket();
    }
  }

  // ── HTTP polling ───────────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    // Check immediately, then every 8 s.
    _checkPendingCall();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _checkPendingCall(),
    );
  }

  Future<void> _checkPendingCall() async {
    if (!mounted) return;
    try {
      final incoming = await sl<PsychCallRepository>().fetchPendingCall();
      if (!mounted) return;
      if (incoming == null) {
        // Nothing pending — reset so a future call can be shown.
        _activeCallKey = null;
        return;
      }
      _onIncomingCall(incoming);
    } catch (_) {
      // Polling errors are non-critical; silently ignore.
    }
  }

  // ── Incoming call handler (shared by socket + polling) ────────────────────

  void _onIncomingCall(IncomingCallData data) {
    if (!mounted) return;
    // Deduplicate: use callId if present, otherwise appointmentId.
    final key = data.callId.isNotEmpty ? data.callId : data.appointmentId;
    if (key.isNotEmpty && key == _activeCallKey) return;
    _activeCallKey = key.isNotEmpty ? key : null;
    context.push(RouteNames.psychIncomingCall, extra: data);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _callSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(RouteNames.login);
        }
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: widget.navigationShell.goBranch,
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
              icon: Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article_rounded),
              label: 'Blogs'),
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
