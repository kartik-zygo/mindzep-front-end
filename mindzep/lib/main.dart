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

import 'injection/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();
  await initDependencies();
  await FirebaseService.instance.initialize();

  final authBloc = sl<AuthBloc>()..add(const AppStarted());
  final router = createAppRouter(authBloc);

  // Sync FCM token whenever it rotates
  FirebaseService.instance.onTokenRefresh.listen((token) {
    authBloc.add(UpdateFcmTokenRequested(fcmToken: token));
  });

  // Navigate based on notification tap
  FirebaseService.instance.onNotificationTap.listen((data) {
    _handleNotificationTap(router, data);
  });

  runApp(MindZepApp(authBloc: authBloc, router: router));
}

class MindZepApp extends StatelessWidget {
  const MindZepApp({
    super.key,
    required this.authBloc,
    required this.router,
  });

  final AuthBloc authBloc;
  final RouterConfig<Object> router;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => authBloc,
        ),
      ],
      child: MaterialApp.router(
        title: 'MindZep',
        theme: AppTheme.light,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Navigate to the relevant screen when the user taps a push notification.
void _handleNotificationTap(GoRouter router, Map<String, dynamic> data) {
  final type = (data['type'] as String? ?? '').toLowerCase();
  switch (type) {
    case 'appointment':
      router.go(RouteNames.userAppointments);
    case 'payment':
      router.go(RouteNames.userWallet);
    case 'blog':
      router.go(RouteNames.psychBlogs);
    default:
      router.go(RouteNames.userNotifications);
  }
}
