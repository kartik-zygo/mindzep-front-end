import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/domain/entities/user_entity.dart';

import 'injection/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();
  await initDependencies();

  // Push notifications must never take the whole app down. On iOS this throws
  // when ios/Runner/GoogleService-Info.plist is missing from the Xcode target,
  // which would otherwise be a black screen on launch with no explanation.
  try {
    await FirebaseService.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint(
      '[Firebase] initialization failed — push notifications are disabled for '
      'this session. On iOS, confirm GoogleService-Info.plist is added to the '
      'Runner target in Xcode. Error: $error',
    );
    debugPrintStack(stackTrace: stackTrace);
  }

  final authBloc = sl<AuthBloc>()..add(const AppStarted());
  final router = createAppRouter(authBloc);

  // Sync FCM token whenever it rotates
  FirebaseService.instance.onTokenRefresh.listen((token) {
    authBloc.add(UpdateFcmTokenRequested(fcmToken: token));
  });

  // Navigate based on notification tap
  FirebaseService.instance.onNotificationTap.listen((data) {
    _handleNotificationTap(router, authBloc, data);
  });

  runApp(MindZepApp(authBloc: authBloc, router: router));
}

class MindZepApp extends StatefulWidget {
  const MindZepApp({super.key, required this.authBloc, required this.router});

  final AuthBloc authBloc;
  final RouterConfig<Object> router;

  @override
  State<MindZepApp> createState() => _MindZepAppState();
}

class _MindZepAppState extends State<MindZepApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.authBloc.add(const SessionRefreshRequested());
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<AuthBloc>(create: (_) => widget.authBloc)],
      child: MaterialApp.router(
        title: 'MindZep',
        theme: AppTheme.light,
        routerConfig: widget.router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          // Respect the user's device font-size preference, but clamp the
          // upper bound so very large accessibility scales can't overflow
          // fixed-height containers, rows and buttons across the app.
          final mq = MediaQuery.of(context);
          final clampedScaler = mq.textScaler.clamp(
            minScaleFactor: 1.0,
            maxScaleFactor: 1.3,
          );
          return MediaQuery(
            data: mq.copyWith(textScaler: clampedScaler),
            child: child!,
          );
        },
      ),
    );
  }
}

/// Navigate to the relevant screen when the user taps a push notification.
void _handleNotificationTap(
  GoRouter router,
  AuthBloc authBloc,
  Map<String, dynamic> data,
) {
  final type = (data['type'] as String? ?? '').toLowerCase();
  final authState = authBloc.state;
  final role = authState is AuthAuthenticated ? authState.user.role : null;

  final notificationsRoute = switch (role) {
    UserRole.admin => RouteNames.adminNotifications,
    UserRole.psychologist => RouteNames.psychNotifications,
    _ => RouteNames.userNotifications,
  };

  switch (type) {
    case 'appointment':
      final route = switch (role) {
        UserRole.admin => RouteNames.adminAppointments,
        UserRole.psychologist => RouteNames.psychSessions,
        _ => RouteNames.userAppointments,
      };
      router.go(route);
      return;
    case 'payment':
      final route = switch (role) {
        UserRole.user => RouteNames.userWallet,
        _ => notificationsRoute,
      };
      router.go(route);
      return;
    case 'blog':
      final route = switch (role) {
        UserRole.admin => RouteNames.adminBlogs,
        UserRole.psychologist => RouteNames.psychBlogs,
        _ => RouteNames.userBlogList,
      };
      router.go(route);
      return;
    default:
      router.go(notificationsRoute);
      return;
  }
}
