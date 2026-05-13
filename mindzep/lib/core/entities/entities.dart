import 'package:equatable/equatable.dart';
import '../../../../core/widgets/app_avatar.dart';

enum SessionType { video, audio, chat }

enum AppointmentStatus { upcoming, ongoing, completed, cancelled, noShow }

enum PaymentStatus { pending, paid, refunded, failed }

enum SlotStatus { available, booked, blocked }

enum BlogStatus { draft, underReview, published, rejected }

// ─── Psychologist Entity ──────────────────────────────────────────────────────

class PsychologistEntity extends Equatable {
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

  const PsychologistEntity({
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
    this.avatarUrl,
    this.bio,
    required this.isApproved,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, status, ratingAverage];
}

// ─── Slot Entity ──────────────────────────────────────────────────────────────

class SlotEntity extends Equatable {
  final String id;
  final String psychologistId;
  final DateTime startTime;
  final int durationMinutes;
  final List<SessionType> sessionTypes;
  final SlotStatus status;

  const SlotEntity({
    required this.id,
    required this.psychologistId,
    required this.startTime,
    required this.durationMinutes,
    required this.sessionTypes,
    required this.status,
  });

  @override
  List<Object?> get props => [id, startTime, status];
}

// ─── Appointment Entity ───────────────────────────────────────────────────────

class AppointmentEntity extends Equatable {
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

  const AppointmentEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.psychologistId,
    required this.psychologistName,
    this.psychologistAvatar,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.sessionType,
    required this.status,
    this.actualDurationSeconds,
    this.totalCharge,
    this.paymentId,
    this.paymentStatus,
    this.rating,
    this.userNotes,
    this.psychologistNotes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, status, scheduledAt];

  AppointmentEntity copyWith({
    AppointmentStatus? status,
    double? rating,
    String? psychologistNotes,
    String? userNotes,
    int? actualDurationSeconds,
    double? totalCharge,
    PaymentStatus? paymentStatus,
  }) {
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
      status: status ?? this.status,
      actualDurationSeconds: actualDurationSeconds ?? this.actualDurationSeconds,
      totalCharge: totalCharge ?? this.totalCharge,
      paymentId: paymentId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      rating: rating ?? this.rating,
      userNotes: userNotes ?? this.userNotes,
      psychologistNotes: psychologistNotes ?? this.psychologistNotes,
      createdAt: createdAt,
    );
  }
}

// ─── Review Entity ────────────────────────────────────────────────────────────

class ReviewEntity extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  const ReviewEntity({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, rating, createdAt];
}

// ─── Blog Entity ──────────────────────────────────────────────────────────────

class BlogEntity extends Equatable {
  final String id;
  final String psychologistId;
  final String psychologistName;
  final String? psychologistAvatar;
  final String title;
  final String body;
  final String category;
  final List<String> tags;
  final String? coverImageUrl;
  final BlogStatus status;
  final int viewCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime? publishedAt;

  const BlogEntity({
    required this.id,
    required this.psychologistId,
    required this.psychologistName,
    this.psychologistAvatar,
    required this.title,
    required this.body,
    required this.category,
    required this.tags,
    this.coverImageUrl,
    required this.status,
    this.viewCount = 0,
    this.commentCount = 0,
    required this.createdAt,
    this.publishedAt,
  });

  @override
  List<Object?> get props => [id, title, status];
}

// ─── Call Session Entity ──────────────────────────────────────────────────────

class CallSessionEntity extends Equatable {
  final String id;
  final String appointmentId;
  final String channelName;
  final String token;
  final double ratePerMinute;
  final int freeMinutes;
  final DateTime? connectedAt;
  final DateTime? disconnectedAt;
  final int? totalSeconds;
  final int? billedSeconds;
  final double? totalCharge;

  const CallSessionEntity({
    required this.id,
    required this.appointmentId,
    required this.channelName,
    required this.token,
    required this.ratePerMinute,
    required this.freeMinutes,
    this.connectedAt,
    this.disconnectedAt,
    this.totalSeconds,
    this.billedSeconds,
    this.totalCharge,
  });

  @override
  List<Object?> get props => [id, appointmentId];
}
