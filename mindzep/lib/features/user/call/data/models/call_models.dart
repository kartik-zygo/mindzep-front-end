import '../../../../../core/utils/json_readers.dart';

class CallRuntimeModel {
  final String callId;
  final String appointmentId;
  final String channelName;
  final String token;
  final int uid;
  final double ratePerMinute;
  final int freeMinutes;
  final String? appId;
  final String? status;

  const CallRuntimeModel({
    required this.callId,
    required this.appointmentId,
    required this.channelName,
    required this.token,
    required this.uid,
    required this.ratePerMinute,
    required this.freeMinutes,
    required this.appId,
    required this.status,
  });

  /// Normalises all the different shapes the backend can return into a single
  /// flat map before reading individual fields.
  ///
  /// The Node/Sequelize backend may return raw ORM objects that look like:
  ///   { "call": { "dataValues": { "_id": "...", "agoraChannel": "...", ... } } }
  ///   { "dataValues": { ... } }
  ///
  /// Standard shape (plan spec):
  ///   { "callId": "...", "channelName": "...", "agoraToken": "...", "uid": ... }
  static Map<String, dynamic> _flatten(Map<String, dynamic> json) {
    // Unwrap { call: { dataValues: {...} } }
    final callRaw = json['call'];
    if (callRaw is Map) {
      final dv = callRaw['dataValues'];
      if (dv is Map) return JsonReaders.asMap(dv);
      return JsonReaders.asMap(callRaw);
    }
    // Unwrap { dataValues: {...} }
    final dvRaw = json['dataValues'];
    if (dvRaw is Map) return JsonReaders.asMap(dvRaw);
    return json;
  }

  factory CallRuntimeModel.fromJson(Map<String, dynamic> json) {
    final flat = _flatten(json);

    // Some backends nest Agora creds under 'agora' / 'rtc' / 'connection'.
    final agora = JsonReaders.asMap(
      JsonReaders.readAny(flat, ['agora', 'rtc', 'connection']),
    );

    // Channel name: agora sub-map → agoraChannel (Sequelize) → standard keys
    final channelName = _firstNonEmpty([
      JsonReaders.readString(agora, ['channelName', 'channelId']),
      JsonReaders.readString(flat, ['agoraChannel', 'channelName', 'channelId']),
    ]);

    // Token: agora sub-map → standard keys (connect endpoint has no token)
    final token = _firstNonEmpty([
      JsonReaders.readString(agora, ['token', 'agoraToken']),
      JsonReaders.readString(flat, ['agoraToken', 'token']),
    ]);

    // UID: agora sub-map → agoraUid (Sequelize) → standard uid
    final uid = () {
      var v = JsonReaders.readInt(agora, ['uid']);
      if (v != 0) return v;
      v = JsonReaders.readInt(flat, ['agoraUid', 'uid']);
      return v;
    }();

    // App ID: agora sub-map → standard keys
    final rawAppId = _firstNonEmpty([
      JsonReaders.readString(agora, ['appId', 'agoraAppId']),
      JsonReaders.readString(flat, ['appId', 'agoraAppId']),
    ]);

    return CallRuntimeModel(
      callId: JsonReaders.readString(flat, ['_id', 'id', 'callId']),
      appointmentId: JsonReaders.readString(flat, ['appointmentId']),
      channelName: channelName,
      token: token,
      uid: uid,
      ratePerMinute: JsonReaders.readDouble(
        flat,
        ['ratePerMinute', 'pricingPerMinute'],
      ),
      freeMinutes: JsonReaders.readInt(flat, ['freeMinutes'], fallback: 2),
      appId: rawAppId.isEmpty ? null : rawAppId,
      status: () {
        final s = JsonReaders.readString(flat, ['status']).trim();
        return s.isEmpty ? null : s;
      }(),
    );
  }

  static String _firstNonEmpty(List<String> values) {
    for (final v in values) {
      if (v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }
}

class CallHeartbeatRequest {
  final int durationSeconds;

  const CallHeartbeatRequest({required this.durationSeconds});

  Map<String, dynamic> toJson() {
    return {'durationSeconds': durationSeconds};
  }
}

class CallEndRequest {
  final int durationSeconds;

  const CallEndRequest({required this.durationSeconds});

  Map<String, dynamic> toJson() {
    return {'durationSeconds': durationSeconds};
  }
}

/// Live billing snapshot returned inside heartbeat responses.
/// `billing` is null while the call is not yet connected, so callers must
/// handle the absent case.
class CallBillingSnapshot {
  final double walletBalance;
  final double chargedSoFar;
  final double ratePerMinute;
  final double appChargePercent;
  final int remainingMinutes;
  final int freeSecondsLeft;
  final bool lowBalance;

  const CallBillingSnapshot({
    required this.walletBalance,
    required this.chargedSoFar,
    required this.ratePerMinute,
    required this.appChargePercent,
    required this.remainingMinutes,
    required this.freeSecondsLeft,
    required this.lowBalance,
  });

  factory CallBillingSnapshot.fromJson(Map<String, dynamic> json) {
    return CallBillingSnapshot(
      walletBalance: JsonReaders.readDouble(json, ['walletBalance']),
      chargedSoFar: JsonReaders.readDouble(json, ['chargedSoFar']),
      ratePerMinute: JsonReaders.readDouble(json, ['ratePerMinute']),
      appChargePercent: JsonReaders.readDouble(json, ['appChargePercent']),
      remainingMinutes: JsonReaders.readInt(json, ['remainingMinutes']),
      freeSecondsLeft: JsonReaders.readInt(json, ['freeSecondsLeft']),
      lowBalance: JsonReaders.readBool(json, ['lowBalance'], fallback: false),
    );
  }

  @override
  String toString() =>
      'Billing(wallet=₹$walletBalance charged=₹$chargedSoFar '
      'remaining=${remainingMinutes}min freeSecs=$freeSecondsLeft low=$lowBalance)';
}

/// Typed response of `POST /calls/:appointmentId/heartbeat`.
///
/// The backend now deducts the wallet on every heartbeat and may report that
/// it force-ended the call (`callEnded == true`, e.g. wallet_exhausted).
class CallHeartbeatResponse {
  final bool callEnded;
  final String? endReason;
  final CallBillingSnapshot? billing;
  final String message;

  const CallHeartbeatResponse({
    required this.callEnded,
    required this.endReason,
    required this.billing,
    required this.message,
  });

  /// Parses the FULL response envelope `{ success, message, data: {...} }` —
  /// the user-facing exhaustion message lives at the top level.
  factory CallHeartbeatResponse.fromEnvelope(Map<String, dynamic> envelope) {
    final data = JsonReaders.asMap(envelope['data']);
    final billingRaw = data['billing'];
    final endReason = JsonReaders.readString(data, ['endReason']).trim();

    return CallHeartbeatResponse(
      callEnded: JsonReaders.readBool(data, ['callEnded'], fallback: false),
      endReason: endReason.isEmpty ? null : endReason,
      billing: billingRaw is Map
          ? CallBillingSnapshot.fromJson(JsonReaders.asMap(billingRaw))
          : null,
      message: JsonReaders.readString(envelope, ['message']),
    );
  }
}

/// Payload of the `call:force-end` socket event on the /call namespace.
class CallForceEndEvent {
  final String appointmentId;
  final String callId;
  final String reason;
  final String message;
  final int totalSeconds;
  final double totalCharge;

  const CallForceEndEvent({
    required this.appointmentId,
    required this.callId,
    required this.reason,
    required this.message,
    required this.totalSeconds,
    required this.totalCharge,
  });

  factory CallForceEndEvent.fromJson(Map<String, dynamic> json) {
    return CallForceEndEvent(
      appointmentId: JsonReaders.readString(json, ['appointmentId']),
      callId: JsonReaders.readString(json, ['callId', 'id', '_id']),
      reason: JsonReaders.readString(json, ['reason'],
          fallback: 'wallet_exhausted'),
      message: JsonReaders.readString(json, ['message']),
      totalSeconds: JsonReaders.readInt(json, ['totalSeconds']),
      totalCharge: JsonReaders.readDouble(json, ['totalCharge']),
    );
  }
}

/// Payload of the `call:low-balance` socket event on the /call namespace.
class CallLowBalanceEvent {
  final String appointmentId;
  final String callId;
  final double walletBalance;
  final int remainingMinutes;
  final String message;

  const CallLowBalanceEvent({
    required this.appointmentId,
    required this.callId,
    required this.walletBalance,
    required this.remainingMinutes,
    required this.message,
  });

  factory CallLowBalanceEvent.fromJson(Map<String, dynamic> json) {
    return CallLowBalanceEvent(
      appointmentId: JsonReaders.readString(json, ['appointmentId']),
      callId: JsonReaders.readString(json, ['callId', 'id', '_id']),
      walletBalance: JsonReaders.readDouble(json, ['walletBalance']),
      remainingMinutes: JsonReaders.readInt(json, ['remainingMinutes']),
      message: JsonReaders.readString(json, ['message']),
    );
  }
}

/// Typed 402 INSUFFICIENT_WALLET_BALANCE error from the call-start endpoints
/// (`/calls/:id/initiate`, `/calls/:id/broadcast-initiate`,
/// `/calls/broadcast-instant`).
class InsufficientBalanceError {
  final String message;
  final double walletBalance;
  final double ratePerMinute;
  final double minimumRequired;

  const InsufficientBalanceError({
    required this.message,
    required this.walletBalance,
    required this.ratePerMinute,
    required this.minimumRequired,
  });

  /// Returns the typed error when [statusCode] is 402 (or the payload carries
  /// code INSUFFICIENT_WALLET_BALANCE); null otherwise.
  static InsufficientBalanceError? tryParse({
    required int? statusCode,
    required String message,
    required Map<String, dynamic>? details,
  }) {
    final errors = JsonReaders.asMap(details?['errors']);
    final code = JsonReaders.readString(errors, ['code']);
    final is402 = statusCode == 402 || code == 'INSUFFICIENT_WALLET_BALANCE';
    if (!is402) return null;

    return InsufficientBalanceError(
      message: message.isNotEmpty
          ? message
          : 'Insufficient wallet balance to start this call. '
              'Please recharge your wallet.',
      walletBalance: JsonReaders.readDouble(errors, ['walletBalance']),
      ratePerMinute: JsonReaders.readDouble(errors, ['ratePerMinute']),
      minimumRequired: JsonReaders.readDouble(errors, ['minimumRequired']),
    );
  }
}

/// Typed response of `POST /calls/:appointmentId/end`.
class CallEndResult {
  final String? endReason; // user_ended | wallet_exhausted | heartbeat_timeout
  final double? paidFromWallet;
  final double? totalCharge;
  final int? totalSeconds;

  const CallEndResult({
    required this.endReason,
    required this.paidFromWallet,
    required this.totalCharge,
    required this.totalSeconds,
  });

  factory CallEndResult.fromJson(Map<String, dynamic> json) {
    final call = JsonReaders.asMap(json['call']);
    final breakdown = JsonReaders.asMap(json['billingBreakdown']);

    final reason = () {
      final fromCall = JsonReaders.readString(call, ['endReason']).trim();
      if (fromCall.isNotEmpty) return fromCall;
      final flat = JsonReaders.readString(json, ['endReason']).trim();
      return flat.isEmpty ? null : flat;
    }();

    double? readOptionalDouble(Map<String, dynamic> map, List<String> keys) {
      final v = JsonReaders.readAny(map, keys);
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    final seconds = () {
      final v = JsonReaders.readInt(call, ['totalSeconds', 'durationSeconds']);
      if (v != 0) return v;
      final flat = JsonReaders.readInt(json, ['totalSeconds', 'durationSeconds']);
      return flat == 0 ? null : flat;
    }();

    return CallEndResult(
      endReason: reason,
      paidFromWallet: readOptionalDouble(breakdown, ['paidFromWallet']),
      totalCharge: readOptionalDouble(breakdown, ['totalCharge']) ??
          readOptionalDouble(call, ['totalCharge']) ??
          readOptionalDouble(json, ['totalCharge']),
      totalSeconds: seconds,
    );
  }
}
