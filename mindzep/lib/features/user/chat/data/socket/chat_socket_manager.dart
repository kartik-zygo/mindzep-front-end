import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../../core/socket/socket_manager.dart';
import '../../../../../core/utils/json_readers.dart';
import '../models/chat_models.dart';

class ChatSocketManager {
  ChatSocketManager({required SocketManager socketManager})
      : _socketManager = socketManager;

  final SocketManager _socketManager;
  io.Socket? _socket;

  final StreamController<ChatMessageModel> _messageController =
      StreamController<ChatMessageModel>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _readController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<ChatMessageModel> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get readStream => _readController.stream;

  Future<void> connect() async {
    _socket = await _socketManager.connect('/chat');

    _socket!.on('chat:message', (payload) {
      final map = JsonReaders.asMap(payload);
      final message = ChatMessageModel.fromJson(map);
      _messageController.add(message);
    });

    _socket!.on('chat:message:sent', (payload) {
      final map = JsonReaders.asMap(payload);
      final message = ChatMessageModel.fromJson(map);
      _messageController.add(message);
    });

    _socket!.on('chat:typing', (payload) {
      _typingController.add(JsonReaders.asMap(payload));
    });

    _socket!.on('chat:stop_typing', (payload) {
      _typingController.add(JsonReaders.asMap(payload));
    });

    _socket!.on('chat:messages_read', (payload) {
      _readController.add(JsonReaders.asMap(payload));
    });
  }

  void joinRoom(String appointmentId) {
    _socket?.emit(
      'chat:join',
      ChatSocketPayload(appointmentId: appointmentId).toJson(),
    );
  }

  void sendMessage(String appointmentId, String message) {
    _socket?.emit(
      'chat:send',
      ChatSocketPayload(
        appointmentId: appointmentId,
        message: message,
      ).toJson(),
    );
  }

  void sendTyping(String appointmentId) {
    _socket?.emit(
      'chat:typing',
      ChatSocketPayload(appointmentId: appointmentId).toJson(),
    );
  }

  void sendStopTyping(String appointmentId) {
    _socket?.emit(
      'chat:stop_typing',
      ChatSocketPayload(appointmentId: appointmentId).toJson(),
    );
  }

  void sendReadReceipt(String appointmentId) {
    _socket?.emit(
      'chat:read',
      ChatSocketPayload(appointmentId: appointmentId).toJson(),
    );
  }

  Future<void> disconnect() async {
    _socket?.off('chat:message');
    _socket?.off('chat:message:sent');
    _socket?.off('chat:typing');
    _socket?.off('chat:stop_typing');
    _socket?.off('chat:messages_read');
    _socketManager.disconnect('/chat');
    _socket = null;
  }

  void dispose() {
    _messageController.close();
    _typingController.close();
    _readController.close();
  }
}
