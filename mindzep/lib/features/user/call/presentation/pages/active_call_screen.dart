import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/utils/currency_utils.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../bloc/call_bloc.dart';

class ActiveCallScreen extends StatelessWidget {
  final PsychologistEntity psychologist;

  const ActiveCallScreen({super.key, required this.psychologist});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CallBloc, CallState>(
      listener: (context, state) {
        if (state is CallEnded) {
          context.pushReplacement(RouteNames.callSummary, extra: state);
        }
      },
      builder: (context, state) {
        if (state is CallConnecting) {
          return _buildConnecting(context, state);
        } else if (state is CallActive) {
          return _buildActive(context, state);
        }
        return const Scaffold(
          backgroundColor: Color(0xFF1A1A2E),
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildConnecting(BuildContext context, CallConnecting state) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppAvatar(
                imageUrl: psychologist.avatarUrl,
                radius: 56,
                initials: _initials(psychologist.name),
              ),
              const SizedBox(height: AppDimensions.paddingL),
              Text(state.psychologistName,
                  style:
                      AppTextStyles.title2.copyWith(color: Colors.white)),
              const SizedBox(height: 8),
              Text('Connecting...',
                  style: AppTextStyles.body.copyWith(color: Colors.white60)),
              const SizedBox(height: AppDimensions.paddingXL),
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: AppDimensions.paddingXL),
              TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.call_end_rounded,
                    color: AppColors.error),
                label: Text('Cancel',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.error)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActive(BuildContext context, CallActive state) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // Top: avatar + name + timer + billing
            const Spacer(),
            Center(
              child: Column(
                children: [
                  AppAvatar(
                    imageUrl: psychologist.avatarUrl,
                    radius: 64,
                    initials: _initials(psychologist.name),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  Text(state.psychologistName,
                      style:
                          AppTextStyles.title2.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(state.elapsedSeconds),
                    style: AppTextStyles.title3.copyWith(
                        color: AppColors.primary,
                        fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 8),
                  // Billing indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: state.isFreePhase
                          ? AppColors.success.withOpacity(0.2)
                          : AppColors.warning.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          state.isFreePhase
                              ? Icons.free_cancellation_rounded
                              : Icons.currency_rupee_rounded,
                          size: 12,
                          color: state.isFreePhase
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          state.isFreePhase
                              ? 'Free period (${120 - state.elapsedSeconds}s left)'
                              : '₹${state.chargeAmount.toStringAsFixed(2)} charged',
                          style: AppTextStyles.caption1.copyWith(
                            color: state.isFreePhase
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Video placeholder
                  if (!state.isVideoOff) ...[
                    const SizedBox(height: AppDimensions.paddingL),
                    Container(
                      width: 200,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusL),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Center(
                        child: Text('Mock Video Feed',
                            style: TextStyle(color: Colors.white38)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            // Controls
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingXL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlButton(
                    icon: state.isMuted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    label: state.isMuted ? 'Unmute' : 'Mute',
                    active: state.isMuted,
                    onTap: () =>
                        context.read<CallBloc>().add(const ToggleMute()),
                  ),
                  _ControlButton(
                    icon: Icons.call_end_rounded,
                    label: 'End',
                    color: AppColors.error,
                    isEndCall: true,
                    onTap: () =>
                        context.read<CallBloc>().add(const EndCall()),
                  ),
                  _ControlButton(
                    icon: state.isSpeakerOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    label: 'Speaker',
                    active: state.isSpeakerOn,
                    onTap: () =>
                        context.read<CallBloc>().add(const ToggleSpeaker()),
                  ),
                  _ControlButton(
                    icon: state.isVideoOff
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded,
                    label: state.isVideoOff ? 'Video Off' : 'Video',
                    active: !state.isVideoOff,
                    onTap: () =>
                        context.read<CallBloc>().add(const ToggleVideo()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool active;
  final bool isEndCall;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.color,
    this.active = true,
    this.isEndCall = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isEndCall
        ? AppColors.error
        : active
            ? Colors.white.withOpacity(0.15)
            : Colors.white.withOpacity(0.06);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: isEndCall ? 64 : 52,
            height: isEndCall ? 64 : 52,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon,
                color: color ?? Colors.white,
                size: isEndCall ? 28 : 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: AppTextStyles.caption2.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

