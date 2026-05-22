import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../user/data/repositories/user_repository.dart';
import '../bloc/call_bloc.dart';
import '../models/call_route_payload.dart';

class PreCallScreen extends StatefulWidget {
  final CallRoutePayload payload;

  const PreCallScreen({super.key, required this.payload});

  @override
  State<PreCallScreen> createState() => _PreCallScreenState();
}

class _PreCallScreenState extends State<PreCallScreen> {
  late final UserRepository _userRepository;
  double _walletBalance = 0;
  bool _walletLoaded = false;

  @override
  void initState() {
    super.initState();
    _userRepository = sl<UserRepository>();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    try {
      final wallet = await _userRepository.getMyWallet();
      if (mounted) {
        setState(() {
          _walletBalance = wallet.balance;
          _walletLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _walletLoaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CallBloc, CallState>(
      listenWhen: (previous, current) {
        if (current is CallErrorState) return true;
        return previous is! CallActive && current is CallActive;
      },
      listener: (context, state) {
        if (state is CallActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.push(
              RouteNames.activeCall,
              extra: {
                'payload': widget.payload,
                'callBloc': context.read<CallBloc>(),
              },
            );
          });
        } else if (state is CallErrorState) {
          AppSnackbar.show(
            context,
            message: state.message,
            type: SnackbarType.error,
          );
        }
      },
      builder: (context, state) {
        final isConnecting = state is CallConnecting;
        // Only gate on empty wallet when there is no booked appointment.
        // With a valid appointment the call can proceed (free minutes apply;
        // billing tracks but the auto-end guard requires wallet > 0).
        final hasNoBalance = _walletLoaded &&
            _walletBalance <= 0 &&
            !widget.payload.hasAppointment;
        final callsDisabled = isConnecting || hasNoBalance;

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
                  Center(
                    child: AppAvatar(
                      imageUrl: widget.payload.psychologistAvatar,
                      radius: 56,
                      initials: _initials(widget.payload.psychologistName),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  Text(
                    widget.payload.psychologistName,
                    style: AppTextStyles.title2.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.payload.specialization,
                    style:
                        AppTextStyles.subheadline.copyWith(color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.currency_rupee_rounded,
                          label:
                              '₹${widget.payload.ratePerMinute.toStringAsFixed(0)}/min · First ${widget.payload.freeMinutes} min free',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.star_rounded,
                          label: widget.payload.rating > 0
                              ? '${widget.payload.rating.toStringAsFixed(1)} rating · ${widget.payload.yearsExperience} yrs exp'
                              : 'Session starts from your booked appointment',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.account_balance_wallet_rounded,
                          label: _walletLoaded
                              ? 'Wallet: ₹${_walletBalance.toStringAsFixed(0)}'
                              : 'Loading wallet...',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingM),
                  if (!widget.payload.hasAppointment)
                    Text(
                      'Call requires an active or upcoming booked session.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption1
                          .copyWith(color: const Color(0xFFFFB4A9)),
                    ),
                  if (hasNoBalance)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Your wallet is empty. Please add funds to start a call.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption1
                            .copyWith(color: const Color(0xFFFFB4A9)),
                      ),
                    ),
                  const Spacer(),
                  if (isConnecting)
                    const Padding(
                      padding: EdgeInsets.only(bottom: AppDimensions.paddingL),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                  if (hasNoBalance)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.paddingL),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _CallButton(
                            icon: Icons.add_card_rounded,
                            label: 'Add Funds',
                            color: AppColors.primary,
                            disabled: false,
                            onTap: () {
                              context.pop();
                              context.push(RouteNames.userWallet);
                            },
                          ),
                          _CallButton(
                            icon: Icons.close_rounded,
                            label: 'Cancel',
                            color: AppColors.error,
                            disabled: false,
                            onTap: () => context.pop(),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _CallButton(
                          icon: Icons.videocam_rounded,
                          label: 'Video',
                          color: AppColors.primary,
                          disabled: callsDisabled,
                          onTap: () => _startCall(context, enableVideo: true),
                        ),
                        _CallButton(
                          icon: Icons.phone_rounded,
                          label: 'Audio',
                          color: AppColors.info,
                          disabled: callsDisabled,
                          onTap: () => _startCall(context, enableVideo: false),
                        ),
                        _CallButton(
                          icon: Icons.close_rounded,
                          label: 'Cancel',
                          color: AppColors.error,
                          disabled: isConnecting,
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
      },
    );
  }

  Future<void> _startCall(BuildContext context, {required bool enableVideo}) async {
    if (!widget.payload.hasAppointment) {
      AppSnackbar.show(
        context,
        message: 'No valid appointment found for this call.',
        type: SnackbarType.error,
      );
      return;
    }

    final microphoneStatus = await Permission.microphone.request();
    if (!microphoneStatus.isGranted) {
      AppSnackbar.show(
        context,
        message: 'Microphone permission is required to start a call.',
        type: SnackbarType.error,
      );
      return;
    }

    if (enableVideo) {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        AppSnackbar.show(
          context,
          message: 'Camera permission is required for video calls.',
          type: SnackbarType.error,
        );
        return;
      }
    }

    context.read<CallBloc>().add(
          InitiateCall(
            appointmentId: widget.payload.appointmentId,
            psychologistId: widget.payload.psychologistId,
            psychologistName: widget.payload.psychologistName,
            psychologistAvatar: widget.payload.psychologistAvatar,
            enableVideo: enableVideo,
            walletBalance: _walletBalance,
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
  final bool disabled;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration:
                BoxDecoration(color: disabled ? color.withOpacity(0.5) : color, shape: BoxShape.circle),
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

