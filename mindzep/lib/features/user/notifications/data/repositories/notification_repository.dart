import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../core/utils/json_readers.dart';
import '../models/notification_models.dart';

class NotificationRepository {
  NotificationRepository({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  Future<List<NotificationModel>> listNotifications() {
    return _dioClient.get<List<NotificationModel>>(
      ApiEndpoints.notifications,
      parser: (json) => JsonReaders.asMapList(json)
          .map(NotificationModel.fromJson)
          .toList(),
    );
  }

  Future<void> markAllRead() {
    return _dioClient.put<void>(
      ApiEndpoints.notificationsReadAll,
      parser: (_) => null,
    );
  }

  Future<void> markOneRead(String notificationId) {
    return _dioClient.put<void>(
      ApiEndpoints.notificationRead(notificationId),
      parser: (_) => null,
    );
  }
}
