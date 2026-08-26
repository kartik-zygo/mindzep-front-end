import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_error_model.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/google_auth_service.dart';
import '../../domain/entities/user_entity.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const Duration _sessionRefreshInterval = Duration(minutes: 10);

  final AuthRepository _authRepository;
  final GoogleAuthService _googleAuthService;

  UserEntity? _currentUser;
  Timer? _sessionRefreshTimer;
  bool _isSessionRefreshInProgress = false;

  UserEntity? get currentUser => _currentUser;

  AuthBloc({
    required AuthRepository authRepository,
    required GoogleAuthService googleAuthService,
  })  : _authRepository = authRepository,
        _googleAuthService = googleAuthService,
        super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<GoogleSignInRequested>(_onGoogleSignIn);
    on<LogoutRequested>(_onLogout);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<OtpVerified>(_onOtpVerified);
    on<ResendOtpRequested>(_onResendOtp);
    on<PasswordResetRequested>(_onPasswordReset);
    on<ChangePasswordRequested>(_onChangePassword);
    on<UpdateFcmTokenRequested>(_onUpdateFcmToken);
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
      await _sendFcmToken();
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
      await _sendFcmToken();
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

  Future<void> _onGoogleSignIn(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    final String? idToken;
    try {
      idToken = await _googleAuthService.getIdToken();
    } on GoogleSignInConfigError catch (error) {
      emit(AuthError(error.userMessage));
      return;
    } catch (error) {
      emit(AuthError(_toErrorMessage(error)));
      return;
    }

    // null idToken means the user dismissed the account picker — silently
    // return without disturbing the current state.
    if (idToken == null) return;

    emit(const AuthLoading());

    try {
      final session = await _authRepository.googleLogin(
        GoogleLoginRequest(idToken: idToken),
      );

      final user =
          session.user?.toEntity() ?? await _authRepository.getCurrentUser();
      await _authRepository.syncUserRole(user.role);
      _currentUser = user;
      _startSessionRefresh();
      emit(AuthAuthenticated(user, isNewGoogleUser: session.isNewUser));
      await _sendFcmToken();
    } on ApiErrorModel catch (error) {
      if (error.statusCode == 401) {
        emit(const AuthError('Google sign-in failed, try again.'));
      } else {
        // 403 (account suspended) and others — surface the server message.
        emit(AuthError(error.message));
      }
    } catch (error) {
      emit(AuthError(_toErrorMessage(error)));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    _stopSessionRefresh();
    await _authRepository.logout();
    // Clear the Google session too so the account picker shows next time.
    await _googleAuthService.signOut();
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
        await _sendFcmToken();
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

  Future<void> _onUpdateFcmToken(
    UpdateFcmTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.updateFcmToken(
        UpdateFcmTokenRequest(fcmToken: event.fcmToken),
      );
    } catch (_) {
      // FCM sync failure should not block app navigation.
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

  Future<void> _sendFcmToken() async {
    try {
      final token = FirebaseService.instance.fcmToken;
      if (token == null || token.isEmpty) return;
      await _authRepository.updateFcmToken(
        UpdateFcmTokenRequest(fcmToken: token),
      );
    } catch (_) {
      // FCM sync failure should not block the user.
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
