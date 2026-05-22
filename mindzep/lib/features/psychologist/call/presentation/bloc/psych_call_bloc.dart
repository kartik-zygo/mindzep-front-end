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

  const PsychCallActive({
    required this.userName,
    this.userAvatar,
    required this.elapsedSeconds,
    this.isMuted = false,
    this.isVideoOff = false,
    this.isSpeakerOn = true,
    this.remoteUid,
    this.channelName = '',
  });

  PsychCallActive copyWith({
    int? elapsedSeconds,
    bool? isMuted,
    bool? isVideoOff,
    bool? isSpeakerOn,
    int? remoteUid,
    bool clearRemoteUid = false,
    String? channelName,
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
      );

  @override
  List<Object?> get props => [
        elapsedSeconds,
        isMuted,
        isVideoOff,
        isSpeakerOn,
        remoteUid,
        channelName,
      ];
}

class PsychCallEnded extends PsychCallState {
  final int totalSeconds;
  final String userName;

  const PsychCallEnded({required this.totalSeconds, required this.userName});

  @override
  List<Object?> get props => [totalSeconds, userName];
}

class PsychCallError extends PsychCallState {
  final String message;
  const PsychCallError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class PsychCallBloc extends Bloc<PsychCallEvent, PsychCallState> {
  final CallRepository _callRepository;
  final AgoraCallEngine _agoraCallEngine;

  Timer? _timer;
  int _elapsedSeconds = 0;
  String? _appointmentId;
  String _userName = 'User';
  String? _userAvatar;
  String _channelName = '';

  PsychCallBloc({
    required CallRepository callRepository,
    required AgoraCallEngine agoraCallEngine,
  })  : _callRepository = callRepository,
        _agoraCallEngine = agoraCallEngine,
        super(const PsychCallIdle()) {
    on<PsychStartCall>(_onStartCall);
    on<_PsychCallConnected>(_onConnected);
    on<PsychTimerTick>(_onTick);
    on<PsychEndCall>(_onEndCall);
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
    emit(PsychCallActive(
      userName: _userName,
      userAvatar: _userAvatar,
      elapsedSeconds: 0,
      channelName: _channelName,
    ));
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      if (!isClosed) add(PsychTimerTick(_elapsedSeconds));
    });
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
    _timer?.cancel();
    final current = state;

    if (current is PsychCallActive) {
      final appointmentId = _appointmentId;
      if (appointmentId != null) {
        try {
          await _callRepository.endCall(
            appointmentId,
            CallEndRequest(durationSeconds: current.elapsedSeconds),
          );
        } catch (_) {
          // End-call failure is tolerated; UI still exits the call.
        }
      }

      await _agoraCallEngine.leaveChannel();

      emit(PsychCallEnded(
        totalSeconds: current.elapsedSeconds,
        userName: current.userName,
      ));
    }
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
    await _agoraCallEngine.dispose();
    return super.close();
  }
}
