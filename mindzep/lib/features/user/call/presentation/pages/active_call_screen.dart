import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../wallet/presentation/pages/wallet_topup_page.dart';
import '../bloc/call_bloc.dart';
import '../models/call_route_payload.dart';

class ActiveCallScreen extends StatelessWidget {
  final CallRoutePayload payload;

  const ActiveCallScreen({super.key, required this.payload});

  static const _backgroundColor = Color(0xFF14142B);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CallBloc, CallState>(
      listener: (context, state) {
        if (state is WalletExhausted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            _showWalletExhaustedDialog(context, state);
          });
        } else if (state is CallEnded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.pushReplacement(RouteNames.callSummary, extra: state);
          });
        }
      },
      builder: (context, state) {
        if (state is CallConnecting) {
          return _buildConnecting(context, state);
        } else if (state is CallErrorState) {
          return _buildError(context, state);
        } else if (state is CallActive) {
          return _buildActive(context, state);
        }
        return const Scaffold(
          backgroundColor: _backgroundColor,
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  /// Wallet ran out — the server already ended the call. Show the backend's
  /// message, then move on to the summary screen.
  void _showWalletExhaustedDialog(BuildContext context, WalletExhausted state) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Row(children: [
          Icon(Icons.account_balance_wallet_rounded,
              color: AppColors.error, size: 22),
          SizedBox(width: 8),
          Expanded(
            child: Text('Call Ended',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ]),
        content: Text(
          state.message ??
              'Your wallet balance is exhausted. The call has been ended. '
                  'Please recharge your wallet to continue talking.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (context.mounted) {
                context.pushReplacement(RouteNames.callSummary, extra: state);
              }
            },
            child: const Text('View Summary'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, CallErrorState state) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 56,
                ),
                const SizedBox(height: AppDimensions.paddingL),
                Text(
                  'Unable to start call',
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
                  onPressed: () => context.pop(),
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
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

  Widget _buildConnecting(BuildContext context, CallConnecting state) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppAvatar(
                imageUrl: payload.psychologistAvatar,
                radius: 56,
                initials: _initials(payload.psychologistName),
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
    final engine = context.read<CallBloc>().agoraCallEngine.rtcEngine;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF14142B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.paddingM),
              Text(
                state.psychologistName,
                style: AppTextStyles.title2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDuration(state.elapsedSeconds),
                style: AppTextStyles.title3.copyWith(
                    color: AppColors.primary, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 10),
              _buildBillingChips(state),
              if (state.showLowBalanceBanner) ...[
                const SizedBox(height: AppDimensions.paddingS),
                _buildLowBalanceBanner(context, state),
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
                              width: 110,
                              height: 150,
                              child: _buildLocalView(engine),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingXL,
                    vertical: AppDimensions.paddingL),
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
                      icon: state.isSpeakerOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      label: 'Speaker',
                      active: state.isSpeakerOn,
                      onTap: () =>
                          context.read<CallBloc>().add(const ToggleSpeaker()),
                    ),
                    _ControlButton(
                      icon: Icons.call_end_rounded,
                      label: 'End',
                      color: Colors.white,
                      isEndCall: true,
                      onTap: () =>
                          context.read<CallBloc>().add(const EndCall()),
                    ),
                    _ControlButton(
                      icon: state.isVideoOff
                          ? Icons.videocam_off_rounded
                          : Icons.videocam_rounded,
                      label: 'Video',
                      active: !state.isVideoOff,
                      onTap: () =>
                          context.read<CallBloc>().add(const ToggleVideo()),
                    ),
                    _ControlButton(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Recharge',
                      active: true,
                      onTap: () => _openMidCallRecharge(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Live billing summary sourced from heartbeat data — no hardcoded values.
  /// Before the first billing snapshot arrives, only the elapsed timer shows.
  Widget _buildBillingChips(CallActive state) {
    // Prepaid appointments are paid in full at booking — no per-minute,
    // free-minute or talk-time billing applies during the call.
    if (state.isPrepaid) {
      return _chip(
        icon: Icons.verified_rounded,
        label: 'Prepaid · session included',
        color: AppColors.success,
      );
    }

    final billing = state.billing;
    final chips = <Widget>[];

    if (state.isFreePhase) {
      final freeSecondsLeft = billing?.freeSecondsLeft ??
          ((state.freeMinutes * 60) - state.elapsedSeconds).clamp(0, 3600);
      chips.add(_chip(
        icon: Icons.card_giftcard_rounded,
        label: 'Free · ${_formatDuration(freeSecondsLeft)} left',
        color: AppColors.success,
      ));
    } else {
      chips.add(_chip(
        icon: Icons.currency_rupee_rounded,
        label: '₹${state.chargeAmount.toStringAsFixed(0)} charged',
        color: AppColors.warning,
      ));
    }

    if (billing != null) {
      chips.add(_chip(
        icon: Icons.timer_outlined,
        label: '~${billing.remainingMinutes} min left',
        color: billing.lowBalance ? AppColors.error : Colors.white70,
      ));
      chips.add(_chip(
        icon: Icons.account_balance_wallet_outlined,
        label: '₹${billing.walletBalance.toStringAsFixed(0)}',
        color: Colors.white70,
      ));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: chips,
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.caption1.copyWith(color: color)),
        ],
      ),
    );
  }

  /// Persistent, non-blocking low-balance warning with a mid-call recharge
  /// shortcut. Cleared automatically when a heartbeat reports
  /// `lowBalance == false` after a successful top-up.
  Widget _buildLowBalanceBanner(BuildContext context, CallActive state) {
    final remaining = state.billing?.remainingMinutes;
    final message = state.lowBalanceMessage ??
        (remaining != null
            ? 'Low balance — about $remaining minute(s) of talk time left.'
            : 'Low wallet balance — recharge now to avoid disconnection.');

    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption1.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _openMidCallRecharge(context),
            child: const Text('Recharge', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// Opens the wallet top-up flow on top of the call screen WITHOUT ending
  /// the call. On success the next heartbeat picks up the new balance and the
  /// low-balance banner clears automatically.
  void _openMidCallRecharge(BuildContext context) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const WalletTopUpPage()),
    );
  }

  Widget _buildRemoteView(CallActive state, RtcEngine? engine) {
    if (engine == null || state.isVideoOff || state.remoteUid == null) {
      return Container(
        color: Colors.white.withValues(alpha: 0.05),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppAvatar(
                imageUrl: payload.psychologistAvatar,
                radius: 48,
                initials: _initials(payload.psychologistName),
              ),
              const SizedBox(height: 12),
              Text(
                state.remoteUid == null
                    ? 'Waiting for therapist to join...'
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
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
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
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.06);
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
