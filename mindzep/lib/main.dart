import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';

import 'injection/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.initialize();
  await initDependencies();

  final authBloc = sl<AuthBloc>()..add(const AppStarted());
  final router = createAppRouter(authBloc);

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
