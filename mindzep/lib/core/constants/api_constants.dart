/// Central place to configure backend URLs.
///
/// Change [apiBaseUrl] (and optionally [socketBaseUrl]) here and
/// hot-restart the app — no need to touch .env or dart-define flags.
///
/// Priority order (highest → lowest):
///   1. .env file  (API_BASE_URL / SOCKET_BASE_URL)
///   2. --dart-define flags
///   3. The constants below  ← edit these for quick local changes
class ApiConstants {
  ApiConstants._();

  /// Base URL of the REST backend (no trailing slash).
  static const String apiBaseUrl =
      'https://ed94-122-184-152-82.ngrok-free.app';

  /// Base URL used for Socket.IO connections.
  /// Defaults to [apiBaseUrl] when left empty.
  static const String socketBaseUrl =
      'https://ed94-122-184-152-82.ngrok-free.app';

  /// Agora App ID — must match the certificate used by the backend to sign
  /// tokens.  Set AGORA_APP_ID in .env or pass --dart-define=AGORA_APP_ID=<id>.
  static const String agoraAppId = '';
}
