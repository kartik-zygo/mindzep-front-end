import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/utils/json_readers.dart';
import '../models/incoming_call_data.dart';

/// Psychologist-side call repository.
///
/// Handles HTTP operations specific to the psychologist call flow, such as
/// polling for a pending incoming call that the socket may have missed.
class PsychCallRepository {
  PsychCallRepository({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Polls `GET /calls/pending` and returns the pending [IncomingCallData]
  /// if one exists, or `null` when there is nothing waiting.
  ///
  /// Expected response shapes (after [ApiResponseParser.extractData]):
  ///   { "pendingCall": { "appointmentId": "...", "agora": { ... } } }
  ///   { "pendingCall": null }
  Future<IncomingCallData?> fetchPendingCall() {
    return _dioClient.get<IncomingCallData?>(
      ApiEndpoints.callPending,
      parser: (json) {
        final map = JsonReaders.asMap(json);
        final pendingRaw = map['pendingCall'];
        if (pendingRaw == null) return null;
        final pendingMap = JsonReaders.asMap(pendingRaw);
        if (pendingMap.isEmpty) return null;
        return IncomingCallData.fromJson(pendingMap);
      },
    );
  }
}
