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
      parser: (json) {
        final m = JsonReaders.asMap(json);
        final list = m.containsKey('notifications') ? m['notifications'] : json;
        return JsonReaders.asMapList(list)
            .map(NotificationModel.fromJson)
            .toList();
      },
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

  Future<void> deleteNotification(String notificationId) {
    return _dioClient.delete<void>(
      ApiEndpoints.notificationDelete(notificationId),
      parser: (_) => null,
    );
  }

  Future<void> clearAll() {
    return _dioClient.delete<void>(
      ApiEndpoints.notificationsClearAll,
      parser: (_) => null,
    );
  }
}
