import '../../../../../core/utils/json_readers.dart';

/// Data carried by a `call:incoming` socket event sent to the psychologist.
class IncomingCallData {
  final String appointmentId;
  final String callId;
  /// `'broadcast'` for instant calls, `'direct'` for appointment-based calls.
  final String callType;
  final String channelName;
  final String token;
  final int uid;
  final String? appId;
  final String userName;
  final String? userAvatar;
  final double ratePerMinute;
  final int freeMinutes;

  const IncomingCallData({
    required this.appointmentId,
    required this.callId,
    this.callType = 'direct',
    required this.channelName,
    required this.token,
    required this.uid,
    this.appId,
    required this.userName,
    this.userAvatar,
    required this.ratePerMinute,
    required this.freeMinutes,
  });

  /// Normalises the socket payload regardless of whether the backend sends a
  /// flat object, a nested Agora sub-map, or a raw Sequelize `dataValues`
  /// wrapper.  Field aliases supported:
  ///   channelName  ←  agoraChannel | channelId
  ///   token        ←  agoraToken
  ///   uid          ←  agoraUid
  factory IncomingCallData.fromJson(Map<String, dynamic> json) {
    // Unwrap Sequelize raw format if present.
    final flat = _flatten(json);

    // Optional Agora sub-map.
    final agora = JsonReaders.asMap(
      JsonReaders.readAny(flat, ['agora', 'rtc', 'connection']),
    );

    String resolveStr(List<String> agoraKeys, List<String> rootKeys) {
      final v = JsonReaders.readString(agora, agoraKeys);
      if (v.isNotEmpty) return v;
      return JsonReaders.readString(flat, rootKeys);
    }

    // Channel: agora sub-map → agoraChannel (Sequelize) → standard keys
    final channelName = resolveStr(
      ['channelName', 'channelId'],
      ['agoraChannel', 'channelName', 'channelId'],
    );

    // Token: agora sub-map → agoraToken → token
    final token = resolveStr(
      ['token', 'agoraToken'],
      ['agoraToken', 'token'],
    );

    // UID: agora sub-map → agoraUid (Sequelize) → uid
    final uid = () {
      var v = JsonReaders.readInt(agora, ['uid']);
      if (v != 0) return v;
      return JsonReaders.readInt(flat, ['agoraUid', 'uid']);
    }();

    // App ID
    final rawAppId = resolveStr(
      ['appId', 'agoraAppId'],
      ['appId', 'agoraAppId'],
    );

    return IncomingCallData(
      appointmentId: JsonReaders.readString(flat, ['appointmentId']),
      callId: JsonReaders.readString(flat, ['callId', 'id', '_id']),
      channelName: channelName,
      token: token,
      uid: uid,
      appId: rawAppId.isEmpty ? null : rawAppId,
      callType: JsonReaders.readString(
        flat,
        ['callType', 'type'],
        fallback: 'direct',
      ),
      userName: JsonReaders.readString(
        flat,
        ['userName', 'callerName', 'name'],
      ),
      userAvatar: () {
        final v = JsonReaders.readString(
          flat,
          ['userAvatar', 'callerAvatar', 'avatar'],
        );
        return v.isEmpty ? null : v;
      }(),
      ratePerMinute: JsonReaders.readDouble(
        flat,
        ['ratePerMinute', 'pricingPerMinute'],
      ),
      freeMinutes: JsonReaders.readInt(flat, ['freeMinutes'], fallback: 2),
    );
  }

  /// Unwraps Sequelize raw shapes:
  ///   { call: { dataValues: {...} } }  →  dataValues
  ///   { dataValues: {...} }            →  dataValues
  static Map<String, dynamic> _flatten(Map<String, dynamic> json) {
    final callRaw = json['call'];
    if (callRaw is Map) {
      final dv = callRaw['dataValues'];
      if (dv is Map) return JsonReaders.asMap(dv);
      return JsonReaders.asMap(callRaw);
    }
    final dvRaw = json['dataValues'];
    if (dvRaw is Map) return JsonReaders.asMap(dvRaw);
    return json;
  }
}
