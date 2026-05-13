import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_button.dart';
import '../bloc/call_bloc.dart';

class PreCallScreen extends StatelessWidget {
  final PsychologistEntity psychologist;

  const PreCallScreen({super.key, required this.psychologist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Avatar
              Center(
                child: AppAvatar(
                  imageUrl: psychologist.avatarUrl,
                  radius: 56,
                  availabilityStatus: psychologist.status,
                  showStatusDot: true,
                  initials: _initials(psychologist.name),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingL),
              Text(
                psychologist.name,
                style:
                    AppTextStyles.title2.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                psychologist.specialization,
                style: AppTextStyles.subheadline
                    .copyWith(color: Colors.white60),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingL),
              // Info card
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusL),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                        icon: Icons.currency_rupee_rounded,
                        label:
                            '₹${psychologist.ratePerMinute}/min · First 2 min free'),
                    const SizedBox(height: 8),
                    _InfoRow(
                        icon: Icons.star_rounded,
                        label:
                            '${psychologist.ratingAverage.toStringAsFixed(1)} rating · ${psychologist.yearsExperience} yrs exp'),
                  ],
                ),
              ),
              const Spacer(),
              // Call buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallButton(
                    icon: Icons.videocam_rounded,
                    label: 'Video',
                    color: AppColors.primary,
                    onTap: () {
                      context.read<CallBloc>().add(InitiateCall(
                          appointmentId: 'instant_${DateTime.now().millisecondsSinceEpoch}',
                          psychologistId: psychologist.id));
                      context.pushReplacement(
                          RouteNames.activeCall,
                          extra: psychologist);
                    },
                  ),
                  _CallButton(
                    icon: Icons.phone_rounded,
                    label: 'Audio',
                    color: AppColors.info,
                    onTap: () {
                      context.read<CallBloc>().add(InitiateCall(
                          appointmentId: 'instant_${DateTime.now().millisecondsSinceEpoch}',
                          psychologistId: psychologist.id));
                      context.pushReplacement(
                          RouteNames.activeCall,
                          extra: psychologist);
                    },
                  ),
                  _CallButton(
                    icon: Icons.close_rounded,
                    label: 'Cancel',
                    color: AppColors.error,
                    onTap: () => context.pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingXL),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.white60),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.subheadline.copyWith(color: Colors.white70)),
      ],
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: AppTextStyles.caption1.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

