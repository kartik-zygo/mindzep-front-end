import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/user/home/presentation/bloc/psychologist_list_bloc.dart';
import '../features/user/call/presentation/bloc/call_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // BLoCs — registered as factories so each context gets a fresh instance
  sl.registerFactory<AuthBloc>(() => AuthBloc());
  sl.registerFactory<PsychologistListBloc>(() => PsychologistListBloc());
  sl.registerFactory<CallBloc>(() => CallBloc());
}
