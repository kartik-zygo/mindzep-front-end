import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../injection/injection_container.dart';
import '../../data/models/incoming_call_data.dart';
import '../../data/socket/psych_call_socket_service.dart';

/// Full-screen incoming call UI shown on the psychologist's device when a
/// user initiates a session.
class PsychIncomingCallScreen extends StatefulWidget {
  final IncomingCallData callData;

  const PsychIncomingCallScreen({super.key, required this.callData});

  @override
  State<PsychIncomingCallScreen> createState() =>
      _PsychIncomingCallScreenState();
}

class _PsychIncomingCallScreenState extends State<PsychIncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  StreamSubscription<Map<String, dynamic>>? _cancelledSub;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Listen for broadcast cancellation so the ringing screen is dismissed
    // automatically when another psychologist was faster or the user cancelled.
    _cancelledSub = sl<PsychCallSocketService>()
        .onCallCancelled
        .listen((payload) {
      final callId = payload['callId'] as String? ?? '';
      final appointmentId = payload['appointmentId'] as String? ?? '';
      // Match by callId or appointmentId to scope to this specific call.
      if (callId == widget.callData.callId ||
          appointmentId == widget.callData.appointmentId) {
        if (mounted) context.pop();
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _cancelledSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.callData;
    final displayName =
        data.userName.isNotEmpty ? data.userName : 'User';

    return PopScope(
      canPop: false, // prevent accidental back-swipe
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Text(
                  'INCOMING SESSION',
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 2.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.paddingXL),
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Center(
                    child: AppAvatar(
                      imageUrl: data.userAvatar,
                      radius: 68,
                      initials: _initials(displayName),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),
                Text(
                  displayName,
                  style: AppTextStyles.title2.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'wants to start a session with you',
                  style: AppTextStyles.body.copyWith(color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RingButton(
                      icon: Icons.call_end_rounded,
                      label: 'Decline',
                      color: AppColors.error,
                      onTap: () => _decline(context),
                    ),
                    _RingButton(
                      icon: Icons.call_rounded,
                      label: 'Audio',
                      color: AppColors.info,
                      onTap: () => _accept(context, enableVideo: false),
                    ),
                    _RingButton(
                      icon: Icons.videocam_rounded,
                      label: 'Video',
                      color: AppColors.success,
                      onTap: () => _accept(context, enableVideo: true),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _accept(BuildContext context, {required bool enableVideo}) {
    context.pushReplacement(RouteNames.psychActiveCall, extra: {
      'callData': widget.callData,
      'enableVideo': enableVideo,
    });
  }

  void _decline(BuildContext context) {
    context.pop();
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }
}

class _RingButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RingButton({
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.caption1.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
