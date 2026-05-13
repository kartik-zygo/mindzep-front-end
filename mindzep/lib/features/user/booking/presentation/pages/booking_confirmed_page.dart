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

  const BookingConfirmedPage({
    super.key,
    required this.psychologist,
    required this.slot,
    required this.sessionType,
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
                      value: '${widget.slot.startTime.day}/${widget.slot.startTime.month}/${widget.slot.startTime.year}',
                    ),
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.schedule_rounded,
                      label: 'Time',
                      value: '${widget.slot.startTime.hour.toString().padLeft(2, "0")}:${widget.slot.startTime.minute.toString().padLeft(2, "0")}',
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

