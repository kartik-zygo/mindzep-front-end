import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

import 'injection/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const MindZepApp());
}

class MindZepApp extends StatelessWidget {
  const MindZepApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: 'MindZep',
        theme: AppTheme.light,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
