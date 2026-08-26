import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around the google_sign_in SDK.
///
/// All Google auth flows (login + signup screens) go through this single
/// service; the resulting idToken is exchanged with the backend via
/// `POST /auth/google`.
class GoogleAuthService {
  /// The backend's WEB OAuth client ID (not the Android one) — this makes
  /// Google issue an idToken whose audience matches the server's
  /// GOOGLE_CLIENT_ID. Not a secret.
  static const String serverClientId =
      '788249689957-pfgkctnm5f94usa9rff755gdon90gc73.apps.googleusercontent.com';

  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _instance => _googleSignIn ??= GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: serverClientId,
      );

  /// Runs the interactive Google Sign-In flow.
  ///
  /// Returns the Google idToken, or null when the user dismissed the account
  /// chooser (callers should silently return in that case).
  ///
  /// Throws [GoogleSignInConfigError] for the Android DEVELOPER_ERROR
  /// (status code 10 — SHA-1 / google-services.json misconfiguration) and
  /// [StateError] when Google returns no idToken (wrong serverClientId).
  Future<String?> getIdToken() async {
    final GoogleSignInAccount? account;
    try {
      account = await _instance.signIn();
    } on PlatformException catch (e) {
      final text = '${e.code} ${e.message ?? ''} ${e.details ?? ''}';
      if (text.contains('10') &&
          (e.code == 'sign_in_failed' || text.contains('DEVELOPER_ERROR'))) {
        debugPrint(
          '[GoogleAuth] DEVELOPER_ERROR (code 10): the SHA-1 fingerprint of '
          'this build\'s signing key is not registered in Firebase/Google '
          'Cloud, or google-services.json is stale. Register the debug, '
          'upload AND Play App Signing SHA-1s, re-download '
          'google-services.json, and rebuild.',
        );
        throw const GoogleSignInConfigError();
      }
      rethrow;
    }

    if (account == null) return null; // user dismissed the sheet

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'Google returned no idToken — verify serverClientId is the WEB '
        'OAuth client ID from Google Cloud Console.',
      );
    }
    return idToken;
  }

  /// Clears the cached Google session so the account picker shows again on
  /// the next sign-in. Safe to call when no Google session exists.
  Future<void> signOut() async {
    try {
      await _instance.signOut();
    } catch (e) {
      debugPrint('[GoogleAuth] signOut failed (ignored): $e');
    }
  }
}

/// Android DEVELOPER_ERROR (status 10) — configuration, not a user error.
class GoogleSignInConfigError implements Exception {
  const GoogleSignInConfigError();

  String get userMessage =>
      'Google Sign-In is not configured correctly for this build. '
      'Please contact support.';
}
