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
  }) : _dioClient = dioClient,
       _tokenStorage = tokenStorage;

  final DioClient _dioClient;
  final TokenStorage _tokenStorage;

  Future<void> register(RegisterRequest request) async {
    await _dioClient.post<void>(
      ApiEndpoints.register,
      data: request.toJson(),
      requiresAuth: false,
      parser: (_) => null,
    );

    // Keep the selected registration role so OTP/first-session bootstrap
    // can recover role-specific routing even if backend profile payload is sparse.
    final normalized = _normalizeRoleNameOrNull(request.role);
    if (normalized != null) {
      await _tokenStorage.saveUserRole(normalized);
    }
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
        // The API returns { success, message, data: { accessToken, refreshToken } }.
        // DioClient's extractData unwraps the 'data' envelope so json is already
        // { accessToken, refreshToken }. Guard against both shapes just in case.
        final raw = JsonReaders.asMap(json);
        final map = raw.containsKey('accessToken')
            ? raw
            : JsonReaders.asMap(raw['data']);
        final accessToken = JsonReaders.readString(map, [
          'accessToken',
          'token',
        ]);
        final nextRefreshToken = JsonReaders.readString(map, [
          'refreshToken',
        ], fallback: token);

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

  Future<UserEntity> getCurrentUser() async {
    final map = await _dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.me,
      parser: (json) => JsonReaders.asMap(json),
    );

    final roleFromApi = JsonReaders.readString(map, [
      'role',
      'userRole',
      'accountType',
      'user_type',
      'type',
    ]).trim();

    if (roleFromApi.isEmpty) {
      final savedRole = await _tokenStorage.getUserRole();
      final normalizedSavedRole = _normalizeRoleNameOrNull(savedRole);
      if (normalizedSavedRole != null) {
        map['role'] = normalizedSavedRole;
      }
    }

    final user = AuthUserModel.fromJson(map).toEntity();
    await _tokenStorage.saveUserRole(user.role.name);
    return user;
  }

  Future<bool> hasSession() {
    return _tokenStorage.hasSession();
  }

  Future<void> clearSession() {
    return _tokenStorage.clearSession();
  }

  Future<void> syncUserRole(UserRole role) {
    return _tokenStorage.saveUserRole(role.name);
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

  String? _normalizeRoleNameOrNull(String? roleRaw) {
    final normalized = roleRaw?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return null;

    switch (normalized) {
      case 'user':
        return 'user';
      case 'psych':
      case 'therapist':
      case 'psychologist':
        return 'psychologist';
      case 'admin':
        return 'admin';
      default:
        return null;
    }
  }
}
