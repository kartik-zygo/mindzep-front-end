import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/utils/currency_utils.dart';
import '../../data/agora/agora_call_engine.dart';
import '../../data/models/call_models.dart';
import '../../data/repositories/call_repository.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class CallEvent extends Equatable {
  const CallEvent();
  @override
  List<Object?> get props => [];
}

class InitiateCall extends CallEvent {
  final String appointmentId;
  final String psychologistId;
  final String? psychologistName;
  final String? psychologistAvatar;
  final bool enableVideo;
  final double walletBalance;

  const InitiateCall({
    required this.appointmentId,
    required this.psychologistId,
    this.psychologistName,
    this.psychologistAvatar,
    this.enableVideo = true,
    this.walletBalance = 0,
  });

  @override
  List<Object?> get props => [
        appointmentId,
        psychologistId,
        psychologistName,
        psychologistAvatar,
        enableVideo,
        walletBalance,
      ];
}

class CallConnected extends CallEvent {
  const CallConnected();
}

class TimerTick extends CallEvent {
  final int elapsedSeconds;
  const TimerTick(this.elapsedSeconds);
  @override
  List<Object?> get props => [elapsedSeconds];
}

class EndCall extends CallEvent {
  const EndCall();
}

class ToggleMute extends CallEvent {
  const ToggleMute();
}

class ToggleVideo extends CallEvent {
  const ToggleVideo();
}

class ToggleSpeaker extends CallEvent {
  const ToggleSpeaker();
}

class RemoteParticipantJoined extends CallEvent {
  final int uid;
  const RemoteParticipantJoined(this.uid);

  @override
  List<Object?> get props => [uid];
}

class RemoteParticipantLeft extends CallEvent {
  final int uid;
  const RemoteParticipantLeft(this.uid);

  @override
  List<Object?> get props => [uid];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class CallState extends Equatable {
  const CallState();
  @override
  List<Object?> get props => [];
}

class CallInitial extends CallState {
  const CallInitial();
}

class CallConnecting extends CallState {
  final String psychologistName;
  final String? psychologistAvatar;
  const CallConnecting(
      {required this.psychologistName, this.psychologistAvatar});
  @override
  List<Object?> get props => [psychologistName, psychologistAvatar];
}

class CallActive extends CallState {
  final String psychologistName;
  final String? psychologistAvatar;
  final int elapsedSeconds;
  final bool isMuted;
  final bool isVideoOff;
  final bool isSpeakerOn;
  final double chargeAmount;
  final bool isFreePhase;
  final int? remoteUid;
  final String channelName;

  const CallActive({
    required this.psychologistName,
    this.psychologistAvatar,
    required this.elapsedSeconds,
    this.isMuted = false,
    this.isVideoOff = false,
    this.isSpeakerOn = true,
    this.chargeAmount = 0,
    this.isFreePhase = true,
    this.remoteUid,
    this.channelName = '',
  });

  CallActive copyWith({
    int? elapsedSeconds,
    bool? isMuted,
    bool? isVideoOff,
    bool? isSpeakerOn,
    double? chargeAmount,
    bool? isFreePhase,
    int? remoteUid,
    bool clearRemoteUid = false,
    String? channelName,
  }) =>
      CallActive(
        psychologistName: psychologistName,
        psychologistAvatar: psychologistAvatar,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        isMuted: isMuted ?? this.isMuted,
        isVideoOff: isVideoOff ?? this.isVideoOff,
        isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
        chargeAmount: chargeAmount ?? this.chargeAmount,
        isFreePhase: isFreePhase ?? this.isFreePhase,
        remoteUid: clearRemoteUid ? null : (remoteUid ?? this.remoteUid),
        channelName: channelName ?? this.channelName,
      );

  @override
  List<Object?> get props => [
        elapsedSeconds,
        isMuted,
        isVideoOff,
        isSpeakerOn,
        chargeAmount,
        isFreePhase,
        remoteUid,
        channelName,
      ];
}

class CallEnded extends CallState {
  final int totalSeconds;
  final double totalCharge;
  final String psychologistName;
  const CallEnded({
    required this.totalSeconds,
    required this.totalCharge,
    required this.psychologistName,
  });
  @override
  List<Object?> get props => [totalSeconds, totalCharge, psychologistName];
}

class WalletExhausted extends CallEnded {
  const WalletExhausted({
    required super.totalSeconds,
    required super.totalCharge,
    required super.psychologistName,
  });
}

class CallErrorState extends CallState {
  final String message;

  const CallErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class CallBloc extends Bloc<CallEvent, CallState> {
  final CallRepository _callRepository;
  final AgoraCallEngine _agoraCallEngine;

  Timer? _timer;
  Timer? _heartbeatTimer;

  String? _appointmentId;
  String _psychologistName = 'Psychologist';
  String? _psychologistAvatar;

  int _elapsedSeconds = 0;
  double _ratePerMinute = 10.0;
  int _freeMinutes = 2;
  double _walletBalance = 0;
  bool _walletDepleted = false;
  String _channelName = '';
  bool _isVideoEnabled = true;

  CallBloc({
    required CallRepository callRepository,
    required AgoraCallEngine agoraCallEngine,
  })  : _callRepository = callRepository,
        _agoraCallEngine = agoraCallEngine,
        super(const CallInitial()) {
    on<InitiateCall>(_onInitiate);
    on<CallConnected>(_onConnected);
    on<TimerTick>(_onTick);
    on<EndCall>(_onEndCall);
    on<ToggleMute>(_onToggleMute);
    on<ToggleVideo>(_onToggleVideo);
    on<ToggleSpeaker>(_onToggleSpeaker);
    on<RemoteParticipantJoined>(_onRemoteParticipantJoined);
    on<RemoteParticipantLeft>(_onRemoteParticipantLeft);
  }

  AgoraCallEngine get agoraCallEngine => _agoraCallEngine;

  Future<void> _onInitiate(
      InitiateCall event, Emitter<CallState> emit) async {
    final appointmentId = event.appointmentId.trim();
    if (appointmentId.isEmpty) {
      emit(const CallErrorState(
          'A valid appointment is required to start a call.'));
      return;
    }

    _appointmentId = appointmentId;
    _psychologistName = event.psychologistName ?? 'Psychologist';
    _psychologistAvatar = event.psychologistAvatar;
    _isVideoEnabled = event.enableVideo;
    _walletBalance = event.walletBalance;
    _walletDepleted = false;

    emit(CallConnecting(
      psychologistName: _psychologistName,
      psychologistAvatar: _psychologistAvatar,
    ));

    try {
      final initiatedCall =
        await _callRepository.initiateCall(appointmentId);
      final connectedCall = await _callRepository.connectCall(appointmentId);

      _appointmentId = connectedCall.appointmentId.trim().isNotEmpty
        ? connectedCall.appointmentId
        : initiatedCall.appointmentId;

      _ratePerMinute = connectedCall.ratePerMinute > 0
          ? connectedCall.ratePerMinute
          : initiatedCall.ratePerMinute;
      _freeMinutes = connectedCall.freeMinutes > 0
          ? connectedCall.freeMinutes
          : initiatedCall.freeMinutes;

      await _joinAgoraIfAvailable(
        initiatedCall,
        connectedCall,
        enableVideo: event.enableVideo,
      );

      if (!isClosed) {
        add(const CallConnected());
      }
    } catch (error) {
      emit(CallErrorState(error.toString()));
    }
  }

  void _onRemoteParticipantJoined(
    RemoteParticipantJoined event,
    Emitter<CallState> emit,
  ) {
    final current = state;
    if (current is! CallActive) return;
    emit(current.copyWith(remoteUid: event.uid));
  }

  void _onRemoteParticipantLeft(
    RemoteParticipantLeft event,
    Emitter<CallState> emit,
  ) {
    final current = state;
    if (current is! CallActive) return;
    if (current.remoteUid != event.uid) return;
    emit(current.copyWith(clearRemoteUid: true));
  }

  void _onConnected(CallConnected event, Emitter<CallState> emit) {
    final current = state;
    if (current is! CallConnecting && current is! CallErrorState) return;

    final psychologistName = current is CallConnecting
        ? current.psychologistName
        : _psychologistName;
    final psychologistAvatar = current is CallConnecting
        ? current.psychologistAvatar
        : _psychologistAvatar;

    _elapsedSeconds = 0;
    emit(CallActive(
      psychologistName: psychologistName,
      psychologistAvatar: psychologistAvatar,
      elapsedSeconds: 0,
      isVideoOff: !_isVideoEnabled,
      channelName: _channelName,
    ));
    _startTimer();
    _startHeartbeat();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      if (!isClosed) add(TimerTick(_elapsedSeconds));
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final appointmentId = _appointmentId;
      if (appointmentId == null) return;

      try {
        await _callRepository.sendHeartbeat(
          appointmentId,
          CallHeartbeatRequest(durationSeconds: _elapsedSeconds),
        );
      } catch (_) {
        // Heartbeat failures are non-blocking for active UI.
      }
    });
  }

  void _onTick(TimerTick event, Emitter<CallState> emit) {
    if (state is! CallActive) return;
    final current = state as CallActive;
    final billedSecs = CurrencyUtils.billedSeconds(
      totalSeconds: event.elapsedSeconds,
      freeMinutes: _freeMinutes,
    );
    final charge = billedSecs > 0 ? (_ratePerMinute / 60.0) * billedSecs : 0.0;
    final isFreePhase = event.elapsedSeconds < (_freeMinutes * 60);

    // Auto-end call when wallet balance is fully consumed
    if (_walletBalance > 0 && !isFreePhase && charge >= _walletBalance && !_walletDepleted) {
      _walletDepleted = true;
      if (!isClosed) add(const EndCall());
      return;
    }

    emit(current.copyWith(
      elapsedSeconds: event.elapsedSeconds,
      chargeAmount: charge,
      isFreePhase: isFreePhase,
    ));
  }

  Future<void> _onEndCall(EndCall event, Emitter<CallState> emit) async {
    _timer?.cancel();
    _heartbeatTimer?.cancel();

    final appointmentId = _appointmentId;
    final current = state;

    if (current is CallActive) {
      if (appointmentId != null) {
        try {
          await _callRepository.endCall(
            appointmentId,
            CallEndRequest(durationSeconds: current.elapsedSeconds),
          );
        } catch (_) {
          // Backend end-call failure is tolerated; UI still exits call.
        }
      }

      await _agoraCallEngine.leaveChannel();

      if (_walletDepleted) {
        emit(WalletExhausted(
          totalSeconds: current.elapsedSeconds,
          totalCharge: current.chargeAmount,
          psychologistName: current.psychologistName,
        ));
      } else {
        emit(CallEnded(
          totalSeconds: current.elapsedSeconds,
          totalCharge: current.chargeAmount,
          psychologistName: current.psychologistName,
        ));
      }
    }
  }

  void _onToggleMute(ToggleMute event, Emitter<CallState> emit) {
    if (state is CallActive) {
      final s = state as CallActive;
      unawaited(_agoraCallEngine.muteLocalAudio(!s.isMuted));
      emit(s.copyWith(isMuted: !s.isMuted));
    }
  }

  void _onToggleVideo(ToggleVideo event, Emitter<CallState> emit) {
    if (state is CallActive) {
      final s = state as CallActive;
      unawaited(_agoraCallEngine.muteLocalVideo(!s.isVideoOff));
      emit(s.copyWith(isVideoOff: !s.isVideoOff));
    }
  }

  void _onToggleSpeaker(ToggleSpeaker event, Emitter<CallState> emit) {
    if (state is CallActive) {
      final s = state as CallActive;
      unawaited(_agoraCallEngine.setSpeakerphone(!s.isSpeakerOn));
      emit(s.copyWith(isSpeakerOn: !s.isSpeakerOn));
    }
  }

  Future<void> _joinAgoraIfAvailable(
    CallRuntimeModel initiated,
    CallRuntimeModel connected,
    {required bool enableVideo}
  ) async {
    final appId = _pickNonEmpty([
      connected.appId,
      initiated.appId,
      AppConfig.agoraAppId,
    ]);

    final token = _pickNonEmpty([connected.token, initiated.token]);
    final channel = _pickNonEmpty([
      connected.channelName,
      initiated.channelName,
    ]);

    if (appId.isEmpty || token.isEmpty || channel.isEmpty) {
      return;
    }

    await _agoraCallEngine.initialize(
      appId: appId,
      eventHandler: RtcEngineEventHandler(
        onError: (error, message) {
          debugPrint('Agora error: $error - $message');
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (!isClosed) {
            add(RemoteParticipantJoined(remoteUid));
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (!isClosed) {
            add(RemoteParticipantLeft(remoteUid));
          }
        },
      ),
    );

    await _agoraCallEngine.joinChannel(
      token: token,
      channelName: channel,
      uid: connected.uid,
      enableVideo: enableVideo,
    );

    _channelName = channel;
  }

  String _pickNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    _heartbeatTimer?.cancel();
    await _agoraCallEngine.dispose();
    return super.close();
  }
}

