import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/entities/entities.dart';
import '../../../../../core/mock/mock_data.dart';
import '../../../../../core/utils/currency_utils.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class CallEvent extends Equatable {
  const CallEvent();
  @override
  List<Object?> get props => [];
}

class InitiateCall extends CallEvent {
  final String appointmentId;
  final String psychologistId;
  const InitiateCall(
      {required this.appointmentId, required this.psychologistId});
  @override
  List<Object?> get props => [appointmentId, psychologistId];
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

  const CallActive({
    required this.psychologistName,
    this.psychologistAvatar,
    required this.elapsedSeconds,
    this.isMuted = false,
    this.isVideoOff = false,
    this.isSpeakerOn = true,
    this.chargeAmount = 0,
    this.isFreePhase = true,
  });

  CallActive copyWith({
    int? elapsedSeconds,
    bool? isMuted,
    bool? isVideoOff,
    bool? isSpeakerOn,
    double? chargeAmount,
    bool? isFreePhase,
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
      );

  @override
  List<Object?> get props => [
        elapsedSeconds,
        isMuted,
        isVideoOff,
        isSpeakerOn,
        chargeAmount,
        isFreePhase,
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

// ─── BLoC ────────────────────────────────────────────────────────────────────

class CallBloc extends Bloc<CallEvent, CallState> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  double _ratePerMinute = 10.0;
  int _freeMinutes = 2;

  CallBloc() : super(const CallInitial()) {
    on<InitiateCall>(_onInitiate);
    on<CallConnected>(_onConnected);
    on<TimerTick>(_onTick);
    on<EndCall>(_onEndCall);
    on<ToggleMute>(_onToggleMute);
    on<ToggleVideo>(_onToggleVideo);
    on<ToggleSpeaker>(_onToggleSpeaker);
  }

  Future<void> _onInitiate(
      InitiateCall event, Emitter<CallState> emit) async {
    final psych = MockData.psychologists.firstWhere(
      (p) => p.id == event.psychologistId,
      orElse: () => MockData.psychologists.first,
    );
    _ratePerMinute = psych.ratePerMinute;
    _freeMinutes = psych.freeMinutes;
    emit(CallConnecting(
      psychologistName: psych.name,
      psychologistAvatar: psych.avatarUrl,
    ));
    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 2));
    if (!isClosed) add(const CallConnected());
  }

  void _onConnected(CallConnected event, Emitter<CallState> emit) {
    final current = state;
    if (current is! CallConnecting) return;
    _elapsedSeconds = 0;
    emit(CallActive(
      psychologistName: current.psychologistName,
      psychologistAvatar: current.psychologistAvatar,
      elapsedSeconds: 0,
    ));
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      if (!isClosed) add(TimerTick(_elapsedSeconds));
    });
  }

  void _onTick(TimerTick event, Emitter<CallState> emit) {
    if (state is! CallActive) return;
    final current = state as CallActive;
    // Billing: 0–119s free, 120s+ billed per second
    final billedSecs =
        CurrencyUtils.billedSeconds(totalSeconds: event.elapsedSeconds, freeMinutes: _freeMinutes);
    final charge =
        billedSecs > 0 ? (_ratePerMinute / 60.0) * billedSecs : 0.0;
    emit(current.copyWith(
      elapsedSeconds: event.elapsedSeconds,
      chargeAmount: charge,
      isFreePhase: event.elapsedSeconds < 120,
    ));
  }

  void _onEndCall(EndCall event, Emitter<CallState> emit) {
    _timer?.cancel();
    final current = state;
    if (current is CallActive) {
      emit(CallEnded(
        totalSeconds: current.elapsedSeconds,
        totalCharge: current.chargeAmount,
        psychologistName: current.psychologistName,
      ));
    }
  }

  void _onToggleMute(ToggleMute event, Emitter<CallState> emit) {
    if (state is CallActive) {
      final s = state as CallActive;
      emit(s.copyWith(isMuted: !s.isMuted));
    }
  }

  void _onToggleVideo(ToggleVideo event, Emitter<CallState> emit) {
    if (state is CallActive) {
      final s = state as CallActive;
      emit(s.copyWith(isVideoOff: !s.isVideoOff));
    }
  }

  void _onToggleSpeaker(ToggleSpeaker event, Emitter<CallState> emit) {
    if (state is CallActive) {
      final s = state as CallActive;
      emit(s.copyWith(isSpeakerOn: !s.isSpeakerOn));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

