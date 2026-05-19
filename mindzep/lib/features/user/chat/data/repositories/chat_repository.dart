import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/utils/json_readers.dart';
import '../models/chat_models.dart';

class ChatRepository {
  ChatRepository({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<List<ChatMessageModel>> listMessages(
    String appointmentId, {
    int page = 1,
    int limit = 50,
  }) {
    return _dioClient.get<List<ChatMessageModel>>(
      ApiEndpoints.chatMessages(appointmentId),
      queryParameters: {
        'page': page,
        'limit': limit,
      },
      parser: (json) {
        return JsonReaders.asMapList(json)
            .map(ChatMessageModel.fromJson)
            .toList();
      },
    );
  }

  Future<ChatMessageModel> sendMessage(
    String appointmentId,
    SendChatMessageRequest request,
  ) {
    return _dioClient.post<ChatMessageModel>(
      ApiEndpoints.chatMessages(appointmentId),
      data: request.toJson(),
      parser: (json) => ChatMessageModel.fromJson(JsonReaders.asMap(json)),
    );
  }

  Future<void> markRead(String appointmentId) {
    return _dioClient.put<void>(
      ApiEndpoints.chatRead(appointmentId),
      parser: (_) => null,
    );
  }
}
