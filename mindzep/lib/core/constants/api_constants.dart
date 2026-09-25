/// Central place to configure backend URLs.
///
/// Change [apiBaseUrl] (and optionally [socketBaseUrl]) here and
/// hot-restart the app — no need to touch .env or dart-define flags.
///
/// Priority order (highest → lowest):
///   1. --dart-define flags
///   2. .env file  (API_BASE_URL / SOCKET_BASE_URL)
///   3. The constants below  ← edit these for quick local changes
class ApiConstants {
  ApiConstants._();

  /// Base URL of the REST backend (no trailing slash).
  ///
  /// The backend is served behind Traefik under the `/mindzep-api` prefix,
  /// which is stripped before the request reaches it:
  ///   REST      https://www.zygonich.com/mindzep-api/api/v1
  ///   Socket.IO https://www.zygonich.com  (path /mindzep-api/socket.io)
  static const String apiBaseUrl =
      'https://www.zygonich.com/mindzep-api';

  /// Base URL used for Socket.IO connections.
  /// Defaults to [apiBaseUrl] when left empty. A path prefix here is used as
  /// the Socket.IO engine path, not the namespace — see [AppConfig.socketPath].
  static const String socketBaseUrl =
      'https://www.zygonich.com/mindzep-api';

  /// Agora App ID — must match the certificate used by the backend to sign
  /// tokens.  Set AGORA_APP_ID in .env or pass --dart-define=AGORA_APP_ID=<id>.
  static const String agoraAppId = 'bd97b1722a244db68aab6e3ee1fca0c4';
}
