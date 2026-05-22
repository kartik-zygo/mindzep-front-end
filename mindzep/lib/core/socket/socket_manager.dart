import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';
import '../network/token_storage.dart';

class SocketManager {
  SocketManager({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;
  final Map<String, io.Socket> _socketByNamespace = {};

  /// Connects to a Socket.IO namespace.
  ///
  /// When [awaitConnection] is `true` the Future resolves only after the
  /// socket emits its 'connect' event (i.e. the auth handshake is complete
  /// and the server has added the socket to its per-user room).  This is
  /// essential for the call namespace where an event can arrive very shortly
  /// after the socket is first created.
  Future<io.Socket> connect(String namespace,
      {bool awaitConnection = false}) async {
    final normalizedNamespace = namespace.startsWith('/')
        ? namespace
        : '/$namespace';

    final existing = _socketByNamespace[normalizedNamespace];
    if (existing != null && existing.connected) {
      return existing;
    }

    final accessToken = await _tokenStorage.getAccessToken();
    final uri = '${AppConfig.socketBaseUrl}$normalizedNamespace';

    final socket = io.io(
      uri,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(8)
          .setAuth({'token': accessToken ?? ''})
          .disableAutoConnect()
          .build(),
    );

    _socketByNamespace[normalizedNamespace] = socket;

    if (awaitConnection) {
      final completer = Completer<io.Socket>();

      socket.onConnect((_) {
        if (!completer.isCompleted) completer.complete(socket);
      });

      socket.onConnectError((err) {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception('Socket connection error [$namespace]: $err'),
          );
        }
      });

      socket.connect();

      // Give the socket up to 15 seconds to complete the auth handshake.
      return completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'Socket [$namespace] did not connect within 15 s',
          const Duration(seconds: 15),
        ),
      );
    }

    socket.connect();
    return socket;
  }

  io.Socket? getConnectedSocket(String namespace) {
    final normalizedNamespace = namespace.startsWith('/')
        ? namespace
        : '/$namespace';
    return _socketByNamespace[normalizedNamespace];
  }

  void disconnect(String namespace) {
    final normalizedNamespace = namespace.startsWith('/')
        ? namespace
        : '/$namespace';
    final socket = _socketByNamespace.remove(normalizedNamespace);
    socket?.dispose();
    socket?.disconnect();
  }

  void disconnectAll() {
    for (final socket in _socketByNamespace.values) {
      socket.dispose();
      socket.disconnect();
    }
    _socketByNamespace.clear();
  }
}
