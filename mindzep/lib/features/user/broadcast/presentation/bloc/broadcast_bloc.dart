import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/network/api_error_model.dart';
import '../../../../../core/utils/json_readers.dart';
import '../../../../user/call/data/models/call_models.dart';
import '../../../../user/call/data/repositories/call_repository.dart';
import '../../../../user/call/data/socket/call_socket_manager.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class BroadcastEvent extends Equatable {
  const BroadcastEvent();
  @override
  List<Object?> get props => [];
}

/// Kick off the broadcast — calls the API and starts listening for
/// `call:accepted` on the socket.
class BroadcastStart extends BroadcastEvent {
  final double walletBalance;
  const BroadcastStart({this.walletBalance = 0});
  @override
  List<Object?> get props => [walletBalance];
}

/// User taps the cancel button.
class BroadcastCancel extends BroadcastEvent {
  const BroadcastCancel();
}

// Private —

class _BroadcastAccepted extends BroadcastEvent {
  final Map<String, dynamic> payload;
  const _BroadcastAccepted(this.payload);
  @override
  List<Object?> get props => [payload];
}

class _BroadcastTimerTick extends BroadcastEvent {
  final int elapsedSeconds;
  const _BroadcastTimerTick(this.elapsedSeconds);
  @override
  List<Object?> get props => [elapsedSeconds];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class BroadcastState extends Equatable {
  const BroadcastState();
  @override
  List<Object?> get props => [];
}

class BroadcastIdle extends BroadcastState {
  const BroadcastIdle();
}

/// Broadcast is active — waiting for a psychologist to accept.
class BroadcastWaiting extends BroadcastState {
  final int elapsedSeconds;
  final int notifiedPsychologists;
  const BroadcastWaiting({
    this.elapsedSeconds = 0,
    this.notifiedPsychologists = 0,
  });

  BroadcastWaiting copyWith({int? elapsedSeconds}) => BroadcastWaiting(
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        notifiedPsychologists: notifiedPsychologists,
      );

  @override
  List<Object?> get props => [elapsedSeconds, notifiedPsychologists];
}

/// A psychologist accepted — carries Agora credentials for the user to join.
class BroadcastAccepted extends BroadcastState {
  final String appointmentId;
  final String callId;
  final String appId;
  final String token;
  final String channelName;
  final int uid;
  final double ratePerMinute;
  final int freeMinutes;
  final double walletBalance;
  final String psychologistName;
  final String? psychologistAvatar;

  const BroadcastAccepted({
    required this.appointmentId,
    required this.callId,
    required this.appId,
    required this.token,
    required this.channelName,
    required this.uid,
    required this.ratePerMinute,
    required this.freeMinutes,
    required this.walletBalance,
    required this.psychologistName,
    this.psychologistAvatar,
  });

  @override
  List<Object?> get props => [appointmentId, callId, channelName];
}

/// 60-second timeout elapsed with no one accepting.
class BroadcastTimeout extends BroadcastState {
  const BroadcastTimeout();
}

/// Broadcast was cancelled by the user.
class BroadcastCancelled extends BroadcastState {
  const BroadcastCancelled();
}

class BroadcastError extends BroadcastState {
  final String message;
  const BroadcastError(this.message);
  @override
  List<Object?> get props => [message];
}

/// `POST /calls/broadcast-instant` rejected with HTTP 402 — the wallet cannot
/// cover one billed minute.
class BroadcastInsufficientBalance extends BroadcastState {
  final InsufficientBalanceError error;
  const BroadcastInsufficientBalance(this.error);
  @override
  List<Object?> get props =>
      [error.walletBalance, error.minimumRequired, error.message];
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class BroadcastCallBloc extends Bloc<BroadcastEvent, BroadcastState> {
  final CallRepository _callRepository;
  final CallSocketManager _callSocketManager;

  static const int _timeoutSeconds = 60;

  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  int _elapsedSeconds = 0;
  String? _appointmentId;
  double _walletBalance = 0;

  BroadcastCallBloc({
    required CallRepository callRepository,
    required CallSocketManager callSocketManager,
  })  : _callRepository = callRepository,
        _callSocketManager = callSocketManager,
        super(const BroadcastIdle()) {
    on<BroadcastStart>(_onStart);
    on<BroadcastCancel>(_onCancel);
    on<_BroadcastAccepted>(_onAccepted);
    on<_BroadcastTimerTick>(_onTimerTick);
  }

  Future<void> _onStart(
    BroadcastStart event,
    Emitter<BroadcastState> emit,
  ) async {
    _walletBalance = event.walletBalance;
    _elapsedSeconds = 0;

    try {
      // Connect to the /call socket namespace and start listening BEFORE
      // initiating the broadcast API call. The server notifies psychologists
      // immediately when the broadcast is created, so a psych can accept and
      // the server can fire call:accepted back to us before the HTTP response
      // even arrives if we connect after the API call.
      await _callSocketManager.connect();
      _socketSub = _callSocketManager.eventStream.listen(_handleSocketEvent);

      final result = await _callRepository.initiateInstantBroadcast();
      _appointmentId = result.appointmentId;

      emit(BroadcastWaiting(
        notifiedPsychologists: result.notifiedPsychologists,
      ));

      // Start the 60-second timeout timer.
      _startTimer();
    } on ApiErrorModel catch (error) {
      debugPrint('[BroadcastCallBloc] start error: $error');
      _cleanup();
      final insufficient = InsufficientBalanceError.tryParse(
        statusCode: error.statusCode,
        message: error.message,
        details: error.details,
      );
      if (insufficient != null) {
        emit(BroadcastInsufficientBalance(insufficient));
      } else {
        emit(BroadcastError(error.message));
      }
    } catch (error) {
      debugPrint('[BroadcastCallBloc] start error: $error');
      _cleanup();
      emit(BroadcastError(error.toString()));
    }
  }

  void _handleSocketEvent(Map<String, dynamic> event) {
    final name = event['event'] as String? ?? '';
    if (name == 'call:accepted') {
      final payload = JsonReaders.asMap(event['payload']);
      if (!isClosed) add(_BroadcastAccepted(payload));
    }
  }

  void _onTimerTick(
    _BroadcastTimerTick event,
    Emitter<BroadcastState> emit,
  ) {
    if (state is! BroadcastWaiting) return;

    if (event.elapsedSeconds >= _timeoutSeconds) {
      _cleanup();
      _cancelBroadcastSilently();
      emit(const BroadcastTimeout());
    } else {
      emit((state as BroadcastWaiting)
          .copyWith(elapsedSeconds: event.elapsedSeconds));
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      if (!isClosed) add(_BroadcastTimerTick(_elapsedSeconds));
    });
  }

  Future<void> _onAccepted(
    _BroadcastAccepted event,
    Emitter<BroadcastState> emit,
  ) async {
    _cleanup();

    final payload = event.payload;

    // Support nested `agora` sub-map or flat payload, mirroring
    // how CallBloc._onCallAccepted resolves credentials.
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
    ]);
    final token = resolve(
      ['token', 'agoraToken'],
      ['token', 'agoraToken'],
    );
    final channel = resolve(
      ['channelName', 'channelId'],
      ['channelName', 'channelId', 'agoraChannel'],
    );
    final uid = () {
      var v = JsonReaders.readInt(agora, ['uid']);
      if (v != 0) return v;
      return JsonReaders.readInt(payload, ['uid', 'agoraUid']);
    }();

    final appointmentId = _appointmentId?.isNotEmpty == true
        ? _appointmentId!
        : JsonReaders.readString(payload, ['appointmentId']);
    final callId =
        JsonReaders.readString(payload, ['callId', 'id', '_id']);

    final psychologistNameRaw = JsonReaders.readString(
        payload, ['psychologistName', 'userName', 'name']);
    final psychologistAvatarRaw = JsonReaders.readString(
        payload, ['psychologistAvatar', 'userAvatar', 'avatar']);

    final ratePerMinute =
        JsonReaders.readDouble(payload, ['ratePerMinute', 'rate']);
    final freeMinutes =
        JsonReaders.readInt(payload, ['freeMinutes'], fallback: 2);

    emit(BroadcastAccepted(
      appointmentId: appointmentId,
      callId: callId,
      appId: appId,
      token: token,
      channelName: channel,
      uid: uid,
      ratePerMinute: ratePerMinute,
      freeMinutes: freeMinutes,
      walletBalance: _walletBalance,
      psychologistName: psychologistNameRaw.isNotEmpty
          ? psychologistNameRaw
          : 'Psychologist',
      psychologistAvatar:
          psychologistAvatarRaw.isNotEmpty ? psychologistAvatarRaw : null,
    ));
  }

  Future<void> _onCancel(
    BroadcastCancel event,
    Emitter<BroadcastState> emit,
  ) async {
    _cleanup();
    await _cancelBroadcastSilently();
    emit(const BroadcastCancelled());
  }

  Future<void> _cancelBroadcastSilently() async {
    try {
      await _callRepository.cancelInstantBroadcast();
    } catch (_) {
      // Tolerate cancel failures — the backend may have already cleaned up.
    }
  }

  void _cleanup() {
    _timer?.cancel();
    _timer = null;
    _socketSub?.cancel();
    _socketSub = null;
  }

  static String _pickNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }

  @override
  Future<void> close() {
    _cleanup();
    return super.close();
  }
}
