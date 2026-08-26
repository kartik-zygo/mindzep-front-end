import 'dart:async';

import 'package:flutter/foundation.dart';
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
    final socket = await _socketManager.connect('/call', awaitConnection: true);

    // The underlying socket is cached per namespace, so connect() can be
    // called by multiple owners (broadcast bloc → call bloc). Clear any
    // previous catch-all handler to avoid duplicated events.
    socket.offAny();
    socket.onAny((event, payload) {
      if (kDebugMode) {
        debugPrint('[CallSocket] ← $event');
      }
      final map = JsonReaders.asMap(payload);
      if (!_callEventController.isClosed) {
        _callEventController.add({
          'event': event,
          'payload': map,
        });
      }
    });

    _socket = socket;
  }

  /// Joins the per-appointment call room so room-scoped events
  /// (`call:force-end`, `call:low-balance`) are delivered.
  void joinCallRoom(String appointmentId) {
    if (appointmentId.isEmpty) return;
    if (kDebugMode) debugPrint('[CallSocket] → call:join $appointmentId');
    _socket?.emit('call:join', {'appointmentId': appointmentId});
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
