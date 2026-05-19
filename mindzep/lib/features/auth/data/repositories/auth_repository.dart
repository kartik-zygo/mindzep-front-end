import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/utils/json_readers.dart';
import '../../domain/entities/user_entity.dart';
import '../models/auth_models.dart';

class AuthRepository {
  AuthRepository({
    required DioClient dioClient,
    required TokenStorage tokenStorage,
  })  : _dioClient = dioClient,
        _tokenStorage = tokenStorage;

  final DioClient _dioClient;
  final TokenStorage _tokenStorage;

  Future<void> register(RegisterRequest request) {
    return _dioClient.post<void>(
      ApiEndpoints.register,
      data: request.toJson(),
      requiresAuth: false,
      parser: (_) => null,
    );
  }

  Future<AuthSession> verifyOtp(VerifyOtpRequest request) async {
    final session = await _dioClient.post<AuthSession>(
      ApiEndpoints.verifyOtp,
      data: request.toJson(),
      requiresAuth: false,
      parser: (json) => AuthSession.fromJson(JsonReaders.asMap(json)),
    );

    await _persistSession(session);
    return session;
  }

  Future<AuthSession> login(LoginRequest request) async {
    final session = await _dioClient.post<AuthSession>(
      ApiEndpoints.login,
      data: request.toJson(),
      requiresAuth: false,
      parser: (json) => AuthSession.fromJson(JsonReaders.asMap(json)),
    );

    await _persistSession(session);
    return session;
  }

  Future<AuthSession> refresh({String? refreshToken}) async {
    final token = refreshToken ?? await _tokenStorage.getRefreshToken() ?? '';

    final session = await _dioClient.post<AuthSession>(
      ApiEndpoints.refresh,
      data: {'refreshToken': token},
      requiresAuth: false,
      parser: (json) {
        final map = JsonReaders.asMap(json);
        final accessToken =
            JsonReaders.readString(map, ['accessToken', 'token']);
        final nextRefreshToken =
            JsonReaders.readString(map, ['refreshToken'], fallback: token);

        return AuthSession(
          accessToken: accessToken,
          refreshToken: nextRefreshToken,
          user: null,
        );
      },
    );

    await _tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );

    return session;
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.getRefreshToken() ?? '';

    if (refreshToken.isNotEmpty) {
      await _dioClient.post<void>(
        ApiEndpoints.logout,
        data: LogoutRequest(refreshToken: refreshToken).toJson(),
        parser: (_) => null,
      );
    }

    await _tokenStorage.clearSession();
  }

  Future<void> forgotPassword(ForgotPasswordRequest request) {
    return _dioClient.post<void>(
      ApiEndpoints.forgotPassword,
      data: request.toJson(),
      requiresAuth: false,
      parser: (_) => null,
    );
  }

  Future<void> resetPassword(ResetPasswordRequest request) {
    return _dioClient.post<void>(
      ApiEndpoints.resetPassword,
      data: request.toJson(),
      requiresAuth: false,
      parser: (_) => null,
    );
  }

  Future<void> changePassword(ChangePasswordRequest request) {
    return _dioClient.put<void>(
      ApiEndpoints.changePassword,
      data: request.toJson(),
      parser: (_) => null,
    );
  }

  Future<AuthSession> googleLogin(GoogleLoginRequest request) async {
    final session = await _dioClient.post<AuthSession>(
      ApiEndpoints.google,
      data: request.toJson(),
      requiresAuth: false,
      parser: (json) => AuthSession.fromJson(JsonReaders.asMap(json)),
    );

    await _persistSession(session);
    return session;
  }

  Future<void> resendOtp(ResendOtpRequest request) {
    return _dioClient.post<void>(
      ApiEndpoints.resendOtp,
      data: request.toJson(),
      requiresAuth: false,
      parser: (_) => null,
    );
  }

  Future<void> updateFcmToken(UpdateFcmTokenRequest request) {
    return _dioClient.post<void>(
      ApiEndpoints.fcmToken,
      data: request.toJson(),
      parser: (_) => null,
    );
  }

  Future<UserEntity> getCurrentUser() {
    return _dioClient.get<UserEntity>(
      ApiEndpoints.me,
      parser: (json) {
        final map = JsonReaders.asMap(json);
        return AuthUserModel.fromJson(map).toEntity();
      },
    );
  }

  Future<bool> hasSession() {
    return _tokenStorage.hasSession();
  }

  Future<void> clearSession() {
    return _tokenStorage.clearSession();
  }

  Future<void> _persistSession(AuthSession session) async {
    await _tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );

    if (session.user != null) {
      await _tokenStorage.saveUserRole(session.user!.role.name);
    }
  }
}
