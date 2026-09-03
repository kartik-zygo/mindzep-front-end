import '../../../../core/utils/json_readers.dart';
import '../../domain/entities/user_entity.dart';

class AuthUserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final UserRole role;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;

  const AuthUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.role,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    var roleRaw = JsonReaders.readString(json, [
      'role',
      'userRole',
      'accountType',
      'user_type',
      'type',
    ]).trim();
    if (roleRaw.isEmpty) {
      final roles = JsonReaders.readStringList(json, ['roles']);
      if (roles.isNotEmpty) {
        roleRaw = roles.first;
      }
    }

    return AuthUserModel(
      id: JsonReaders.readString(json, ['id', '_id', 'userId']),
      name: JsonReaders.readString(json, ['name', 'fullName']),
      email: JsonReaders.readString(json, ['email']),
      phone: JsonReaders.readString(json, ['phone', 'mobile']),
      avatarUrl:
          JsonReaders.readString(json, [
            'avatarUrl',
            'avatar',
            'profilePicture',
          ]).trim().isEmpty
          ? null
          : JsonReaders.readString(json, [
              'avatarUrl',
              'avatar',
              'profilePicture',
            ]),
      role: _parseRole(roleRaw),
      isVerified: JsonReaders.readBool(json, [
        'isVerified',
        'verified',
      ], fallback: false),
      isActive: JsonReaders.readBool(json, [
        'isActive',
        'active',
      ], fallback: true),
      createdAt: JsonReaders.readDateTime(json, ['createdAt', 'created_at']),
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      role: role,
      isVerified: isVerified,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  static UserRole _parseRole(String role) {
    switch (role.trim().toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'psych':
      case 'therapist':
      case 'psychologist':
        return UserRole.psychologist;
      case 'user':
      default:
        return UserRole.user;
    }
  }
}

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final AuthUserModel? user;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final userMap = JsonReaders.asMap(
      JsonReaders.readAny(json, ['user', 'profile']),
    );

    final accessToken = JsonReaders.readString(json, [
      'accessToken',
      'token',
    ]).trim();
    final refreshToken = JsonReaders.readString(json, ['refreshToken']).trim();

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: userMap.isEmpty ? null : AuthUserModel.fromJson(userMap),
    );
  }
}

class RegisterRequest {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;
  final String role;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.confirmPassword,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'confirmPassword': confirmPassword,
      'role': role,
    };
  }
}

class VerifyOtpRequest {
  final String identifier;
  final String otp;
  final String purpose;

  const VerifyOtpRequest({
    required this.identifier,
    required this.otp,
    required this.purpose,
  });

  Map<String, dynamic> toJson() {
    return {'identifier': identifier, 'otp': otp, 'purpose': purpose};
  }
}

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

class LogoutRequest {
  final String refreshToken;

  const LogoutRequest({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {'refreshToken': refreshToken};
  }
}

class ForgotPasswordRequest {
  final String email;

  const ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

class ResetPasswordRequest {
  final String identifier;
  final String otp;
  final String newPassword;
  final String confirmPassword;

  const ResetPasswordRequest({
    required this.identifier,
    required this.otp,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'otp': otp,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}

class ResendOtpRequest {
  final String identifier;
  final String purpose;

  const ResendOtpRequest({required this.identifier, required this.purpose});

  Map<String, dynamic> toJson() {
    return {'identifier': identifier, 'purpose': purpose};
  }
}
