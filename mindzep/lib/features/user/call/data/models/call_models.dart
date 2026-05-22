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
