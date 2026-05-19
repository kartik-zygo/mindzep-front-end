import '../../../../core/entities/entities.dart';
import '../../../../core/utils/json_readers.dart';
import '../../../../core/widgets/app_avatar.dart';

class PsychologistModel {
  final String id;
  final String name;
  final String credentials;
  final String specialization;
  final List<String> specializations;
  final List<String> languages;
  final int yearsExperience;
  final double ratingAverage;
  final int totalReviews;
  final int totalSessions;
  final double ratePerMinute;
  final int freeMinutes;
  final AvailabilityStatus status;
  final String? avatarUrl;
  final String? bio;
  final bool isApproved;
  final bool isActive;
  final DateTime createdAt;

  const PsychologistModel({
    required this.id,
    required this.name,
    required this.credentials,
    required this.specialization,
    required this.specializations,
    required this.languages,
    required this.yearsExperience,
    required this.ratingAverage,
    required this.totalReviews,
    required this.totalSessions,
    required this.ratePerMinute,
    required this.freeMinutes,
    required this.status,
    required this.avatarUrl,
    required this.bio,
    required this.isApproved,
    required this.isActive,
    required this.createdAt,
  });

  factory PsychologistModel.fromJson(Map<String, dynamic> json) {
    final userMap = JsonReaders.asMap(JsonReaders.readAny(json, ['user', 'profile']));
    final statusRaw =
        JsonReaders.readString(json, ['availabilityStatus', 'status', 'availability'], fallback: 'offline');
    final avatar = JsonReaders.readString(
      json,
      ['avatarUrl', 'avatar', 'profilePicture'],
    ).trim();
    final userAvatar = JsonReaders.readString(
      userMap,
      ['avatarUrl', 'avatar', 'profilePicture'],
    ).trim();
    final bio = JsonReaders.readString(json, ['bio']).trim();

    return PsychologistModel(
      id: JsonReaders.readString(json, ['id', '_id', 'psychologistId']),
      name: JsonReaders.readString(
        json,
        ['name', 'fullName'],
        fallback: JsonReaders.readString(
          userMap,
          ['name', 'fullName'],
          fallback: 'Psychologist',
        ),
      ),
      credentials: JsonReaders.readString(json, ['credentials'], fallback: '-'),
      specialization: JsonReaders.readString(
        json,
        ['specialization'],
        fallback: JsonReaders.readString(
          json,
          ['category'],
          fallback: (JsonReaders.readStringList(json, ['specializations']).isNotEmpty)
              ? JsonReaders.readStringList(json, ['specializations']).first
              : 'General',
        ),
      ),
      specializations: JsonReaders.readStringList(json, ['specializations']),
      languages: JsonReaders.readStringList(json, ['languages']),
      yearsExperience: JsonReaders.readInt(json, ['yearsExperience', 'experienceYears']),
      ratingAverage: JsonReaders.readDouble(json, ['ratingAverage', 'rating']),
      totalReviews: JsonReaders.readInt(json, ['totalReviews', 'reviewsCount']),
      totalSessions: JsonReaders.readInt(json, ['totalSessions', 'sessionsCount']),
      ratePerMinute: JsonReaders.readDouble(json, ['ratePerMinute', 'pricePerMinute']),
      freeMinutes: JsonReaders.readInt(json, ['freeMinutes'], fallback: 2),
      status: _parseAvailability(statusRaw),
      avatarUrl: avatar.isEmpty ? (userAvatar.isEmpty ? null : userAvatar) : avatar,
      bio: bio.isEmpty ? null : bio,
      isApproved: JsonReaders.readBool(json, ['isApproved', 'approved'], fallback: true),
      isActive: JsonReaders.readBool(json, ['isActive', 'active'], fallback: true),
      createdAt: JsonReaders.readDateTime(json, ['createdAt', 'created_at']),
    );
  }

  PsychologistEntity toEntity() {
    return PsychologistEntity(
      id: id,
      name: name,
      credentials: credentials,
      specialization: specialization,
      specializations: specializations,
      languages: languages,
      yearsExperience: yearsExperience,
      ratingAverage: ratingAverage,
      totalReviews: totalReviews,
      totalSessions: totalSessions,
      ratePerMinute: ratePerMinute,
      freeMinutes: freeMinutes,
      status: status,
      avatarUrl: avatarUrl,
      bio: bio,
      isApproved: isApproved,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  static AvailabilityStatus _parseAvailability(String value) {
    switch (value.toLowerCase()) {
      case 'available':
        return AvailabilityStatus.available;
      case 'busy':
        return AvailabilityStatus.busy;
      case 'offline':
      default:
        return AvailabilityStatus.offline;
    }
  }
}

class PsychologistUpdateRequest {
  final String? bio;
  final List<String>? languages;
  final double? ratePerMinute;
  final List<String>? specializations;

  const PsychologistUpdateRequest({
    this.bio,
    this.languages,
    this.ratePerMinute,
    this.specializations,
  });

  Map<String, dynamic> toJson() {
    return {
      if (bio != null) 'bio': bio,
      if (languages != null) 'languages': languages,
      if (ratePerMinute != null) 'ratePerMinute': ratePerMinute,
      if (specializations != null) 'specializations': specializations,
    };
  }
}

class AvailabilityUpdateRequest {
  final String status;

  const AvailabilityUpdateRequest({required this.status});

  Map<String, dynamic> toJson() {
    return {'status': status};
  }
}

class PsychologistReviewModel {
  final String id;
  final String userName;
  final String? userAvatar;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  const PsychologistReviewModel({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory PsychologistReviewModel.fromJson(Map<String, dynamic> json) {
    final comment = JsonReaders.readString(json, ['comment', 'review']).trim();
    final avatar = JsonReaders.readString(json, ['userAvatar', 'avatar']).trim();

    return PsychologistReviewModel(
      id: JsonReaders.readString(json, ['id', '_id', 'reviewId']),
      userName: JsonReaders.readString(json, ['userName', 'name']),
      userAvatar: avatar.isEmpty ? null : avatar,
      rating: JsonReaders.readDouble(json, ['rating']),
      comment: comment.isEmpty ? null : comment,
      createdAt: JsonReaders.readDateTime(json, ['createdAt', 'created_at']),
    );
  }
}

class PsychologistBlogPreviewModel {
  final String id;
  final String title;
  final String? category;
  final DateTime createdAt;

  const PsychologistBlogPreviewModel({
    required this.id,
    required this.title,
    required this.category,
    required this.createdAt,
  });

  factory PsychologistBlogPreviewModel.fromJson(Map<String, dynamic> json) {
    final category = JsonReaders.readString(json, ['category']).trim();

    return PsychologistBlogPreviewModel(
      id: JsonReaders.readString(json, ['id', '_id', 'blogId']),
      title: JsonReaders.readString(json, ['title']),
      category: category.isEmpty ? null : category,
      createdAt: JsonReaders.readDateTime(json, ['createdAt', 'created_at']),
    );
  }
}

class PsychologistDocumentModel {
  final String id;
  final String? documentType;
  final String fileUrl;
  final DateTime createdAt;

  const PsychologistDocumentModel({
    required this.id,
    required this.documentType,
    required this.fileUrl,
    required this.createdAt,
  });

  factory PsychologistDocumentModel.fromJson(Map<String, dynamic> json) {
    final documentType = JsonReaders.readString(json, ['documentType', 'type']).trim();

    return PsychologistDocumentModel(
      id: JsonReaders.readString(json, ['id', '_id', 'documentId']),
      documentType: documentType.isEmpty ? null : documentType,
      fileUrl: JsonReaders.readString(json, ['fileUrl', 'url']),
      createdAt: JsonReaders.readDateTime(json, ['createdAt', 'created_at']),
    );
  }
}

class SlotModel {
  final String id;
  final String psychologistId;
  final DateTime startTime;
  final int durationMinutes;
  final List<SessionType> sessionTypes;
  final SlotStatus status;

  const SlotModel({
    required this.id,
    required this.psychologistId,
    required this.startTime,
    required this.durationMinutes,
    required this.sessionTypes,
    required this.status,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    final sessionTypesRaw = JsonReaders.readStringList(json, ['sessionTypes']);
    final statusRaw = JsonReaders.readString(json, ['status'], fallback: 'available');

    return SlotModel(
      id: JsonReaders.readString(json, ['id', '_id', 'slotId']),
      psychologistId:
          JsonReaders.readString(json, ['psychologistId', 'psychologist']),
      startTime: JsonReaders.readDateTime(json, ['startTime', 'start_time']),
      durationMinutes: JsonReaders.readInt(json, ['durationMinutes', 'duration']),
      sessionTypes: sessionTypesRaw.map(_parseSessionType).toList(),
      status: _parseSlotStatus(statusRaw),
    );
  }

  SlotEntity toEntity() {
    return SlotEntity(
      id: id,
      psychologistId: psychologistId,
      startTime: startTime,
      durationMinutes: durationMinutes,
      sessionTypes: sessionTypes,
      status: status,
    );
  }

  static SessionType _parseSessionType(String value) {
    switch (value.toLowerCase()) {
      case 'video':
        return SessionType.video;
      case 'audio':
        return SessionType.audio;
      case 'chat':
      default:
        return SessionType.chat;
    }
  }

  static SlotStatus _parseSlotStatus(String value) {
    switch (value.toLowerCase()) {
      case 'booked':
        return SlotStatus.booked;
      case 'blocked':
        return SlotStatus.blocked;
      case 'available':
      default:
        return SlotStatus.available;
    }
  }
}

class SlotCreateRequest {
  final DateTime startTime;
  final int durationMinutes;
  final List<String> sessionTypes;
  final bool isRecurring;

  const SlotCreateRequest({
    required this.startTime,
    required this.durationMinutes,
    required this.sessionTypes,
    this.isRecurring = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toUtc().toIso8601String(),
      'durationMinutes': durationMinutes,
      'sessionTypes': sessionTypes,
      'isRecurring': isRecurring,
    };
  }
}

class SlotUpdateRequest {
  final DateTime? startTime;
  final int? durationMinutes;
  final List<String>? sessionTypes;

  const SlotUpdateRequest({
    this.startTime,
    this.durationMinutes,
    this.sessionTypes,
  });

  Map<String, dynamic> toJson() {
    return {
      if (startTime != null) 'startTime': startTime!.toUtc().toIso8601String(),
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (sessionTypes != null) 'sessionTypes': sessionTypes,
    };
  }
}

class SlotBulkActionRequest {
  final String action;
  final List<String> slotIds;

  const SlotBulkActionRequest({
    required this.action,
    required this.slotIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'slotIds': slotIds,
    };
  }
}
