import '../../../../../core/entities/entities.dart';
import '../../../../../core/utils/json_readers.dart';

class AppointmentModel {
  final String id;
  final String userId;
  final String userName;
  final String psychologistId;
  final String psychologistName;
  final String? psychologistAvatar;
  final DateTime scheduledAt;
  final int durationMinutes;
  final SessionType sessionType;
  final AppointmentStatus status;
  final int? actualDurationSeconds;
  final double? totalCharge;
  final String? paymentId;
  final PaymentStatus? paymentStatus;
  final double? rating;
  final String? userNotes;
  final String? psychologistNotes;
  final DateTime createdAt;

  const AppointmentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.psychologistId,
    required this.psychologistName,
    required this.psychologistAvatar,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.sessionType,
    required this.status,
    required this.actualDurationSeconds,
    required this.totalCharge,
    required this.paymentId,
    required this.paymentStatus,
    required this.rating,
    required this.userNotes,
    required this.psychologistNotes,
    required this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final psychologist = JsonReaders.asMap(
      JsonReaders.readAny(json, ['psychologist', 'doctor']),
    );
    final user = JsonReaders.asMap(JsonReaders.readAny(json, ['user', 'patient']));

    final avatar = JsonReaders.readString(
      psychologist,
      ['avatarUrl', 'avatar', 'profilePicture'],
    ).trim();

    final userNotes = JsonReaders.readString(json, ['userNotes', 'notes']).trim();
    final psychologistNotes =
        JsonReaders.readString(json, ['psychologistNotes']).trim();

    final sessionTypeRaw =
        JsonReaders.readString(json, ['sessionType'], fallback: 'video');
    final statusRaw =
        JsonReaders.readString(json, ['status'], fallback: 'upcoming');
    final paymentStatusRaw =
        JsonReaders.readString(json, ['paymentStatus']).trim();

    return AppointmentModel(
      id: JsonReaders.readString(json, ['id', '_id', 'appointmentId']),
      userId: JsonReaders.readString(json, ['userId'], fallback: JsonReaders.readString(user, ['id', '_id'])),
      userName: JsonReaders.readString(json, ['userName'], fallback: JsonReaders.readString(user, ['name', 'fullName'])),
      psychologistId: JsonReaders.readString(
        json,
        ['psychologistId'],
        fallback: JsonReaders.readString(psychologist, ['id', '_id']),
      ),
      psychologistName: JsonReaders.readString(
        json,
        ['psychologistName'],
        fallback: JsonReaders.readString(psychologist, ['name', 'fullName']),
      ),
      psychologistAvatar: avatar.isEmpty ? null : avatar,
      scheduledAt: JsonReaders.readDateTime(
        json,
        ['scheduledAt', 'slotStartTime', 'appointmentTime'],
      ),
      durationMinutes: JsonReaders.readInt(json, ['durationMinutes', 'duration']),
      sessionType: _parseSessionType(sessionTypeRaw),
      status: _parseStatus(statusRaw),
      actualDurationSeconds:
          JsonReaders.readAny(json, ['actualDurationSeconds']) == null
              ? null
              : JsonReaders.readInt(json, ['actualDurationSeconds']),
      totalCharge: JsonReaders.readAny(json, ['totalCharge']) == null
          ? null
          : JsonReaders.readDouble(json, ['totalCharge']),
      paymentId: JsonReaders.readString(json, ['paymentId']).trim().isEmpty
          ? null
          : JsonReaders.readString(json, ['paymentId']),
      paymentStatus: paymentStatusRaw.isEmpty
          ? null
          : _parsePaymentStatus(paymentStatusRaw),
      rating: JsonReaders.readAny(json, ['rating']) == null
          ? null
          : JsonReaders.readDouble(json, ['rating']),
      userNotes: userNotes.isEmpty ? null : userNotes,
      psychologistNotes:
          psychologistNotes.isEmpty ? null : psychologistNotes,
      createdAt: JsonReaders.readDateTime(json, ['createdAt', 'created_at']),
    );
  }

  AppointmentEntity toEntity() {
    return AppointmentEntity(
      id: id,
      userId: userId,
      userName: userName,
      psychologistId: psychologistId,
      psychologistName: psychologistName,
      psychologistAvatar: psychologistAvatar,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      sessionType: sessionType,
      status: status,
      actualDurationSeconds: actualDurationSeconds,
      totalCharge: totalCharge,
      paymentId: paymentId,
      paymentStatus: paymentStatus,
      rating: rating,
      userNotes: userNotes,
      psychologistNotes: psychologistNotes,
      createdAt: createdAt,
    );
  }

  static SessionType _parseSessionType(String value) {
    switch (value.toLowerCase()) {
      case 'audio':
        return SessionType.audio;
      case 'chat':
        return SessionType.chat;
      case 'video':
      default:
        return SessionType.video;
    }
  }

  static AppointmentStatus _parseStatus(String value) {
    switch (value.toLowerCase()) {
      case 'ongoing':
      case 'in_progress':
        return AppointmentStatus.ongoing;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'no_show':
        return AppointmentStatus.noShow;
      case 'upcoming':
      default:
        return AppointmentStatus.upcoming;
    }
  }

  static PaymentStatus _parsePaymentStatus(String value) {
    switch (value.toLowerCase()) {
      case 'paid':
      case 'success':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'failed':
        return PaymentStatus.failed;
      case 'pending':
      default:
        return PaymentStatus.pending;
    }
  }
}

class BookAppointmentRequest {
  final String slotId;
  final String psychologistId;
  final String sessionType;

  /// Optional sub-range within the availability window. When provided, only
  /// `[startTime, startTime + durationMinutes]` is booked and the leftover
  /// time in the window stays available. Omit both to book the full window.
  final DateTime? startTime;
  final int? durationMinutes;

  const BookAppointmentRequest({
    required this.slotId,
    required this.psychologistId,
    required this.sessionType,
    this.startTime,
    this.durationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'slotId': slotId,
      'psychologistId': psychologistId,
      'sessionType': sessionType,
      if (startTime != null) 'startTime': startTime!.toUtc().toIso8601String(),
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
    };
  }
}

class CancelAppointmentRequest {
  final String reason;

  const CancelAppointmentRequest({required this.reason});

  Map<String, dynamic> toJson() {
    return {'reason': reason};
  }
}

class PsychologistNotesRequest {
  final String notes;

  const PsychologistNotesRequest({required this.notes});

  Map<String, dynamic> toJson() {
    return {'notes': notes};
  }
}

class RateAppointmentRequest {
  final double rating;
  final String? review;

  const RateAppointmentRequest({required this.rating, this.review});

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      if (review != null && review!.trim().isNotEmpty) 'review': review,
    };
  }
}
