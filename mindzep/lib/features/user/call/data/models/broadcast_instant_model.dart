import '../../../../../core/utils/json_readers.dart';

/// Response model for `POST /calls/broadcast-instant`.
class BroadcastInstantModel {
  final String callId;
  final String appointmentId;
  final int notifiedPsychologists;

  const BroadcastInstantModel({
    required this.callId,
    required this.appointmentId,
    required this.notifiedPsychologists,
  });

  factory BroadcastInstantModel.fromJson(Map<String, dynamic> json) {
    // The backend may wrap the result in a `data` key or return it flat.
    final flat = _flatten(json);
    return BroadcastInstantModel(
      callId: JsonReaders.readString(flat, ['callId', 'id', '_id']),
      appointmentId: JsonReaders.readString(flat, ['appointmentId']),
      notifiedPsychologists: JsonReaders.readInt(
        flat,
        ['notifiedPsychologists'],
      ),
    );
  }

  static Map<String, dynamic> _flatten(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) return JsonReaders.asMap(data);
    return json;
  }
}
