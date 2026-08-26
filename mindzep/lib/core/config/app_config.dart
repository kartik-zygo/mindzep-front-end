import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mindzep/core/constants/api_constants.dart';

/// Central runtime configuration.
///
/// Priority order (highest → lowest):
///   1. --dart-define flags (authoritative — release builds are driven by these)
///   2. .env file (local development convenience only)
///   3. The fallback constants in [ApiConstants] / hardcoded defaults
///
/// Production release build:
///   flutter build appbundle \
///     --dart-define=API_BASE_URL=https://api.mindzep.com \
///     --dart-define=PAYMENT_ENV=production
class AppConfig {
  AppConfig._();

  static bool _initialized = false;

  static const String _apiBaseUrlDefine =
      String.fromEnvironment('API_BASE_URL');
  static const String _socketBaseUrlDefine =
      String.fromEnvironment('SOCKET_BASE_URL');
  static const String _agoraAppIdDefine =
      String.fromEnvironment('AGORA_APP_ID');
  static const String _paymentEnvDefine =
      String.fromEnvironment('PAYMENT_ENV');

  /// Legacy alias for PAYMENT_ENV kept for backwards compatibility with
  /// existing build scripts / .env files.
  static const String _cashfreeEnvironmentDefine =
      String.fromEnvironment('CASHFREE_ENVIRONMENT');

  static late final String apiBaseUrl;
  static late final String socketBaseUrl;
  static late final String restBaseUrl;
  static late final String agoraAppId;

  /// 'sandbox' | 'production' — drives the Cashfree SDK environment.
  static late final String paymentEnv;

  static bool get isPaymentProduction => paymentEnv == 'production';

  static Future<void> initialize({String envFileName = '.env'}) async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: envFileName);
    } catch (_) {
      // .env is optional when values are provided through --dart-define.
    }

    final rawApiBase = _resolveValue(
      defineValue: _apiBaseUrlDefine,
      dotenvKey: 'API_BASE_URL',
      fallback: ApiConstants.apiBaseUrl,
    );

    if (rawApiBase.isEmpty || rawApiBase == '__BACKEND_BASE_URL__') {
      throw StateError(
        'API_BASE_URL is not configured. Pass --dart-define=API_BASE_URL=<url>, '
        'set API_BASE_URL in .env, or update ApiConstants.apiBaseUrl.',
      );
    }

    apiBaseUrl = _sanitizeUrl(rawApiBase);
    socketBaseUrl = _sanitizeUrl(
      _resolveValue(
        defineValue: _socketBaseUrlDefine,
        dotenvKey: 'SOCKET_BASE_URL',
        fallback: ApiConstants.socketBaseUrl.isNotEmpty
            ? ApiConstants.socketBaseUrl
            : apiBaseUrl,
      ),
    );
    restBaseUrl = '$apiBaseUrl/api/v1';

    agoraAppId = _resolveValue(
      defineValue: _agoraAppIdDefine,
      dotenvKey: 'AGORA_APP_ID',
      fallback: ApiConstants.agoraAppId,
    );

    final rawPaymentEnv = () {
      // PAYMENT_ENV takes precedence over the legacy CASHFREE_ENVIRONMENT key.
      if (_paymentEnvDefine.trim().isNotEmpty) return _paymentEnvDefine;
      if (_cashfreeEnvironmentDefine.trim().isNotEmpty) {
        return _cashfreeEnvironmentDefine;
      }
      final envValue = dotenv.env['PAYMENT_ENV']?.trim() ?? '';
      if (envValue.isNotEmpty) return envValue;
      final legacyEnvValue = dotenv.env['CASHFREE_ENVIRONMENT']?.trim() ?? '';
      if (legacyEnvValue.isNotEmpty) return legacyEnvValue;
      return 'sandbox';
    }();

    paymentEnv =
        rawPaymentEnv.trim().toLowerCase() == 'production'
            ? 'production'
            : 'sandbox';

    _initialized = true;
  }

  static String _resolveValue({
    required String defineValue,
    required String dotenvKey,
    String fallback = '',
  }) {
    // --dart-define wins: release builds must not be overridden by a bundled
    // .env asset that was meant for local development.
    final compileTimeValue = defineValue.trim();
    if (compileTimeValue.isNotEmpty) {
      return compileTimeValue;
    }

    final envValue = dotenv.env[dotenvKey]?.trim() ?? '';
    if (envValue.isNotEmpty) {
      return envValue;
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
