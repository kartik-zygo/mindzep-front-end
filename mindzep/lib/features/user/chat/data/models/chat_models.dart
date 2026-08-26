import '../../../../../core/utils/json_readers.dart';

class ChatMessageModel {
  final String id;
  final String appointmentId;
  final String senderId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.appointmentId,
    required this.senderId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: JsonReaders.readString(json, ['id', '_id', 'messageId']),
      appointmentId:
          JsonReaders.readString(json, ['appointmentId', 'roomId']),
      senderId: JsonReaders.readString(json, ['senderId', 'userId']),
      message: JsonReaders.readString(json, ['message', 'text']),
      isRead: JsonReaders.readBool(json, ['isRead', 'read']),
      createdAt: JsonReaders.readDateTime(json, ['createdAt', 'created_at']),
    );
  }
}

class SendChatMessageRequest {
  final String message;

  const SendChatMessageRequest({required this.message});

  Map<String, dynamic> toJson() {
    return {'message': message};
  }
}

class ChatSocketPayload {
  final String appointmentId;
  final String? message;

  const ChatSocketPayload({required this.appointmentId, this.message});

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      if (message != null) 'message': message,
    };
  }
}
