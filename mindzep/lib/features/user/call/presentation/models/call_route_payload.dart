import '../../../../../core/entities/entities.dart';

class CallRoutePayload {
  final String appointmentId;
  final String psychologistId;
  final String psychologistName;
  final String? psychologistAvatar;
  final String specialization;
  final double ratePerMinute;
  final int freeMinutes;
  final double rating;
  final int yearsExperience;
  final SessionType preferredSessionType;

  const CallRoutePayload({
    required this.appointmentId,
    required this.psychologistId,
    required this.psychologistName,
    required this.psychologistAvatar,
    required this.specialization,
    required this.ratePerMinute,
    required this.freeMinutes,
    required this.rating,
    required this.yearsExperience,
    required this.preferredSessionType,
  });

  bool get hasAppointment => appointmentId.trim().isNotEmpty;

  factory CallRoutePayload.fromPsychologist(
    PsychologistEntity psychologist, {
    String appointmentId = '',
    SessionType preferredSessionType = SessionType.video,
  }) {
    return CallRoutePayload(
      appointmentId: appointmentId,
      psychologistId: psychologist.id,
      psychologistName: psychologist.name,
      psychologistAvatar: psychologist.avatarUrl,
      specialization: psychologist.specialization,
      ratePerMinute: psychologist.ratePerMinute,
      freeMinutes: psychologist.freeMinutes,
      rating: psychologist.ratingAverage,
      yearsExperience: psychologist.yearsExperience,
      preferredSessionType: preferredSessionType,
    );
  }

  factory CallRoutePayload.fromAppointment(AppointmentEntity appointment) {
    return CallRoutePayload(
      appointmentId: appointment.id,
      psychologistId: appointment.psychologistId,
      psychologistName: appointment.psychologistName.trim().isEmpty
          ? 'Psychologist'
          : appointment.psychologistName,
      psychologistAvatar: appointment.psychologistAvatar,
      specialization: appointment.sessionType == SessionType.video
          ? 'Video Therapist'
          : appointment.sessionType == SessionType.audio
              ? 'Audio Therapist'
              : 'Chat Therapist',
      ratePerMinute: 0,
      freeMinutes: 2,
      rating: 0,
      yearsExperience: 0,
      preferredSessionType: appointment.sessionType,
    );
  }

  /// Minimal payload for calls that originated from the instant broadcast flow
  /// (no prior appointment slot).  Most fields are unknown at navigation time;
  /// the actual billing values come from the BLoC state.
  factory CallRoutePayload.fromBroadcast({
    required String appointmentId,
    required String psychologistName,
    String? psychologistAvatar,
    double ratePerMinute = 0,
    int freeMinutes = 2,
  }) {
    return CallRoutePayload(
      appointmentId: appointmentId,
      psychologistId: '',
      psychologistName: psychologistName,
      psychologistAvatar: psychologistAvatar,
      specialization: 'Instant Session',
      ratePerMinute: ratePerMinute,
      freeMinutes: freeMinutes,
      rating: 0,
      yearsExperience: 0,
      preferredSessionType: SessionType.video,
    );
  }
}
