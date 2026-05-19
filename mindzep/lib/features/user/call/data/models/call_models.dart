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

  factory CallRuntimeModel.fromJson(Map<String, dynamic> json) {
    final agora = JsonReaders.asMap(
      JsonReaders.readAny(json, ['agora', 'rtc', 'connection']),
    );

    return CallRuntimeModel(
      callId: JsonReaders.readString(json, ['id', '_id', 'callId']),
      appointmentId: JsonReaders.readString(
        json,
        ['appointmentId'],
      ),
      channelName: JsonReaders.readString(
        agora,
        ['channelName', 'channelId'],
        fallback: JsonReaders.readString(json, ['channelName', 'channelId']),
      ),
      token: JsonReaders.readString(
        agora,
        ['token', 'agoraToken'],
        fallback: JsonReaders.readString(json, ['token', 'agoraToken']),
      ),
      uid: JsonReaders.readInt(
        agora,
        ['uid'],
        fallback: JsonReaders.readInt(json, ['uid']),
      ),
      ratePerMinute: JsonReaders.readDouble(
        json,
        ['ratePerMinute', 'pricingPerMinute'],
      ),
      freeMinutes: JsonReaders.readInt(json, ['freeMinutes'], fallback: 2),
      appId: JsonReaders.readString(
        agora,
        ['appId', 'agoraAppId'],
      ).trim().isEmpty
          ? JsonReaders.readString(json, ['appId', 'agoraAppId']).trim().isEmpty
              ? null
              : JsonReaders.readString(json, ['appId', 'agoraAppId'])
          : JsonReaders.readString(agora, ['appId', 'agoraAppId']),
      status: JsonReaders.readString(json, ['status']).trim().isEmpty
          ? null
          : JsonReaders.readString(json, ['status']),
    );
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
