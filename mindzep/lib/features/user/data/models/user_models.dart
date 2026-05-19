import '../../../../core/utils/json_readers.dart';

class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String role;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;

  const UserProfileModel({
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

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final avatar = JsonReaders.readString(
      json,
      ['avatarUrl', 'avatar', 'profilePicture'],
    ).trim();

    return UserProfileModel(
      id: JsonReaders.readString(json, ['id', '_id', 'userId']),
      name: JsonReaders.readString(json, ['name', 'fullName']),
      email: JsonReaders.readString(json, ['email']),
      phone: JsonReaders.readString(json, ['phone', 'mobile']),
      avatarUrl: avatar.isEmpty ? null : avatar,
      role: JsonReaders.readString(json, ['role'], fallback: 'user'),
      isVerified: JsonReaders.readBool(json, ['isVerified', 'verified'], fallback: false),
      isActive: JsonReaders.readBool(json, ['isActive', 'active'], fallback: true),
      createdAt: JsonReaders.readDateTime(json, ['createdAt', 'created_at']),
    );
  }
}

class UserUpdateRequest {
  final String? name;
  final String? phone;
  final String? avatarUrl;

  const UserUpdateRequest({
    this.name,
    this.phone,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}

class ExtendedProfileModel {
  final String? bio;
  final String? gender;
  final String? location;
  final DateTime? dateOfBirth;
  final Map<String, dynamic> raw;

  const ExtendedProfileModel({
    required this.bio,
    required this.gender,
    required this.location,
    required this.dateOfBirth,
    required this.raw,
  });

  factory ExtendedProfileModel.fromJson(Map<String, dynamic> json) {
    final dobString = JsonReaders.readString(
      json,
      ['dateOfBirth', 'dob'],
    ).trim();

    return ExtendedProfileModel(
      bio: JsonReaders.readString(json, ['bio']).trim().isEmpty
          ? null
          : JsonReaders.readString(json, ['bio']),
      gender: JsonReaders.readString(json, ['gender']).trim().isEmpty
          ? null
          : JsonReaders.readString(json, ['gender']),
      location: JsonReaders.readString(json, ['location', 'city']).trim().isEmpty
          ? null
          : JsonReaders.readString(json, ['location', 'city']),
      dateOfBirth:
          dobString.isEmpty ? null : DateTime.tryParse(dobString),
      raw: json,
    );
  }
}

class ExtendedProfileUpdateRequest {
  final String? bio;
  final String? gender;
  final String? location;
  final DateTime? dateOfBirth;

  const ExtendedProfileUpdateRequest({
    this.bio,
    this.gender,
    this.location,
    this.dateOfBirth,
  });

  Map<String, dynamic> toJson() {
    return {
      if (bio != null) 'bio': bio,
      if (gender != null) 'gender': gender,
      if (location != null) 'location': location,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
    };
  }
}

class WalletSummaryModel {
  final double balance;
  final double totalCredits;
  final double totalDebits;
  final String currency;
  final Map<String, dynamic> raw;

  const WalletSummaryModel({
    required this.balance,
    required this.totalCredits,
    required this.totalDebits,
    required this.currency,
    required this.raw,
  });

  factory WalletSummaryModel.fromJson(Map<String, dynamic> json) {
    // Backend may wrap wallet data under a 'wallet' key: { "wallet": { ... } }
    final walletData = JsonReaders.readAny(json, ['wallet']) != null
        ? JsonReaders.asMap(json['wallet'])
        : json;
    return WalletSummaryModel(
      balance: JsonReaders.readDouble(
        walletData,
        ['balance', 'walletBalance', 'amount'],
      ),
      totalCredits: JsonReaders.readDouble(walletData, ['totalCredits', 'credits']),
      totalDebits: JsonReaders.readDouble(walletData, ['totalDebits', 'debits']),
      currency: JsonReaders.readString(walletData, ['currency'], fallback: 'INR'),
      raw: json,
    );
  }
}

class MoodLogModel {
  final String id;
  final int score;
  final String? tag;
  final String? note;
  final DateTime createdAt;

  const MoodLogModel({
    required this.id,
    required this.score,
    required this.tag,
    required this.note,
    required this.createdAt,
  });

  factory MoodLogModel.fromJson(Map<String, dynamic> json) {
    final tag = JsonReaders.readString(json, ['tag']).trim();
    final note = JsonReaders.readString(json, ['note']).trim();

    return MoodLogModel(
      id: JsonReaders.readString(json, ['id', '_id', 'moodId']),
      score: JsonReaders.readInt(json, ['score']),
      tag: tag.isEmpty ? null : tag,
      note: note.isEmpty ? null : note,
      createdAt: JsonReaders.readDateTime(json, ['createdAt', 'created_at']),
    );
  }
}

class MoodCreateRequest {
  final int score;
  final String? tag;
  final String? note;

  const MoodCreateRequest({
    required this.score,
    this.tag,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      if (tag != null && tag!.trim().isNotEmpty) 'tag': tag,
      if (note != null && note!.trim().isNotEmpty) 'note': note,
    };
  }
}

class UserNotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const UserNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory UserNotificationModel.fromJson(Map<String, dynamic> json) {
    return UserNotificationModel(
      id: JsonReaders.readString(json, ['id', '_id', 'notificationId']),
      title: JsonReaders.readString(json, ['title']),
      body: JsonReaders.readString(json, ['body', 'message']),
      type: JsonReaders.readString(json, ['type'], fallback: 'system'),
      isRead: JsonReaders.readBool(json, ['isRead', 'read']),
      createdAt: JsonReaders.readDateTime(json, ['createdAt', 'created_at']),
    );
  }
}
