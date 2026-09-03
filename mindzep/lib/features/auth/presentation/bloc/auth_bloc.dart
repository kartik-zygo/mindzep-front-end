import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_error_model.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const Duration _sessionRefreshInterval = Duration(minutes: 10);

  final AuthRepository _authRepository;

  UserEntity? _currentUser;
  Timer? _sessionRefreshTimer;
  bool _isSessionRefreshInProgress = false;

  UserEntity? get currentUser => _currentUser;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<OtpVerified>(_onOtpVerified);
    on<ResendOtpRequested>(_onResendOtp);
    on<PasswordResetRequested>(_onPasswordReset);
    on<ChangePasswordRequested>(_onChangePassword);
    on<SessionRefreshRequested>(_onSessionRefreshRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final hasSession = await _authRepository.hasSession();
    if (!hasSession) {
      _stopSessionRefresh();
      emit(const AuthUnauthenticated());
      return;
    }

    try {
      final user = await _authRepository.getCurrentUser();
      await _authRepository.syncUserRole(user.role);
      _currentUser = user;
      _startSessionRefresh();
      emit(AuthAuthenticated(user));
    } catch (_) {
      _stopSessionRefresh();
      await _authRepository.clearSession();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      final session = await _authRepository.login(
        LoginRequest(email: event.email.trim(), password: event.password),
      );

      final user =
          session.user?.toEntity() ?? await _authRepository.getCurrentUser();
      await _authRepository.syncUserRole(user.role);
      _currentUser = user;
      _startSessionRefresh();
      emit(AuthAuthenticated(user));
    } catch (error) {
      emit(AuthError(_toErrorMessage(error)));
    }
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.register(
        RegisterRequest(
          name: event.name.trim(),
          email: event.email.trim(),
          phone: event.phone.trim(),
          password: event.password,
          confirmPassword: event.password,
          role: event.role,
        ),
      );

      emit(
        AuthOtpSent(identifier: event.email.trim(), purpose: 'registration'),
      );
    } catch (error) {
      emit(AuthError(_toErrorMessage(error)));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    _stopSessionRefresh();
    await _authRepository.logout();
    _currentUser = null;
    emit(const AuthUnauthenticated());
  }

  Future<void> _onForgotPassword(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.forgotPassword(
        ForgotPasswordRequest(email: event.email.trim()),
      );
      emit(
        AuthOtpSent(identifier: event.email.trim(), purpose: 'password_reset'),
      );
    } catch (error) {
      emit(AuthError(_toErrorMessage(error)));
    }
  }

  Future<void> _onOtpVerified(
    OtpVerified event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final session = await _authRepository.verifyOtp(
        VerifyOtpRequest(
          identifier: event.identifier.trim(),
          otp: event.otp.trim(),
          purpose: event.purpose.trim(),
        ),
      );

      if (event.purpose == 'registration') {
        final user =
            session.user?.toEntity() ?? await _authRepository.getCurrentUser();
        await _authRepository.syncUserRole(user.role);
        _currentUser = user;
        _startSessionRefresh();
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthOtpVerified());
      }
    } catch (error) {
      emit(AuthError(_toErrorMessage(error)));
    }
  }

  Future<void> _onResendOtp(
    ResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.resendOtp(
        ResendOtpRequest(
          identifier: event.identifier.trim(),
          purpose: event.purpose.trim(),
        ),
      );
      emit(AuthOperationSuccess('OTP sent successfully.'));
      emit(
        AuthOtpSent(
          identifier: event.identifier.trim(),
          purpose: event.purpose.trim(),
        ),
      );
    } catch (error) {
      emit(AuthError(_toErrorMessage(error)));
    }
  }

  Future<void> _onPasswordReset(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.resetPassword(
        ResetPasswordRequest(
          identifier: event.identifier.trim(),
          otp: event.otp.trim(),
          newPassword: event.newPassword,
          confirmPassword: event.confirmPassword,
        ),
      );
      emit(const AuthPasswordResetSuccess());
    } catch (error) {
      emit(AuthError(_toErrorMessage(error)));
    }
  }

  Future<void> _onChangePassword(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.changePassword(
        ChangePasswordRequest(
          currentPassword: event.currentPassword,
          newPassword: event.newPassword,
          confirmPassword: event.confirmPassword,
        ),
      );
      emit(const AuthOperationSuccess('Password updated successfully.'));
    } catch (error) {
      emit(AuthError(_toErrorMessage(error)));
    }
  }

  Future<void> _onSessionRefreshRequested(
    SessionRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (_isSessionRefreshInProgress) return;

    final hasSession = await _authRepository.hasSession();
    if (!hasSession) {
      _stopSessionRefresh();
      return;
    }

    _isSessionRefreshInProgress = true;
    try {
      await _authRepository.refresh();
    } on ApiErrorModel catch (error) {
      final isTokenInvalid = error.statusCode == 401 || error.statusCode == 403;
      if (isTokenInvalid) {
        _stopSessionRefresh();
        await _authRepository.clearSession();
        _currentUser = null;
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      // Keep the session as-is on transient network failures.
      // Existing interceptor-based refresh and retries will still protect requests.
    } finally {
      _isSessionRefreshInProgress = false;
    }
  }

  void _startSessionRefresh() {
    _sessionRefreshTimer?.cancel();
    _sessionRefreshTimer = Timer.periodic(_sessionRefreshInterval, (_) {
      add(const SessionRefreshRequested());
    });
  }

  void _stopSessionRefresh() {
    _sessionRefreshTimer?.cancel();
    _sessionRefreshTimer = null;
  }

  String _toErrorMessage(Object error) {
    if (error is ApiErrorModel) {
      return error.message;
    }
    return error.toString();
  }

  @override
  Future<void> close() {
    _stopSessionRefresh();
    return super.close();
  }
}
