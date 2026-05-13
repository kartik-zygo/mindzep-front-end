import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/mock/mock_data.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  UserEntity? _currentUser;

  UserEntity? get currentUser => _currentUser;

  AuthBloc() : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<GoogleSignInRequested>(_onGoogleSignIn);
    on<LogoutRequested>(_onLogout);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<OtpVerified>(_onOtpVerified);
    on<PasswordResetRequested>(_onPasswordReset);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 2500));
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString('user_role');
    if (savedRole != null) {
      final user = _getUserForRole(savedRole);
      if (user != null) {
        _currentUser = user;
        emit(AuthAuthenticated(user));
        return;
      }
    }
    emit(const AuthUnauthenticated());
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 1200));

    final credentials = {
      'user@mindzep.com': MockData.currentUser,
      'psych@mindzep.com': MockData.currentPsychologist,
      'admin@mindzep.com': MockData.currentAdmin,
    };

    final validPasswords = {
      'user@mindzep.com': 'user123',
      'psych@mindzep.com': 'psych123',
      'admin@mindzep.com': 'admin123',
    };

    final user = credentials[event.email.toLowerCase().trim()];
    final validPwd = validPasswords[event.email.toLowerCase().trim()];

    if (user == null || validPwd != event.password) {
      emit(const AuthError('Invalid email or password. Try user@mindzep.com / user123'));
      return;
    }

    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', user.role.name);
    emit(AuthAuthenticated(user));
  }

  Future<void> _onRegister(
      RegisterRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 1200));
    final role = event.role == 'psychologist' ? UserRole.psychologist : UserRole.user;
    final newUser = UserEntity(
      id: 'u_new',
      name: event.name,
      email: event.email,
      phone: event.phone,
      role: role,
      isVerified: true,
      isActive: true,
      createdAt: DateTime.now(),
    );
    _currentUser = newUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', newUser.role.name);
    emit(AuthAuthenticated(newUser));
  }

  Future<void> _onGoogleSignIn(
      GoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 1000));
    _currentUser = MockData.currentUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', UserRole.user.name);
    emit(AuthAuthenticated(MockData.currentUser));
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    emit(const AuthUnauthenticated());
  }

  Future<void> _onForgotPassword(
      ForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 1000));
    emit(AuthOtpSent(event.email));
  }

  Future<void> _onOtpVerified(
      OtpVerified event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 800));
    emit(const AuthOtpVerified());
  }

  Future<void> _onPasswordReset(
      PasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 800));
    emit(const AuthPasswordResetSuccess());
  }

  UserEntity? _getUserForRole(String roleName) {
    return switch (roleName) {
      'user' => MockData.currentUser,
      'psychologist' => MockData.currentPsychologist,
      'admin' => MockData.currentAdmin,
      _ => null,
    };
  }
}
