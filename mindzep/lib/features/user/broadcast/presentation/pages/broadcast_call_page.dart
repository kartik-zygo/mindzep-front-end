import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../injection/injection_container.dart';
import '../../../../user/call/presentation/bloc/call_bloc.dart';
import '../../../../user/call/presentation/models/call_route_payload.dart';
import '../bloc/broadcast_bloc.dart';

/// "Talk to a Psychologist Now" waiting screen.
///
/// Initiates a no-appointment instant broadcast via [BroadcastCallBloc], shows
/// a radar animation while waiting, and navigates to [ActiveCallScreen] the
/// moment a psychologist accepts.
class BroadcastCallPage extends StatefulWidget {
  const BroadcastCallPage({super.key});

  @override
  State<BroadcastCallPage> createState() => _BroadcastCallPageState();
}

class _BroadcastCallPageState extends State<BroadcastCallPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _ringCtrl;
  late Animation<double> _ring1, _ring2, _ring3;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat();
    _ring1 = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0, 0.7, curve: Curves.easeOut)));
    _ring2 = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOut)));
    _ring3 = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));

    // Start the broadcast immediately on page open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BroadcastCallBloc>().add(const BroadcastStart());
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  String _formatElapsed(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _onAccepted(BuildContext context, BroadcastAccepted state) {
    final callBloc = sl<CallBloc>();
    callBloc.add(JoinBroadcastCall(
      appointmentId: state.appointmentId,
      appId: state.appId,
      token: state.token,
      channelName: state.channelName,
      uid: state.uid,
      ratePerMinute: state.ratePerMinute,
      freeMinutes: state.freeMinutes,
      walletBalance: state.walletBalance,
      psychologistName: state.psychologistName,
      psychologistAvatar: state.psychologistAvatar,
    ));

    final payload = CallRoutePayload.fromBroadcast(
      appointmentId: state.appointmentId,
      psychologistName: state.psychologistName,
      psychologistAvatar: state.psychologistAvatar,
      ratePerMinute: state.ratePerMinute,
      freeMinutes: state.freeMinutes,
    );

    context.pushReplacement(
      RouteNames.activeCall,
      extra: {'payload': payload, 'callBloc': callBloc},
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BroadcastCallBloc, BroadcastState>(
      listenWhen: (_, current) =>
          current is BroadcastAccepted ||
          current is BroadcastTimeout ||
          current is BroadcastCancelled ||
          current is BroadcastError,
      listener: (context, state) {
        if (state is BroadcastAccepted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _onAccepted(context, state);
          });
        } else if (state is BroadcastTimeout) {
          _showDialog(
            context,
            title: 'No Therapist Available',
            message:
                'No psychologist accepted your call within 60 seconds. '
                'Please try again in a moment.',
            onOk: () => context.go(RouteNames.userHome),
          );
        } else if (state is BroadcastCancelled) {
          context.go(RouteNames.userHome);
        } else if (state is BroadcastError) {
          AppSnackbar.show(
            context,
            message: state.message,
            type: SnackbarType.error,
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.go(RouteNames.userHome);
          });
        }
      },
      builder: (context, state) {
        final elapsedSeconds =
            state is BroadcastWaiting ? state.elapsedSeconds : 0;
        final notified =
            state is BroadcastWaiting ? state.notifiedPsychologists : 0;
        final isLoading = state is BroadcastIdle;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A1A),
          body: SafeArea(
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => context
                          .read<BroadcastCallBloc>()
                          .add(const BroadcastCancel()),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    const Spacer(),
                    if (!isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9500).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFFF9500).withOpacity(0.4)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.bolt_rounded,
                              color: Color(0xFFFF9500), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _formatElapsed(elapsedSeconds),
                            style: const TextStyle(
                              color: Color(0xFFFF9500),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ]),
                      ),
                  ]),
                ),

                const Spacer(),

                // ── Radar animation ─────────────────────────────────────────
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(alignment: Alignment.center, children: [
                    ...[_ring1, _ring2, _ring3].map((anim) => AnimatedBuilder(
                          animation: anim,
                          builder: (_, __) => Opacity(
                            opacity: (1 - anim.value).clamp(0.0, 1.0),
                            child: Container(
                              width: 80 + anim.value * 160,
                              height: 80 + anim.value * 160,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color:
                                        const Color(0xFF5E5CE6).withOpacity(0.4),
                                    width: 1.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        )),
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5E5CE6), Color(0xFF8B7CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5E5CE6).withOpacity(
                                  0.2 + _pulseCtrl.value * 0.3),
                              blurRadius: 30 + _pulseCtrl.value * 20,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : const Icon(Icons.radio_rounded,
                                color: Colors.white, size: 44),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 28),
                Text(
                  isLoading ? 'Connecting...' : 'Broadcasting...',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isLoading
                      ? 'Initialising instant call'
                      : 'Connecting to the first available therapist',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                ),

                if (!isLoading && notified > 0) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34C759).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF34C759).withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.notifications_active_rounded,
                          color: Color(0xFF34C759), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '$notified therapist${notified == 1 ? '' : 's'} notified',
                        style: const TextStyle(
                          color: Color(0xFF34C759),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  ),
                ],

                const Spacer(),

                // ── Cancel button ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
                  child: GestureDetector(
                    onTap: () => context
                        .read<BroadcastCallBloc>()
                        .add(const BroadcastCancel()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close_rounded,
                                color: Colors.white70, size: 18),
                            SizedBox(width: 8),
                            Text('Cancel Broadcast',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                          ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onOk,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 18)),
        content: Text(message,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onOk();
            },
            child: const Text('OK',
                style: TextStyle(color: Color(0xFF5E5CE6))),
          ),
        ],
      ),
    );
  }
}
