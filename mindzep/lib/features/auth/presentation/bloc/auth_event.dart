import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role; // 'user' or 'psychologist'
  const RegisterRequested({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
  });
  @override
  List<Object?> get props => [email, role];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;
  const ForgotPasswordRequested({required this.email});
  @override
  List<Object?> get props => [email];
}

class OtpVerified extends AuthEvent {
  final String identifier;
  final String otp;
  final String purpose;

  const OtpVerified({
    required this.identifier,
    required this.otp,
    required this.purpose,
  });

  @override
  List<Object?> get props => [identifier, otp, purpose];
}

class ResendOtpRequested extends AuthEvent {
  final String identifier;
  final String purpose;

  const ResendOtpRequested({required this.identifier, required this.purpose});

  @override
  List<Object?> get props => [identifier, purpose];
}

class PasswordResetRequested extends AuthEvent {
  final String identifier;
  final String otp;
  final String newPassword;
  final String confirmPassword;

  const PasswordResetRequested({
    required this.identifier,
    required this.otp,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [identifier, otp, newPassword, confirmPassword];
}

class ChangePasswordRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword, confirmPassword];
}

class SessionRefreshRequested extends AuthEvent {
  const SessionRefreshRequested();
}
