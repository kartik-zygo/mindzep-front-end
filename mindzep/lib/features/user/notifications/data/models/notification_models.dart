import '../../../../../core/utils/json_readers.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: JsonReaders.readString(json, ['id', '_id', 'notificationId']),
      title: JsonReaders.readString(json, ['title']),
      message: JsonReaders.readString(json, ['message', 'body']),
      type: JsonReaders.readString(json, ['type'], fallback: 'system'),
      isRead: JsonReaders.readBool(json, ['isRead', 'read']),
      createdAt: JsonReaders.readDateTime(json, ['createdAt', 'created_at']),
    );
  }
}
