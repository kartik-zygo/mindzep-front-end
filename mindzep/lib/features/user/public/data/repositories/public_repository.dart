import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/utils/json_readers.dart';

class PublicRepository {
  PublicRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<Map<String, dynamic>> getHealth() {
    return _dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.health,
      requiresAuth: false,
      parser: JsonReaders.asMap,
    );
  }

  Future<Map<String, dynamic>> getStaticContent(String type) {
    return _dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.publicStaticContent(type),
      requiresAuth: false,
      parser: JsonReaders.asMap,
    );
  }
}
