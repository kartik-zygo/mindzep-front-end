import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../../core/socket/socket_manager.dart';
import '../../../../../core/utils/json_readers.dart';
import '../models/notification_models.dart';

class NotificationsSocketManager {
  NotificationsSocketManager({required SocketManager socketManager})
      : _socketManager = socketManager;

  final SocketManager _socketManager;
  io.Socket? _socket;

  final StreamController<NotificationModel> _notificationController =
      StreamController<NotificationModel>.broadcast();

  Stream<NotificationModel> get notificationStream =>
      _notificationController.stream;

  Future<void> connect() async {
    _socket = await _socketManager.connect('/notifications');

    _socket!.onAny((event, payload) {
      final map = JsonReaders.asMap(payload);
      if (map.isEmpty) {
        return;
      }

      final isNotificationEvent =
          (map.containsKey('notificationId') ||
              map.containsKey('id') ||
              map.containsKey('_id')) &&
          map.containsKey('title');

      if (!isNotificationEvent) {
        return;
      }

      _notificationController.add(NotificationModel.fromJson(map));
    });
  }

  Future<void> disconnect() async {
    _socketManager.disconnect('/notifications');
    _socket = null;
  }

  void dispose() {
    _notificationController.close();
  }
}
