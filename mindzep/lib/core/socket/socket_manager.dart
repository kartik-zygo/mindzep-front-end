import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';
import '../network/token_storage.dart';

class SocketManager {
  SocketManager({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;
  final Map<String, io.Socket> _socketByNamespace = {};

  Future<io.Socket> connect(String namespace) async {
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

    socket.connect();
    _socketByNamespace[normalizedNamespace] = socket;
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
