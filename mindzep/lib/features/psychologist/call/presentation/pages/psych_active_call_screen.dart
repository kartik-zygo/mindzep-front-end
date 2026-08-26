import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../data/models/incoming_call_data.dart';
import '../bloc/psych_call_bloc.dart';

/// Active call screen for the psychologist, rendered after they accept a call.
class PsychActiveCallScreen extends StatefulWidget {
  final IncomingCallData callData;
  final bool enableVideo;

  const PsychActiveCallScreen({
    super.key,
    required this.callData,
    required this.enableVideo,
  });

  @override
  State<PsychActiveCallScreen> createState() => _PsychActiveCallScreenState();
}

class _PsychActiveCallScreenState extends State<PsychActiveCallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _requestPermissionsAndStart();
    });
  }

  Future<void> _requestPermissionsAndStart() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required to join a session.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      context.go(RouteNames.psychSessions);
      return;
    }

    bool videoGranted = false;
    if (widget.enableVideo) {
      final camStatus = await Permission.camera.request();
      videoGranted = camStatus.isGranted;
    }

    if (!mounted) return;
    context.read<PsychCallBloc>().add(PsychStartCall(
          callData: widget.callData,
          enableVideo: widget.enableVideo && videoGranted,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: BlocConsumer<PsychCallBloc, PsychCallState>(
        listener: (context, state) {
          if (state is PsychCallEnded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              if (state.endReason == 'wallet_exhausted') {
                _showWalletExhaustedDialog(context, state);
              } else {
                context.go(RouteNames.psychSessions);
              }
            });
          }
        },
        builder: (context, state) {
          if (state is PsychCallConnecting) {
            return _buildConnecting(context, state);
          } else if (state is PsychCallError) {
            return _buildError(context, state);
          } else if (state is PsychCallActive) {
            return _buildActive(context, state);
          }
          return const Scaffold(
            backgroundColor: Color(0xFF1A1A2E),
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildConnecting(BuildContext context, PsychCallConnecting state) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppAvatar(
                imageUrl: widget.callData.userAvatar,
                radius: 56,
                initials: _initials(widget.callData.userName),
              ),
              const SizedBox(height: AppDimensions.paddingL),
              Text(
                state.userName,
                style: AppTextStyles.title2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Joining session...',
                style: AppTextStyles.body.copyWith(color: Colors.white60),
              ),
              const SizedBox(height: AppDimensions.paddingXL),
              const CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, PsychCallError state) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 56),
                const SizedBox(height: AppDimensions.paddingL),
                Text(
                  'Unable to join session',
                  style: AppTextStyles.title2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppDimensions.paddingS),
                Text(
                  state.message,
                  style: AppTextStyles.body.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.paddingXL),
                TextButton.icon(
                  onPressed: () => context.go(RouteNames.psychSessions),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                  label: Text(
                    'Go Back',
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActive(BuildContext context, PsychCallActive state) {
    final engine = context.read<PsychCallBloc>().agoraCallEngine.rtcEngine;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              state.userName,
              style: AppTextStyles.title2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDuration(state.elapsedSeconds),
              style: AppTextStyles.title3.copyWith(
                color: AppColors.primary,
                fontFamily: 'monospace',
              ),
            ),
            if (state.userLowBalance) ...[
              const SizedBox(height: AppDimensions.paddingS),
              Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingL),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "User's balance is low — the call may end soon.",
                        style: AppTextStyles.caption1
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppDimensions.paddingM),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingL),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusL),
                        child: _buildRemoteView(state, engine),
                      ),
                    ),
                    if (!state.isVideoOff)
                      Positioned(
                        right: 12,
                        top: 12,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 120,
                            height: 160,
                            child: _buildLocalView(engine),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingXL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CtrlBtn(
                    icon: state.isMuted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    label: state.isMuted ? 'Unmute' : 'Mute',
                    active: state.isMuted,
                    onTap: () => context
                        .read<PsychCallBloc>()
                        .add(const PsychToggleMute()),
                  ),
                  _CtrlBtn(
                    icon: Icons.call_end_rounded,
                    label: 'End',
                    color: AppColors.error,
                    isEndCall: true,
                    onTap: () => context
                        .read<PsychCallBloc>()
                        .add(const PsychEndCall()),
                  ),
                  _CtrlBtn(
                    icon: state.isSpeakerOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    label: 'Speaker',
                    active: state.isSpeakerOn,
                    onTap: () => context
                        .read<PsychCallBloc>()
                        .add(const PsychToggleSpeaker()),
                  ),
                  _CtrlBtn(
                    icon: state.isVideoOff
                        ? Icons.videocam_off_rounded
                        : Icons.videocam_rounded,
                    label: state.isVideoOff ? 'Video Off' : 'Video',
                    active: !state.isVideoOff,
                    onTap: () => context
                        .read<PsychCallBloc>()
                        .add(const PsychToggleVideo()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteView(PsychCallActive state, RtcEngine? engine) {
    // Note: state.isVideoOff is the *local* camera flag — do not use it here.
    if (engine == null || state.remoteUid == null) {
      return Container(
        color: Colors.white.withOpacity(0.05),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppAvatar(
                imageUrl: widget.callData.userAvatar,
                radius: 48,
                initials: _initials(widget.callData.userName),
              ),
              const SizedBox(height: 12),
              Text(
                state.remoteUid == null
                    ? 'Waiting for user to connect...'
                    : 'Remote video unavailable',
                style: AppTextStyles.body.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: engine,
        canvas: VideoCanvas(uid: state.remoteUid),
        connection: RtcConnection(channelId: state.channelName),
      ),
    );
  }

  Widget _buildLocalView(RtcEngine? engine) {
    if (engine == null) {
      return Container(
        color: Colors.black54,
        child: const Center(
          child: Icon(Icons.videocam_off_rounded, color: Colors.white70),
        ),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  /// The server force-ended the call because the user's wallet ran out —
  /// explain that to the psychologist before returning to sessions.
  void _showWalletExhaustedDialog(BuildContext context, PsychCallEnded state) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Call Ended',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Text(
          state.message ?? "Call ended — user's wallet balance is exhausted.",
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (context.mounted) context.go(RouteNames.psychSessions);
            },
            child: const Text('OK'),
          ),
        ],
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
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool active;
  final bool isEndCall;
  final VoidCallback onTap;

  const _CtrlBtn({
    required this.icon,
    required this.label,
    this.color,
    this.active = true,
    this.isEndCall = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isEndCall
        ? AppColors.error
        : active
            ? (color ?? AppColors.primary).withOpacity(0.2)
            : Colors.white.withOpacity(0.1);
    final iconColor = isEndCall
        ? Colors.white
        : active
            ? (color ?? AppColors.primary)
            : Colors.white60;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration:
                BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption2.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
