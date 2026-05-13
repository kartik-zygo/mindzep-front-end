import 'package:equatable/equatable.dart';

enum UserRole { user, psychologist, admin }

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final UserRole role;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;

  const UserEntity({
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

  @override
  List<Object?> get props =>
      [id, name, email, phone, avatarUrl, role, isVerified, isActive, createdAt];

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    UserRole? role,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
