import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../user/call/data/agora/agora_call_engine.dart';
import '../../../../user/call/data/models/call_models.dart';
import '../../../../user/call/data/repositories/call_repository.dart';
import '../../data/models/incoming_call_data.dart';
import '../../data/socket/psych_call_socket_service.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class PsychCallEvent extends Equatable {
  const PsychCallEvent();
  @override
  List<Object?> get props => [];
}

/// Fired by [PsychActiveCallScreen] after the psychologist accepts a call.
class PsychStartCall extends PsychCallEvent {
  final IncomingCallData callData;
  final bool enableVideo;

  const PsychStartCall({required this.callData, this.enableVideo = true});

  @override
  List<Object?> get props => [callData.appointmentId, enableVideo];
}

class _PsychCallConnected extends PsychCallEvent {
  const _PsychCallConnected();
}

class PsychTimerTick extends PsychCallEvent {
  final int elapsedSeconds;
  const PsychTimerTick(this.elapsedSeconds);
  @override
  List<Object?> get props => [elapsedSeconds];
}

class PsychEndCall extends PsychCallEvent {
  const PsychEndCall();
}

class PsychToggleMute extends PsychCallEvent {
  const PsychToggleMute();
}

class PsychToggleVideo extends PsychCallEvent {
  const PsychToggleVideo();
}

class PsychToggleSpeaker extends PsychCallEvent {
  const PsychToggleSpeaker();
}

class PsychRemoteJoined extends PsychCallEvent {
  final int uid;
  const PsychRemoteJoined(this.uid);
  @override
  List<Object?> get props => [uid];
}

class PsychRemoteLeft extends PsychCallEvent {
  final int uid;
  const PsychRemoteLeft(this.uid);
  @override
  List<Object?> get props => [uid];
}

/// A heartbeat response arrived (server may have force-ended the call).
class _PsychHeartbeatArrived extends PsychCallEvent {
  final CallHeartbeatResponse response;
  const _PsychHeartbeatArrived(this.response);
  @override
  List<Object?> get props => [response];
}

/// `call:force-end` socket event — the server already terminated the call.
class _PsychForceEndReceived extends PsychCallEvent {
  final CallForceEndEvent payload;
  const _PsychForceEndReceived(this.payload);
  @override
  List<Object?> get props => [payload];
}

/// `call:low-balance` socket event — user is about to run out of talk time.
class _PsychLowBalanceReceived extends PsychCallEvent {
  final CallLowBalanceEvent payload;
  const _PsychLowBalanceReceived(this.payload);
  @override
  List<Object?> get props => [payload];
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class PsychCallState extends Equatable {
  const PsychCallState();
  @override
  List<Object?> get props => [];
}

class PsychCallIdle extends PsychCallState {
  const PsychCallIdle();
}

class PsychCallConnecting extends PsychCallState {
  final String userName;
  const PsychCallConnecting(this.userName);
  @override
  List<Object?> get props => [userName];
}

class PsychCallActive extends PsychCallState {
  final String userName;
  final String? userAvatar;
  final int elapsedSeconds;
  final bool isMuted;
  final bool isVideoOff;
  final bool isSpeakerOn;
  final int? remoteUid;
  final String channelName;

  /// True when the server warned that the user's balance is running low —
  /// the call may end shortly.
  final bool userLowBalance;

  const PsychCallActive({
    required this.userName,
    this.userAvatar,
    required this.elapsedSeconds,
    this.isMuted = false,
    this.isVideoOff = false,
    this.isSpeakerOn = true,
    this.remoteUid,
    this.channelName = '',
    this.userLowBalance = false,
  });

  PsychCallActive copyWith({
    int? elapsedSeconds,
    bool? isMuted,
    bool? isVideoOff,
    bool? isSpeakerOn,
    int? remoteUid,
    bool clearRemoteUid = false,
    String? channelName,
    bool? userLowBalance,
  }) =>
      PsychCallActive(
        userName: userName,
        userAvatar: userAvatar,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        isMuted: isMuted ?? this.isMuted,
        isVideoOff: isVideoOff ?? this.isVideoOff,
        isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
        remoteUid: clearRemoteUid ? null : (remoteUid ?? this.remoteUid),
        channelName: channelName ?? this.channelName,
        userLowBalance: userLowBalance ?? this.userLowBalance,
      );

  @override
  List<Object?> get props => [
        elapsedSeconds,
        isMuted,
        isVideoOff,
        isSpeakerOn,
        remoteUid,
        channelName,
        userLowBalance,
      ];
}

class PsychCallEnded extends PsychCallState {
  final int totalSeconds;
  final String userName;

  /// user_ended | wallet_exhausted | heartbeat_timeout
  final String endReason;

  /// Display copy for the end screen (e.g. wallet exhaustion explanation).
  final String? message;

  const PsychCallEnded({
    required this.totalSeconds,
    required this.userName,
    this.endReason = 'user_ended',
    this.message,
  });

  @override
  List<Object?> get props => [totalSeconds, userName, endReason, message];
}

class PsychCallError extends PsychCallState {
  final String message;
  const PsychCallError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class PsychCallBloc extends Bloc<PsychCallEvent, PsychCallState> {
  static const Duration _heartbeatInterval = Duration(seconds: 20);

  final CallRepository _callRepository;
  final AgoraCallEngine _agoraCallEngine;
  final PsychCallSocketService _socketService;

  Timer? _timer;
  Timer? _heartbeatTimer;
  StreamSubscription<CallForceEndEvent>? _forceEndSub;
  StreamSubscription<CallLowBalanceEvent>? _lowBalanceSub;

  int _elapsedSeconds = 0;
  String? _appointmentId;
  String _userName = 'User';
  String? _userAvatar;
  String _channelName = '';

  /// Set the moment any end path wins (psych end / force-end socket /
  /// heartbeat callEnded). All other end paths become no-ops.
  bool _isFinalizing = false;

  PsychCallBloc({
    required CallRepository callRepository,
    required AgoraCallEngine agoraCallEngine,
    required PsychCallSocketService socketService,
  })  : _callRepository = callRepository,
        _agoraCallEngine = agoraCallEngine,
        _socketService = socketService,
        super(const PsychCallIdle()) {
    on<PsychStartCall>(_onStartCall);
    on<_PsychCallConnected>(_onConnected);
    on<PsychTimerTick>(_onTick);
    on<PsychEndCall>(_onEndCall);
    on<_PsychHeartbeatArrived>(_onHeartbeatArrived);
    on<_PsychForceEndReceived>(_onForceEndReceived);
    on<_PsychLowBalanceReceived>(_onLowBalanceReceived);
    on<PsychToggleMute>(_onToggleMute);
    on<PsychToggleVideo>(_onToggleVideo);
    on<PsychToggleSpeaker>(_onToggleSpeaker);
    on<PsychRemoteJoined>(_onRemoteJoined);
    on<PsychRemoteLeft>(_onRemoteLeft);
  }

  AgoraCallEngine get agoraCallEngine => _agoraCallEngine;

  Future<void> _onStartCall(
    PsychStartCall event,
    Emitter<PsychCallState> emit,
  ) async {
    final callData = event.callData;
    _appointmentId = callData.appointmentId;
    _userName = callData.userName.isNotEmpty ? callData.userName : 'User';
    _userAvatar = callData.userAvatar;
    _isFinalizing = false;

    emit(PsychCallConnecting(_userName));

    try {
      // Notify the backend (and the user) that the psychologist accepted.
      // The response may carry updated Agora credentials.
      final acceptResult =
          await _callRepository.broadcastAcceptCall(callData.appointmentId);

      // Resolve Agora credentials — prefer server response, fall back to socket data.
      final appId = _pickNonEmpty([
        acceptResult.appId,
        callData.appId,
        AppConfig.agoraAppId,
      ]);
      final token =
          _pickNonEmpty([acceptResult.token, callData.token]);
      final channel = _pickNonEmpty([
        acceptResult.channelName,
        callData.channelName,
      ]);
      final uid =
          acceptResult.uid != 0 ? acceptResult.uid : callData.uid;

      if (appId.isEmpty) {
        throw Exception(
          'Agora App ID is not configured. '
          'Set AGORA_APP_ID in .env or ApiConstants.agoraAppId.',
        );
      }
      if (token.isEmpty) {
        throw Exception(
          'Agora token is empty — check broadcastAcceptCall response.',
        );
      }
      if (channel.isEmpty) {
        throw Exception(
          'Agora channel name is empty — check broadcastAcceptCall response.',
        );
      }

      await _agoraCallEngine.initialize(
          appId: appId,
          eventHandler: RtcEngineEventHandler(
            onError: (error, message) {
              debugPrint('[PsychCall] Agora error: $error - $message');
            },
            onUserJoined: (connection, remoteUid, elapsed) {
              if (!isClosed) add(PsychRemoteJoined(remoteUid));
            },
            onUserOffline: (connection, remoteUid, reason) {
              if (!isClosed) add(PsychRemoteLeft(remoteUid));
            },
          ),
        );

      await _agoraCallEngine.joinChannel(
          token: token,
          channelName: channel,
          uid: uid,
          enableVideo: event.enableVideo,
        );

      _channelName = channel;

      if (!isClosed) add(const _PsychCallConnected());
    } catch (error) {
      emit(PsychCallError(error.toString()));
    }
  }

  void _onConnected(
    _PsychCallConnected event,
    Emitter<PsychCallState> emit,
  ) {
    _elapsedSeconds = 0;

    // Join the per-appointment call room and start watching for server-side
    // billing events (force-end / low-balance).
    final appointmentId = _appointmentId ?? '';
    if (appointmentId.isNotEmpty) {
      _socketService.joinCallRoom(appointmentId);
    }
    _forceEndSub?.cancel();
    _forceEndSub = _socketService.onForceEnd.listen((payload) {
      if (isClosed) return;
      if (!_isForThisCall(payload.appointmentId)) return;
      add(_PsychForceEndReceived(payload));
    });
    _lowBalanceSub?.cancel();
    _lowBalanceSub = _socketService.onLowBalance.listen((payload) {
      if (isClosed) return;
      if (!_isForThisCall(payload.appointmentId)) return;
      add(_PsychLowBalanceReceived(payload));
    });

    emit(PsychCallActive(
      userName: _userName,
      userAvatar: _userAvatar,
      elapsedSeconds: 0,
      channelName: _channelName,
    ));
    _startTimer();
    _startHeartbeat();
  }

  bool _isForThisCall(String eventAppointmentId) {
    final current = _appointmentId ?? '';
    if (current.isEmpty || eventAppointmentId.isEmpty) return true;
    return current == eventAppointmentId;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      if (!isClosed) add(PsychTimerTick(_elapsedSeconds));
    });
  }

  // ── Heartbeat loop — keeps the call alive AND learns about force-ends ─────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _sendHeartbeat(); // first beat immediately on join
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _sendHeartbeat();
    });
  }

  Future<void> _sendHeartbeat() async {
    final appointmentId = _appointmentId;
    if (appointmentId == null || _isFinalizing) return;

    try {
      final response = await _callRepository.sendHeartbeat(
        appointmentId,
        CallHeartbeatRequest(durationSeconds: _elapsedSeconds),
      );
      if (kDebugMode) {
        debugPrint(
            '[PsychCall] heartbeat → ended=${response.callEnded} ${response.billing ?? '(no billing yet)'}');
      }
      if (!isClosed) add(_PsychHeartbeatArrived(response));
    } catch (error) {
      if (kDebugMode) debugPrint('[PsychCall] heartbeat failed: $error');
    }
  }

  Future<void> _onHeartbeatArrived(
    _PsychHeartbeatArrived event,
    Emitter<PsychCallState> emit,
  ) async {
    final response = event.response;

    if (response.callEnded) {
      await _finalizeServerEndedCall(
        emit,
        reason: response.endReason ?? 'wallet_exhausted',
      );
      return;
    }

    final current = state;
    if (current is! PsychCallActive) return;

    final billing = response.billing;
    if (billing != null && current.userLowBalance != billing.lowBalance) {
      emit(current.copyWith(userLowBalance: billing.lowBalance));
    }
  }

  Future<void> _onForceEndReceived(
    _PsychForceEndReceived event,
    Emitter<PsychCallState> emit,
  ) async {
    await _finalizeServerEndedCall(emit, reason: event.payload.reason);
  }

  void _onLowBalanceReceived(
    _PsychLowBalanceReceived event,
    Emitter<PsychCallState> emit,
  ) {
    final current = state;
    if (current is! PsychCallActive) return;
    if (current.userLowBalance) return; // already shown — don't re-emit
    emit(current.copyWith(userLowBalance: true));
  }

  /// Shared teardown for server-side call termination — heartbeat `callEnded`
  /// or `call:force-end`, whichever arrives first wins; the second is a no-op.
  Future<void> _finalizeServerEndedCall(
    Emitter<PsychCallState> emit, {
    required String reason,
  }) async {
    if (_isFinalizing) return;
    _isFinalizing = true;

    _timer?.cancel();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    await _agoraCallEngine.leaveChannel();

    // No POST /calls/end here — the server already settled and ended the call.
    emit(PsychCallEnded(
      totalSeconds: _elapsedSeconds,
      userName: _userName,
      endReason: reason,
      message: reason == 'wallet_exhausted'
          ? "Call ended — user's wallet balance is exhausted."
          : null,
    ));
  }

  void _onTick(PsychTimerTick event, Emitter<PsychCallState> emit) {
    if (state is PsychCallActive) {
      emit((state as PsychCallActive)
          .copyWith(elapsedSeconds: event.elapsedSeconds));
    }
  }

  Future<void> _onEndCall(
    PsychEndCall event,
    Emitter<PsychCallState> emit,
  ) async {
    if (_isFinalizing) return;

    final current = state;
    if (current is! PsychCallActive) return;

    _isFinalizing = true;
    _timer?.cancel();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    CallEndResult? endResult;
    final appointmentId = _appointmentId;
    if (appointmentId != null) {
      try {
        endResult = await _callRepository.endCall(
          appointmentId,
          CallEndRequest(durationSeconds: current.elapsedSeconds),
        );
      } catch (_) {
        // End-call failure is tolerated; UI still exits the call.
      }
    }

    await _agoraCallEngine.leaveChannel();

    emit(PsychCallEnded(
      totalSeconds: endResult?.totalSeconds ?? current.elapsedSeconds,
      userName: current.userName,
      endReason: endResult?.endReason ?? 'user_ended',
    ));
  }

  void _onToggleMute(PsychToggleMute event, Emitter<PsychCallState> emit) {
    if (state is PsychCallActive) {
      final s = state as PsychCallActive;
      unawaited(_agoraCallEngine.muteLocalAudio(!s.isMuted));
      emit(s.copyWith(isMuted: !s.isMuted));
    }
  }

  void _onToggleVideo(PsychToggleVideo event, Emitter<PsychCallState> emit) {
    if (state is PsychCallActive) {
      final s = state as PsychCallActive;
      unawaited(_agoraCallEngine.muteLocalVideo(!s.isVideoOff));
      emit(s.copyWith(isVideoOff: !s.isVideoOff));
    }
  }

  void _onToggleSpeaker(
    PsychToggleSpeaker event,
    Emitter<PsychCallState> emit,
  ) {
    if (state is PsychCallActive) {
      final s = state as PsychCallActive;
      unawaited(_agoraCallEngine.setSpeakerphone(!s.isSpeakerOn));
      emit(s.copyWith(isSpeakerOn: !s.isSpeakerOn));
    }
  }

  void _onRemoteJoined(PsychRemoteJoined event, Emitter<PsychCallState> emit) {
    if (state is PsychCallActive) {
      emit((state as PsychCallActive).copyWith(remoteUid: event.uid));
    }
  }

  void _onRemoteLeft(PsychRemoteLeft event, Emitter<PsychCallState> emit) {
    if (state is PsychCallActive) {
      final s = state as PsychCallActive;
      if (s.remoteUid == event.uid) {
        emit(s.copyWith(clearRemoteUid: true));
      }
    }
  }

  String _pickNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _forceEndSub?.cancel();
    await _lowBalanceSub?.cancel();
    await _agoraCallEngine.dispose();
    return super.close();
  }
}
