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
