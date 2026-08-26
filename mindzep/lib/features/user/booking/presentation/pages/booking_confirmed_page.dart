import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_button.dart';

class BookingConfirmedPage extends StatefulWidget {
  final PsychologistEntity psychologist;
  final SlotEntity slot;
  final String sessionType;
  /// Appointment ID returned after booking. When non-null/non-empty a
  /// "Start Call Now" shortcut is shown so the user can jump straight
  /// into the call without going through the sessions list.
  final String? appointmentId;

  /// The exact sub-range that was booked within the availability window.
  final DateTime bookedStartTime;
  final int bookedDurationMinutes;

  const BookingConfirmedPage({
    super.key,
    required this.psychologist,
    required this.slot,
    required this.sessionType,
    this.appointmentId,
    required this.bookedStartTime,
    required this.bookedDurationMinutes,
  });

  @override
  State<BookingConfirmedPage> createState() => _BookingConfirmedPageState();
}

class _BookingConfirmedPageState extends State<BookingConfirmedPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Success animation
              FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingXL),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              Text(
                'Booking Confirmed!',
                style: AppTextStyles.title2
                    .copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                'Your session has been booked successfully.',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              // Session details card
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusL),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Psychologist',
                      value: widget.psychologist.name,
                    ),
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: '${widget.bookedStartTime.day}/${widget.bookedStartTime.month}/${widget.bookedStartTime.year}',
                    ),
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.schedule_rounded,
                      label: 'Time',
                      value: '${_hhmm(widget.bookedStartTime)} – ${_hhmm(widget.bookedStartTime.add(Duration(minutes: widget.bookedDurationMinutes)))}',
                    ),
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.timelapse_rounded,
                      label: 'Duration',
                      value: '${widget.bookedDurationMinutes} min',
                    ),
                    const Divider(height: 20),
                    _DetailRow(
                      icon: widget.sessionType == 'video'
                          ? Icons.videocam_rounded
                          : Icons.phone_rounded,
                      label: 'Type',
                      value: widget.sessionType == 'video'
                          ? 'Video Session'
                          : 'Audio Session',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // ── "Start Call Now" shortcut, shown once the booking has a
              // confirmed appointmentId.
              if (widget.appointmentId != null &&
                  widget.appointmentId!.isNotEmpty) ...[
                AppButton(
                  label: 'Start Call Now',
                  onPressed: () => context.push(
                    RouteNames.preCall,
                    extra: {
                      'psychologist': widget.psychologist,
                      'appointmentId': widget.appointmentId,
                      'sessionType': widget.sessionType == 'video'
                          ? SessionType.video
                          : SessionType.audio,
                    },
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingM),
              ],
              AppButton(
                label: 'View My Appointments',
                onPressed: () => context.go(RouteNames.userAppointments),
              ),
              const SizedBox(height: AppDimensions.paddingM),
              AppButton(
                label: 'Back to Home',
                style: AppButtonStyle.outlined,
                onPressed: () => context.go(RouteNames.userHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppDimensions.paddingM),
        Text(label,
            style: AppTextStyles.subheadline
                .copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: AppTextStyles.subheadline
                .copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600)),
      ],
    );
  }
}

