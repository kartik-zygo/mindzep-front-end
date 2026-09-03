import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/dio_client.dart';
import '../core/network/token_storage.dart';
import '../core/socket/socket_manager.dart';
import '../features/admin/data/repositories/admin_repository.dart';
import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/common/uploads/data/repositories/upload_repository.dart';
import '../features/psychologist/data/repositories/psychologist_repository.dart';
import '../features/user/appointments/data/repositories/appointment_repository.dart';
import '../features/user/blog/data/repositories/blog_repository.dart';
import '../features/user/call/data/agora/agora_call_engine.dart';
import '../features/user/call/data/repositories/call_repository.dart';
import '../features/psychologist/call/data/socket/psych_call_socket_service.dart';
import '../features/psychologist/call/data/repositories/psych_call_repository.dart';
import '../features/psychologist/call/presentation/bloc/psych_call_bloc.dart';
import '../features/user/broadcast/presentation/bloc/broadcast_bloc.dart';
import '../features/user/call/data/socket/call_socket_manager.dart';
import '../features/user/call/presentation/bloc/call_bloc.dart';
import '../features/user/chat/data/repositories/chat_repository.dart';
import '../features/user/chat/data/socket/chat_socket_manager.dart';
import '../features/user/home/presentation/bloc/psychologist_list_bloc.dart';
import '../features/user/notifications/data/repositories/notification_repository.dart';
import '../features/user/notifications/data/socket/notifications_socket_manager.dart';
import '../features/user/payments/data/repositories/payment_repository.dart';
import '../features/user/public/data/repositories/public_repository.dart';
import '../features/user/data/repositories/user_repository.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  if (sl.isRegistered<SharedPreferences>()) {
    return;
  }

  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerLazySingleton<TokenStorage>(() => TokenStorage());
  sl.registerLazySingleton<SocketManager>(
    () => SocketManager(tokenStorage: sl<TokenStorage>()),
  );

  // Core network
  sl.registerLazySingleton<DioClient>(
    () => DioClient(tokenStorage: sl<TokenStorage>()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      dioClient: sl<DioClient>(),
      tokenStorage: sl<TokenStorage>(),
    ),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<PsychologistRepository>(
    () => PsychologistRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<AppointmentRepository>(
    () => AppointmentRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<CallRepository>(
    () => CallRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<UploadRepository>(
    () => UploadRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<BlogRepository>(
    () => BlogRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepository(dioClient: sl<DioClient>()),
  );
  sl.registerLazySingleton<PublicRepository>(
    () => PublicRepository(dioClient: sl<DioClient>()),
  );

  // Integration services
  sl.registerFactory<AgoraCallEngine>(() => AgoraCallEngine());

  // Socket managers
  sl.registerLazySingleton<ChatSocketManager>(
    () => ChatSocketManager(socketManager: sl<SocketManager>()),
  );
  sl.registerLazySingleton<CallSocketManager>(
    () => CallSocketManager(socketManager: sl<SocketManager>()),
  );
  sl.registerLazySingleton<NotificationsSocketManager>(
    () => NotificationsSocketManager(socketManager: sl<SocketManager>()),
  );
  sl.registerLazySingleton<PsychCallSocketService>(
    () => PsychCallSocketService(socketManager: sl<SocketManager>()),
  );
  sl.registerLazySingleton<PsychCallRepository>(
    () => PsychCallRepository(dioClient: sl<DioClient>()),
  );

  // BLoCs — registered as factories so each context gets a fresh instance
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<PsychologistListBloc>(
    () => PsychologistListBloc(repository: sl<PsychologistRepository>()),
  );
  sl.registerFactory<CallBloc>(
    () => CallBloc(
      callRepository: sl<CallRepository>(),
      agoraCallEngine: sl<AgoraCallEngine>(),
      callSocketManager: sl<CallSocketManager>(),
    ),
  );
  sl.registerFactory<BroadcastCallBloc>(
    () => BroadcastCallBloc(
      callRepository: sl<CallRepository>(),
      callSocketManager: sl<CallSocketManager>(),
    ),
  );
  sl.registerFactory<PsychCallBloc>(
    () => PsychCallBloc(
      callRepository: sl<CallRepository>(),
      agoraCallEngine: sl<AgoraCallEngine>(),
      socketService: sl<PsychCallSocketService>(),
    ),
  );
}
