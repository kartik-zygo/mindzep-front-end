import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../../core/socket/socket_manager.dart';
import '../../../../../core/utils/json_readers.dart';

class CallSocketManager {
  CallSocketManager({required SocketManager socketManager})
      : _socketManager = socketManager;

  final SocketManager _socketManager;
  io.Socket? _socket;

  final StreamController<Map<String, dynamic>> _callEventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get eventStream => _callEventController.stream;

  Future<void> connect() async {
    _socket = await _socketManager.connect('/call');

    _socket!.onAny((event, payload) {
      final map = JsonReaders.asMap(payload);
      _callEventController.add({
        'event': event,
        'payload': map,
      });
    });
  }

  void emit(String event, Map<String, dynamic> payload) {
    _socket?.emit(event, payload);
  }

  Future<void> disconnect() async {
    _socketManager.disconnect('/call');
    _socket = null;
  }

  void dispose() {
    _callEventController.close();
  }
}
