import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_readers.dart';
import '../models/admin_models.dart';

class AdminRepository {
  AdminRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<Map<String, dynamic>> dashboard() {
    return _dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.adminDashboard,
      parser: JsonReaders.asMap,
    );
  }

  Future<Map<String, dynamic>> createPsychologist(
    CreatePsychologistRequest request,
  ) {
    return _dioClient.post<Map<String, dynamic>>(
      ApiEndpoints.adminPsychologists,
      data: request.toJson(),
      parser: JsonReaders.asMap,
    );
  }

  Future<List<Map<String, dynamic>>> listPsychologists({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) {
    return _dioClient.get<List<Map<String, dynamic>>>(
      ApiEndpoints.adminPsychologists,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      parser: (json) {
        final m = JsonReaders.asMap(json);
        final list = m.containsKey('psychologists') ? m['psychologists'] : json;
        return JsonReaders.asMapList(list);
      },
    );
  }

  Future<Map<String, dynamic>> getPsychologist(String psychologistId) {
    return _dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.adminPsychologistById(psychologistId),
      parser: JsonReaders.asMap,
    );
  }

  Future<Map<String, dynamic>> updatePsychologist(
    String psychologistId,
    Map<String, dynamic> body,
  ) {
    return _dioClient.put<Map<String, dynamic>>(
      ApiEndpoints.adminPsychologistById(psychologistId),
      data: body,
      parser: JsonReaders.asMap,
    );
  }

  Future<void> suspendPsychologist(
    String psychologistId,
    SuspendEntityRequest request,
  ) {
    return _dioClient.put<void>(
      ApiEndpoints.adminPsychologistSuspend(psychologistId),
      data: request.toJson(),
      parser: (_) => null,
    );
  }

  Future<void> activatePsychologist(String psychologistId) {
    return _dioClient.put<void>(
      ApiEndpoints.adminPsychologistActivate(psychologistId),
      parser: (_) => null,
    );
  }

  Future<void> deletePsychologist(String psychologistId) {
    return _dioClient.delete<void>(
      ApiEndpoints.adminPsychologistById(psychologistId),
      parser: (_) => null,
    );
  }

  Future<List<Map<String, dynamic>>> listUsers({
    int page = 1,
    int limit = 50,
    String? search,
    String? status,
  }) {
    return _dioClient.get<List<Map<String, dynamic>>>(
      ApiEndpoints.adminUsers,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      parser: (json) {
        final map = JsonReaders.asMap(json);
        final list = map.containsKey('users') ? map['users'] : json;
        return JsonReaders.asMapList(list);
      },
    );
  }

  Future<Map<String, dynamic>> getUser(String userId) {
    return _dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.adminUserById(userId),
      parser: (json) {
        final map = JsonReaders.asMap(json);
        return map.containsKey('user') ? JsonReaders.asMap(map['user']) : map;
      },
    );
  }

  Future<void> suspendUser(String userId, SuspendEntityRequest request) {
    return _dioClient.put<void>(
      ApiEndpoints.adminUserSuspend(userId),
      data: request.toJson(),
      parser: (_) => null,
    );
  }

  Future<void> activateUser(String userId) {
    return _dioClient.put<void>(
      ApiEndpoints.adminUserActivate(userId),
      parser: (_) => null,
    );
  }

  Future<void> creditUserWallet(String userId, CreditWalletRequest request) {
    return _dioClient.post<void>(
      ApiEndpoints.adminCreditWallet(userId),
      data: request.toJson(),
      parser: (_) => null,
    );
  }

  Future<List<Map<String, dynamic>>> listAppointments({
    int page = 1,
    int limit = 20,
  }) {
    return _dioClient.get<List<Map<String, dynamic>>>(
      ApiEndpoints.adminAppointments,
      queryParameters: {'page': page, 'limit': limit},
      parser: (json) {
        final m = JsonReaders.asMap(json);
        final list = m.containsKey('appointments') ? m['appointments'] : json;
        return JsonReaders.asMapList(list);
      },
    );
  }

  Future<List<Map<String, dynamic>>> listAuditLogs({
    int page = 1,
    int limit = 50,
  }) {
    return _dioClient.get<List<Map<String, dynamic>>>(
      ApiEndpoints.adminAuditLogs,
      queryParameters: {'page': page, 'limit': limit},
      parser: JsonReaders.asMapList,
    );
  }

  Future<Map<String, dynamic>> getStaticContent(String type) {
    return _dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.adminStaticContent(type),
      parser: JsonReaders.asMap,
    );
  }

  Future<Map<String, dynamic>> updateStaticContent(
    String type,
    UpdateStaticContentRequest request,
  ) {
    return _dioClient.put<Map<String, dynamic>>(
      ApiEndpoints.adminStaticContent(type),
      data: request.toJson(),
      parser: JsonReaders.asMap,
    );
  }
}
