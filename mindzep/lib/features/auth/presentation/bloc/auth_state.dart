import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthOtpSent extends AuthState {
  final String email;
  const AuthOtpSent(this.email);
  @override
  List<Object?> get props => [email];
}

class AuthOtpVerified extends AuthState {
  const AuthOtpVerified();
}

class AuthPasswordResetSuccess extends AuthState {
  const AuthPasswordResetSuccess();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
