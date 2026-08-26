import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/network/api_error_model.dart';
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

/// A heartbeat response arrived (billing snapshot / server-side call end).
class _HeartbeatArrived extends CallEvent {
  final CallHeartbeatResponse response;
  const _HeartbeatArrived(this.response);
  @override
  List<Object?> get props => [response];
}

/// `call:force-end` socket event — the server already terminated the call.
class _ForceEndReceived extends CallEvent {
  final CallForceEndEvent payload;
  const _ForceEndReceived(this.payload);
  @override
  List<Object?> get props => [payload];
}

/// `call:low-balance` socket event — warn before the cutoff.
class _LowBalanceReceived extends CallEvent {
  final CallLowBalanceEvent payload;
  const _LowBalanceReceived(this.payload);
  @override
  List<Object?> get props => [payload];
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
  final int freeMinutes;

  /// True for prepaid appointments — the call carries no per-minute charge, so
  /// the UI hides all billing chips.
  final bool isPrepaid;

  /// Live billing snapshot from the latest heartbeat (null until the backend
  /// starts billing — e.g. before the call is connected server-side).
  final CallBillingSnapshot? billing;

  /// True while the low-balance warning banner should be visible.
  final bool showLowBalanceBanner;

  /// Server-provided low balance warning text (fallback copy applied in UI).
  final String? lowBalanceMessage;

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
    this.freeMinutes = 0,
    this.isPrepaid = false,
    this.billing,
    this.showLowBalanceBanner = false,
    this.lowBalanceMessage,
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
    int? freeMinutes,
    CallBillingSnapshot? billing,
    bool? showLowBalanceBanner,
    String? lowBalanceMessage,
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
        freeMinutes: freeMinutes ?? this.freeMinutes,
        isPrepaid: isPrepaid,
        billing: billing ?? this.billing,
        showLowBalanceBanner: showLowBalanceBanner ?? this.showLowBalanceBanner,
        lowBalanceMessage: lowBalanceMessage ?? this.lowBalanceMessage,
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
        freeMinutes,
        isPrepaid,
        billing?.walletBalance,
        billing?.remainingMinutes,
        billing?.chargedSoFar,
        billing?.freeSecondsLeft,
        billing?.lowBalance,
        showLowBalanceBanner,
        lowBalanceMessage,
      ];
}

class CallEnded extends CallState {
  final int totalSeconds;
  final double totalCharge;
  final String psychologistName;

  /// user_ended | wallet_exhausted | heartbeat_timeout
  final String endReason;

  /// Server-provided end message (e.g. wallet exhaustion copy).
  final String? message;

  /// Rupees already collected from the wallet during the call, when the
  /// /calls/end response includes billingBreakdown.paidFromWallet.
  final double? paidFromWallet;

  const CallEnded({
    required this.totalSeconds,
    required this.totalCharge,
    required this.psychologistName,
    this.endReason = 'user_ended',
    this.message,
    this.paidFromWallet,
  });

  @override
  List<Object?> get props =>
      [totalSeconds, totalCharge, psychologistName, endReason, message, paidFromWallet];
}

class WalletExhausted extends CallEnded {
  const WalletExhausted({
    required super.totalSeconds,
    required super.totalCharge,
    required super.psychologistName,
    super.message,
    super.paidFromWallet,
  }) : super(endReason: 'wallet_exhausted');
}

class CallErrorState extends CallState {
  final String message;

  const CallErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

/// Call start rejected with HTTP 402 INSUFFICIENT_WALLET_BALANCE.
class CallInsufficientBalance extends CallState {
  final InsufficientBalanceError error;

  const CallInsufficientBalance(this.error);

  @override
  List<Object?> get props =>
      [error.walletBalance, error.minimumRequired, error.message];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class CallBloc extends Bloc<CallEvent, CallState> {
  static const Duration _heartbeatInterval = Duration(seconds: 20);

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
  String _channelName = '';
  bool _isVideoEnabled = true;

  /// True when the appointment was paid upfront (prepaid). The backend then
  /// reports `ratePerMinute == 0`, bills nothing during the call, and the UI
  /// hides all per-minute / free-minute / talk-time billing chips.
  bool _isPrepaid = false;
  CallBillingSnapshot? _latestBilling;

  /// Set the moment any end path wins (user end / force-end socket /
  /// heartbeat callEnded). All other end paths become no-ops.
  bool _isFinalizing = false;

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
    on<_HeartbeatArrived>(_onHeartbeatArrived);
    on<_ForceEndReceived>(_onForceEndReceived);
    on<_LowBalanceReceived>(_onLowBalanceReceived);
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
    _isFinalizing = false;
    _latestBilling = null;

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

      // A prepaid appointment comes back with ratePerMinute == 0 (charged in
      // full at booking). Pay-as-you-go calls return a positive rate.
      _isPrepaid = broadcast.ratePerMinute <= 0;
      _ratePerMinute = broadcast.ratePerMinute > 0
          ? broadcast.ratePerMinute
          : _ratePerMinute;
      _freeMinutes =
          broadcast.freeMinutes > 0 ? broadcast.freeMinutes : _freeMinutes;

      // Connect to the /call socket namespace and listen for the psychologist
      // to accept (call:accepted) or decline (call:rejected). The same
      // subscription later carries call:force-end / call:low-balance.
      await _callSocketManager.connect();
      _socketSub ??=
          _callSocketManager.eventStream.listen(_handleSocketEvent);
    } on ApiErrorModel catch (error) {
      final insufficient = InsufficientBalanceError.tryParse(
        statusCode: error.statusCode,
        message: error.message,
        details: error.details,
      );
      if (insufficient != null) {
        emit(CallInsufficientBalance(insufficient));
      } else {
        emit(CallErrorState(error.message));
      }
    } catch (error) {
      emit(CallErrorState(error.toString()));
    }
  }

  /// Routes incoming socket events to the appropriate internal BLoC event.
  void _handleSocketEvent(Map<String, dynamic> event) {
    if (isClosed) return;
    final name = event['event'] as String? ?? '';
    final payload = JsonReaders.asMap(event['payload']);

    switch (name) {
      case 'call:accepted':
        add(_CallAccepted(payload));
        break;
      case 'call:rejected':
        add(const _CallRejected('The psychologist declined the call.'));
        break;
      case 'call:force-end':
        final parsed = CallForceEndEvent.fromJson(payload);
        if (_isForThisCall(parsed.appointmentId)) {
          if (kDebugMode) {
            debugPrint(
                '[CallBloc] call:force-end → reason=${parsed.reason}');
          }
          add(_ForceEndReceived(parsed));
        }
        break;
      case 'call:low-balance':
        final parsed = CallLowBalanceEvent.fromJson(payload);
        if (_isForThisCall(parsed.appointmentId)) {
          if (kDebugMode) {
            debugPrint(
                '[CallBloc] call:low-balance → ~${parsed.remainingMinutes} min left');
          }
          add(_LowBalanceReceived(parsed));
        }
        break;
    }
  }

  /// Force-end / low-balance are also emitted to the private user-id room, so
  /// an empty appointmentId on either side is treated as a match.
  bool _isForThisCall(String eventAppointmentId) {
    final current = _appointmentId ?? '';
    if (current.isEmpty || eventAppointmentId.isEmpty) return true;
    return current == eventAppointmentId;
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
    // Instant/broadcast calls are always pay-as-you-go (no upfront payment).
    _isPrepaid = false;
    _ratePerMinute = event.ratePerMinute > 0 ? event.ratePerMinute : _ratePerMinute;
    _freeMinutes = event.freeMinutes > 0 ? event.freeMinutes : _freeMinutes;
    _isVideoEnabled = event.enableVideo;
    _isFinalizing = false;
    _latestBilling = null;

    emit(CallConnecting(
      psychologistName: _psychologistName,
      psychologistAvatar: _psychologistAvatar,
    ));

    try {
      final appId = event.appId.isNotEmpty ? event.appId : AppConfig.agoraAppId;

      if (appId.isEmpty) throw Exception('Agora App ID missing.');
      if (event.token.isEmpty) throw Exception('Agora token missing.');
      if (event.channelName.isEmpty) throw Exception('Agora channel name missing.');

      // The /call socket may already be connected by the broadcast flow —
      // (re)connect and subscribe so force-end / low-balance reach this bloc.
      await _callSocketManager.connect();
      _socketSub ??=
          _callSocketManager.eventStream.listen(_handleSocketEvent);

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

    // Join the per-appointment call room so room-scoped billing events
    // (call:force-end / call:low-balance) are delivered immediately.
    final appointmentId = _appointmentId ?? '';
    if (appointmentId.isNotEmpty) {
      _callSocketManager.joinCallRoom(appointmentId);
    }

    _elapsedSeconds = 0;
    emit(CallActive(
      psychologistName: psychologistName,
      psychologistAvatar: psychologistAvatar,
      elapsedSeconds: 0,
      isVideoOff: !_isVideoEnabled,
      channelName: _channelName,
      freeMinutes: _freeMinutes,
      isPrepaid: _isPrepaid,
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

  // ── Heartbeat loop — single owner of the in-call billing lifecycle ────────

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
            '[CallBloc] heartbeat → ended=${response.callEnded} ${response.billing ?? '(no billing yet)'}');
      }
      if (!isClosed) add(_HeartbeatArrived(response));
    } catch (error) {
      // Heartbeat failures are non-blocking for the active UI; the next tick
      // retries, and the server-side sweeper protects against zombie calls.
      if (kDebugMode) debugPrint('[CallBloc] heartbeat failed: $error');
    }
  }

  Future<void> _onHeartbeatArrived(
    _HeartbeatArrived event,
    Emitter<CallState> emit,
  ) async {
    final response = event.response;

    if (response.callEnded) {
      await _finalizeServerEndedCall(
        emit,
        reason: response.endReason ?? 'wallet_exhausted',
        message: response.message,
        totalSeconds: _elapsedSeconds,
        totalCharge: response.billing?.chargedSoFar ??
            _latestBilling?.chargedSoFar ??
            _estimatedCharge(_elapsedSeconds),
      );
      return;
    }

    final billing = response.billing;
    if (billing == null) return;
    _latestBilling = billing;

    final current = state;
    if (current is! CallActive) return;

    emit(current.copyWith(
      billing: billing,
      chargeAmount: billing.chargedSoFar,
      isFreePhase: billing.freeSecondsLeft > 0,
      // Show the banner when the server flags low balance; clear it once a
      // mid-call recharge brings the balance back up.
      showLowBalanceBanner: billing.lowBalance,
      lowBalanceMessage: billing.lowBalance ? current.lowBalanceMessage : null,
    ));
  }

  Future<void> _onForceEndReceived(
    _ForceEndReceived event,
    Emitter<CallState> emit,
  ) async {
    final payload = event.payload;
    await _finalizeServerEndedCall(
      emit,
      reason: payload.reason,
      message: payload.message,
      totalSeconds:
          payload.totalSeconds > 0 ? payload.totalSeconds : _elapsedSeconds,
      totalCharge: payload.totalCharge > 0
          ? payload.totalCharge
          : _latestBilling?.chargedSoFar ?? _estimatedCharge(_elapsedSeconds),
    );
  }

  void _onLowBalanceReceived(
    _LowBalanceReceived event,
    Emitter<CallState> emit,
  ) {
    final current = state;
    if (current is! CallActive) return;
    // Idempotent: re-emitting the same banner state is a no-op for the UI.
    emit(current.copyWith(
      showLowBalanceBanner: true,
      lowBalanceMessage:
          event.payload.message.isNotEmpty ? event.payload.message : null,
    ));
  }

  /// Shared teardown for server-side call termination (heartbeat `callEnded`
  /// or `call:force-end` socket event — whichever arrives first wins; the
  /// second is a no-op).
  Future<void> _finalizeServerEndedCall(
    Emitter<CallState> emit, {
    required String reason,
    required String message,
    required int totalSeconds,
    required double totalCharge,
  }) async {
    if (_isFinalizing) return;
    _isFinalizing = true;

    _timer?.cancel();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    await _agoraCallEngine.leaveChannel();

    // No POST /calls/end here — the server already settled and ended the call.
    if (reason == 'wallet_exhausted') {
      emit(WalletExhausted(
        totalSeconds: totalSeconds,
        totalCharge: totalCharge,
        psychologistName: _psychologistName,
        message: message.isNotEmpty ? message : null,
      ));
    } else {
      emit(CallEnded(
        totalSeconds: totalSeconds,
        totalCharge: totalCharge,
        psychologistName: _psychologistName,
        endReason: reason,
        message: message.isNotEmpty ? message : null,
      ));
    }
  }

  void _onTick(TimerTick event, Emitter<CallState> emit) {
    if (state is! CallActive) return;
    final current = state as CallActive;

    // The heartbeat snapshot is authoritative; the local estimate only fills
    // the gap between beats.
    final billing = current.billing;
    final isFreePhase = billing != null
        ? billing.freeSecondsLeft > 0
        : event.elapsedSeconds < (_freeMinutes * 60);
    final charge =
        billing?.chargedSoFar ?? _estimatedCharge(event.elapsedSeconds);

    emit(current.copyWith(
      elapsedSeconds: event.elapsedSeconds,
      chargeAmount: charge,
      isFreePhase: isFreePhase,
    ));
  }

  double _estimatedCharge(int elapsedSeconds) {
    final billedSecs = CurrencyUtils.billedSeconds(
      totalSeconds: elapsedSeconds,
      freeMinutes: _freeMinutes,
    );
    return billedSecs > 0 ? (_ratePerMinute / 60.0) * billedSecs : 0.0;
  }

  Future<void> _onEndCall(EndCall event, Emitter<CallState> emit) async {
    if (_isFinalizing) return;

    final appointmentId = _appointmentId;
    final current = state;

    if (current is! CallActive) {
      // Cancelled before connecting — just stop listening for accept events.
      _timer?.cancel();
      _heartbeatTimer?.cancel();
      await _socketSub?.cancel();
      _socketSub = null;
      return;
    }

    _isFinalizing = true;
    _timer?.cancel();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    CallEndResult? endResult;
    if (appointmentId != null) {
      try {
        endResult = await _callRepository.endCall(
          appointmentId,
          CallEndRequest(durationSeconds: current.elapsedSeconds),
        );
      } catch (_) {
        // Backend end-call failure is tolerated; UI still exits call.
      }
    }

    await _agoraCallEngine.leaveChannel();

    final endReason = endResult?.endReason ?? 'user_ended';
    final totalCharge = endResult?.totalCharge ??
        _latestBilling?.chargedSoFar ??
        current.chargeAmount;

    if (endReason == 'wallet_exhausted') {
      emit(WalletExhausted(
        totalSeconds: endResult?.totalSeconds ?? current.elapsedSeconds,
        totalCharge: totalCharge,
        psychologistName: current.psychologistName,
        paidFromWallet: endResult?.paidFromWallet,
      ));
    } else {
      emit(CallEnded(
        totalSeconds: endResult?.totalSeconds ?? current.elapsedSeconds,
        totalCharge: totalCharge,
        psychologistName: current.psychologistName,
        endReason: endReason,
        paidFromWallet: endResult?.paidFromWallet,
      ));
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
    _heartbeatTimer = null;
    await _socketSub?.cancel();
    _callSocketManager.disconnect();
    await _agoraCallEngine.dispose();
    return super.close();
  }
}
