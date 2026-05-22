import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../../core/socket/socket_manager.dart';
import '../../../../../core/utils/json_readers.dart';
import '../models/incoming_call_data.dart';

/// Persistent socket service for the psychologist side.
///
/// Connects to the /call namespace and exposes a stream of incoming call
/// events emitted by the backend as `call:incoming` when a user initiates
/// a call.
///
/// Key design points:
/// - [connect] waits for the socket to ACTUALLY connect (auth handshake
///   complete, server has added the socket to the per-user room).  This
///   eliminates the race condition where the backend emits `call:incoming`
///   before the socket has finished joining its room.
/// - [onConnect] / [onDisconnect] handlers trace connectivity in debug mode.
/// - The `call:incoming` data handler logs parse errors instead of silently
///   dropping events.
class PsychCallSocketService {
  PsychCallSocketService({required SocketManager socketManager})
      : _socketManager = socketManager;

  final SocketManager _socketManager;
  io.Socket? _socket;
  bool _connected = false;

  final StreamController<IncomingCallData> _incomingController =
      StreamController<IncomingCallData>.broadcast();

  /// Fires whenever the backend sends a `call:cancelled` socket event
  /// (reason: `accepted_by_other` or `user_cancelled`).
  final StreamController<Map<String, dynamic>> _cancelledController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Fires whenever the backend sends a `call:incoming` socket event.
  Stream<IncomingCallData> get onIncomingCall => _incomingController.stream;

  /// Fires whenever the backend sends a `call:cancelled` socket event.
  /// The map carries at minimum `{ callId, appointmentId, reason }`.
  Stream<Map<String, dynamic>> get onCallCancelled => _cancelledController.stream;

  /// Connects to the /call namespace and waits until the socket is truly
  /// connected (auth handshake complete, room joined on the server side).
  /// Safe to call multiple times — subsequent calls are no-ops if the socket
  /// is already connected.
  Future<void> connect() async {
    if (_connected && (_socket?.connected ?? false)) return;
    _connected = false;

    _socket = await _socketManager.connect('/call', awaitConnection: true);
    _connected = true;

    _registerListeners(_socket!);
    debugPrint('[PsychCallSocket] connected ✓');
  }

  void _registerListeners(io.Socket socket) {
    socket.onDisconnect((reason) {
      _connected = false;
      debugPrint('[PsychCallSocket] disconnected — $reason');
    });

    socket.onConnect((_) {
      _connected = true;
      debugPrint('[PsychCallSocket] reconnected ✓');
      // Ask the server to re-deliver any pending call:incoming that was missed
      // while the socket was disconnected or not yet established.
      socket.emit('call:sync');
    });

    socket.onConnectError((err) {
      debugPrint('[PsychCallSocket] connect error — $err');
    });

    socket.on('call:incoming', (data) {
      debugPrint('[PsychCallSocket] call:incoming received → $data');
      try {
        final map = JsonReaders.asMap(data);
        if (map.isEmpty) {
          debugPrint('[PsychCallSocket] call:incoming: empty/non-map payload ignored');
          return;
        }
        if (!_incomingController.isClosed) {
          _incomingController.add(IncomingCallData.fromJson(map));
        }
      } catch (e, st) {
        debugPrint('[PsychCallSocket] call:incoming parse error: $e\n$st');
      }
    });

    socket.on('call:cancelled', (data) {
      debugPrint('[PsychCallSocket] call:cancelled received → $data');
      try {
        final map = JsonReaders.asMap(data);
        if (!_cancelledController.isClosed) {
          _cancelledController.add(map);
        }
      } catch (e) {
        debugPrint('[PsychCallSocket] call:cancelled parse error: $e');
      }
    });
  }

  /// Emits a rejection event to the server so the user is notified.
  void emitReject(String appointmentId) {
    _socket?.emit('call:reject', {'appointmentId': appointmentId});
  }

  void disconnect() {
    _connected = false;
    _socketManager.disconnect('/call');
    _socket = null;
  }

  void dispose() {
    _incomingController.close();
    _cancelledController.close();
  }
}
