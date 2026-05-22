import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/utils/currency_utils.dart';
import '../../../../../core/utils/json_readers.dart';
import '../../data/agora/agora_call_engine.dart';
import '../../data/models/call_models.dart';
import '../../data/repositories/call_repository.dart';
import '../../data/socket/call_socket_manager.dart';
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

/// Joins an Agora channel directly from broadcast-accepted credentials —
/// skips the API initiation step since the BroadcastCallBloc already handled
/// `POST /calls/broadcast-instant` and received `call:accepted` from the
/// socket.  This event is fired immediately after navigating to ActiveCallScreen.
class JoinBroadcastCall extends CallEvent {
  final String appointmentId;
  final String appId;
  final String token;
  final String channelName;
  final int uid;
  final double ratePerMinute;
  final int freeMinutes;
  final double walletBalance;
  final String psychologistName;
  final String? psychologistAvatar;
  final bool enableVideo;

  const JoinBroadcastCall({
    required this.appointmentId,
    required this.appId,
    required this.token,
    required this.channelName,
    required this.uid,
    required this.ratePerMinute,
    required this.freeMinutes,
    this.walletBalance = 0,
    required this.psychologistName,
    this.psychologistAvatar,
    this.enableVideo = true,
  });

  @override
  List<Object?> get props => [appointmentId, channelName, token];
}

// ─── Private internal events ─────────────────────────────────────────────────

/// Fired when the psychologist accepts the call. Carries the raw socket payload
/// containing Agora credentials.
class _CallAccepted extends CallEvent {
  final Map<String, dynamic> payload;
  const _CallAccepted(this.payload);
  @override
  List<Object?> get props => [payload];
}

/// Fired when the psychologist declines the call.
class _CallRejected extends CallEvent {
  final String reason;
  const _CallRejected(this.reason);
  @override
  List<Object?> get props => [reason];
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
  final CallSocketManager _callSocketManager;

  Timer? _timer;
  Timer? _heartbeatTimer;
  StreamSubscription<Map<String, dynamic>>? _socketSub;

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
    required CallSocketManager callSocketManager,
  })  : _callRepository = callRepository,
        _agoraCallEngine = agoraCallEngine,
        _callSocketManager = callSocketManager,
        super(const CallInitial()) {
    on<InitiateCall>(_onInitiate);
    on<JoinBroadcastCall>(_onJoinBroadcast);
    on<_CallAccepted>(_onCallAccepted);
    on<_CallRejected>(_onCallRejected);
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
      // Broadcast-initiate ONLY — notifies the psychologist and opens the
      // call slot.  Do NOT call /initiate or /connect; those are the old
      // self-service flow that bypasses the accept/reject step.
      final broadcast =
          await _callRepository.broadcastInitiateCall(appointmentId);

      _ratePerMinute = broadcast.ratePerMinute > 0
          ? broadcast.ratePerMinute
          : _ratePerMinute;
      _freeMinutes =
          broadcast.freeMinutes > 0 ? broadcast.freeMinutes : _freeMinutes;

      // Connect to the /call socket namespace and listen for the psychologist
      // to accept (call:accepted) or decline (call:rejected).
      await _callSocketManager.connect();
      _socketSub =
          _callSocketManager.eventStream.listen(_handleSocketEvent);
    } catch (error) {
      emit(CallErrorState(error.toString()));
    }
  }

  /// Routes incoming socket events to the appropriate internal BLoC event.
  void _handleSocketEvent(Map<String, dynamic> event) {
    final name = event['event'] as String? ?? '';
    final payload = JsonReaders.asMap(event['payload']);
    if (name == 'call:accepted') {
      if (!isClosed) add(_CallAccepted(payload));
    } else if (name == 'call:rejected') {
      if (!isClosed) {
        add(const _CallRejected('The psychologist declined the call.'));
      }
    }
  }

  /// Directly joins an Agora channel from broadcast-accepted credentials.
  /// Called when the user navigates to [ActiveCallScreen] after the
  /// [BroadcastCallBloc] received the `call:accepted` socket event.
  Future<void> _onJoinBroadcast(
    JoinBroadcastCall event,
    Emitter<CallState> emit,
  ) async {
    _appointmentId = event.appointmentId;
    _psychologistName = event.psychologistName;
    _psychologistAvatar = event.psychologistAvatar;
    _ratePerMinute = event.ratePerMinute > 0 ? event.ratePerMinute : _ratePerMinute;
    _freeMinutes = event.freeMinutes > 0 ? event.freeMinutes : _freeMinutes;
    _walletBalance = event.walletBalance;
    _walletDepleted = false;
    _isVideoEnabled = event.enableVideo;

    emit(CallConnecting(
      psychologistName: _psychologistName,
      psychologistAvatar: _psychologistAvatar,
    ));

    try {
      final appId = event.appId.isNotEmpty ? event.appId : AppConfig.agoraAppId;

      if (appId.isEmpty) throw Exception('Agora App ID missing.');
      if (event.token.isEmpty) throw Exception('Agora token missing.');
      if (event.channelName.isEmpty) throw Exception('Agora channel name missing.');

      await _agoraCallEngine.initialize(
        appId: appId,
        eventHandler: RtcEngineEventHandler(
          onError: (error, message) {
            debugPrint('Agora error (broadcast): $error - $message');
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            if (!isClosed) add(RemoteParticipantJoined(remoteUid));
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (!isClosed) add(RemoteParticipantLeft(remoteUid));
          },
        ),
      );

      await _agoraCallEngine.joinChannel(
        token: event.token,
        channelName: event.channelName,
        uid: event.uid,
        enableVideo: _isVideoEnabled,
      );

      _channelName = event.channelName;
      if (!isClosed) add(const CallConnected());
    } catch (error) {
      emit(CallErrorState(error.toString()));
    }
  }

  /// Handles psychologist accepting — parses Agora credentials from the socket
  /// payload, initialises the engine, joins the channel, then emits [CallActive].
  Future<void> _onCallAccepted(
      _CallAccepted event, Emitter<CallState> emit) async {
    try {
      await _socketSub?.cancel();
      _socketSub = null;

      final payload = event.payload;

      // Support nested agora sub-map or flat payload (same aliases as backend).
      final agora = JsonReaders.asMap(
        JsonReaders.readAny(payload, ['agora', 'rtc', 'connection']),
      );

      String resolve(List<String> agoraKeys, List<String> rootKeys) {
        final v = JsonReaders.readString(agora, agoraKeys);
        if (v.isNotEmpty) return v;
        return JsonReaders.readString(payload, rootKeys);
      }

      final appId = _pickNonEmpty([
        resolve(['appId', 'agoraAppId'], ['appId', 'agoraAppId']),
        AppConfig.agoraAppId,
      ]);
      final token =
          resolve(['token', 'agoraToken'], ['token', 'agoraToken']);
      final channel = resolve(
        ['channelName', 'channelId'],
        ['channelName', 'channelId', 'agoraChannel'],
      );
      int uid = JsonReaders.readInt(agora, ['uid']);
      if (uid == 0) uid = JsonReaders.readInt(payload, ['uid', 'agoraUid']);

      if (appId.isEmpty) {
        throw Exception('Agora App ID missing in call:accepted event.');
      }
      if (token.isEmpty) {
        throw Exception('Agora token missing in call:accepted event.');
      }
      if (channel.isEmpty) {
        throw Exception('Agora channel name missing in call:accepted event.');
      }

      // Refresh billing metadata if the accepted event carries fresher values.
      final rate =
          JsonReaders.readDouble(payload, ['ratePerMinute', 'rate']);
      if (rate > 0) _ratePerMinute = rate;
      final free = JsonReaders.readInt(payload, ['freeMinutes']);
      if (free > 0) _freeMinutes = free;

      await _agoraCallEngine.initialize(
        appId: appId,
        eventHandler: RtcEngineEventHandler(
          onError: (error, message) {
            debugPrint('Agora error: $error - $message');
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            if (!isClosed) add(RemoteParticipantJoined(remoteUid));
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (!isClosed) add(RemoteParticipantLeft(remoteUid));
          },
        ),
      );

      await _agoraCallEngine.joinChannel(
        token: token,
        channelName: channel,
        uid: uid,
        enableVideo: _isVideoEnabled,
      );

      _channelName = channel;
      if (!isClosed) add(const CallConnected());
    } catch (error) {
      emit(CallErrorState(error.toString()));
    }
  }

  void _onCallRejected(_CallRejected event, Emitter<CallState> emit) {
    emit(CallErrorState(event.reason));
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
    // Cancel socket subscription if the user cancels before accepting.
    await _socketSub?.cancel();
    _socketSub = null;
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
    await _socketSub?.cancel();
    _callSocketManager.disconnect();
    await _agoraCallEngine.dispose();
    return super.close();
  }
}

