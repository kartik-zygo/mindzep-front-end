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

class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
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
  final String otp;
  const OtpVerified({required this.otp});
  @override
  List<Object?> get props => [otp];
}

class PasswordResetRequested extends AuthEvent {
  final String newPassword;
  const PasswordResetRequested({required this.newPassword});
}
