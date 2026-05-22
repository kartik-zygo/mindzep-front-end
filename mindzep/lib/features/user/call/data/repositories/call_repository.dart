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

  Future<void> sendHeartbeat(
    String appointmentId,
    CallHeartbeatRequest request,
  ) {
    return _dioClient.post<void>(
      ApiEndpoints.callHeartbeat(appointmentId),
      data: request.toJson(),
      parser: (_) => null,
    );
  }

  Future<void> endCall(
    String appointmentId,
    CallEndRequest request,
  ) {
    return _dioClient.post<void>(
      ApiEndpoints.callEnd(appointmentId),
      data: request.toJson(),
      parser: (_) => null,
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
