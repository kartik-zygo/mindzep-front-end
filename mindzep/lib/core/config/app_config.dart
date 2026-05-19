import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static bool _initialized = false;

  static const String _apiBaseUrlDefine =
      String.fromEnvironment('API_BASE_URL');
  static const String _socketBaseUrlDefine =
      String.fromEnvironment('SOCKET_BASE_URL');
  static const String _agoraAppIdDefine =
      String.fromEnvironment('AGORA_APP_ID');
  static const String _cashfreeEnvironmentDefine =
      String.fromEnvironment('CASHFREE_ENVIRONMENT');

  static late final String apiBaseUrl;
  static late final String socketBaseUrl;
  static late final String restBaseUrl;
  static late final String agoraAppId;
  static late final String cashfreeEnvironment;

  static Future<void> initialize({String envFileName = '.env'}) async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: envFileName);
    } catch (_) {
      // .env is optional when values are provided through --dart-define.
    }

    final rawApiBase = _resolveValue(
      dotenvKey: 'API_BASE_URL',
      defineValue: _apiBaseUrlDefine,
    );

    if (rawApiBase.isEmpty || rawApiBase == '__BACKEND_BASE_URL__') {
      throw StateError(
        'API_BASE_URL is not configured. Set API_BASE_URL in .env '
        'or pass --dart-define=API_BASE_URL=<backend-url>.',
      );
    }

    apiBaseUrl = _sanitizeUrl(rawApiBase);
    socketBaseUrl = _sanitizeUrl(
      _resolveValue(
        dotenvKey: 'SOCKET_BASE_URL',
        defineValue: _socketBaseUrlDefine,
        fallback: apiBaseUrl,
      ),
    );
    restBaseUrl = '$apiBaseUrl/api/v1';

    agoraAppId = _resolveValue(
      dotenvKey: 'AGORA_APP_ID',
      defineValue: _agoraAppIdDefine,
    );

    cashfreeEnvironment = _resolveValue(
      dotenvKey: 'CASHFREE_ENVIRONMENT',
      defineValue: _cashfreeEnvironmentDefine,
      fallback: 'sandbox',
    ).toLowerCase();

    _initialized = true;
  }

  static String _resolveValue({
    required String dotenvKey,
    required String defineValue,
    String fallback = '',
  }) {
    final envValue = dotenv.env[dotenvKey]?.trim() ?? '';
    if (envValue.isNotEmpty) {
      return envValue;
    }

    final compileTimeValue = defineValue.trim();
    if (compileTimeValue.isNotEmpty) {
      return compileTimeValue;
    }

    return fallback;
  }

  static String _sanitizeUrl(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return normalized;
    return normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
  }
}
