import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/utils/json_readers.dart';
import '../models/broadcast_instant_model.dart';
import '../models/call_models.dart';

class CallRepository {
  CallRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<CallRuntimeModel> initiateCall(String appointmentId) {
    return _dioClient.post<CallRuntimeModel>(
      ApiEndpoints.callInitiate(appointmentId),
      parser: (json) => CallRuntimeModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<CallRuntimeModel> broadcastInitiateCall(String appointmentId) {
    return _dioClient.post<CallRuntimeModel>(
      ApiEndpoints.callBroadcastInitiate(appointmentId),
      parser: (json) => CallRuntimeModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<CallRuntimeModel> broadcastAcceptCall(String appointmentId) {
    return _dioClient.post<CallRuntimeModel>(
      ApiEndpoints.callBroadcastAccept(appointmentId),
      parser: (json) => CallRuntimeModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<CallRuntimeModel> connectCall(String appointmentId) {
    return _dioClient.post<CallRuntimeModel>(
      ApiEndpoints.callConnect(appointmentId),
      parser: (json) => CallRuntimeModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  /// Sends a liveness heartbeat. The backend deducts the wallet for elapsed
  /// talk-time and returns a live billing snapshot — and may report that the
  /// call was force-ended (wallet_exhausted).
  ///
  /// Parsed from the full envelope (extractData: false) because the
  /// user-facing exhaustion message lives at the top level, next to `data`.
  Future<CallHeartbeatResponse> sendHeartbeat(
    String appointmentId,
    CallHeartbeatRequest request,
  ) {
    return _dioClient.post<CallHeartbeatResponse>(
      ApiEndpoints.callHeartbeat(appointmentId),
      data: request.toJson(),
      extractData: false,
      parser: (json) =>
          CallHeartbeatResponse.fromEnvelope(JsonReaders.asMap(json)),
    );
  }

  Future<CallEndResult> endCall(
    String appointmentId,
    CallEndRequest request,
  ) {
    return _dioClient.post<CallEndResult>(
      ApiEndpoints.callEnd(appointmentId),
      data: request.toJson(),
      parser: (json) => CallEndResult.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<CallRuntimeModel> getCallDetails(String appointmentId) {
    return _dioClient.get<CallRuntimeModel>(
      ApiEndpoints.callDetails(appointmentId),
      parser: (json) => CallRuntimeModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  /// Initiates a no-appointment instant broadcast call.
  /// Corresponds to `POST /calls/broadcast-instant`.
  Future<BroadcastInstantModel> initiateInstantBroadcast() {
    return _dioClient.post<BroadcastInstantModel>(
      ApiEndpoints.callBroadcastInstant,
      parser: (json) =>
          BroadcastInstantModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  /// Cancels an in-progress instant broadcast before anyone accepts.
  /// Corresponds to `POST /calls/broadcast-instant/cancel`.
  Future<void> cancelInstantBroadcast() {
    return _dioClient.post<void>(
      ApiEndpoints.callBroadcastInstantCancel,
      parser: (_) => null,
    );
  }
}
