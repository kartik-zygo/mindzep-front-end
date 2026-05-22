import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─── Background message handler (must be top-level function) ─────────────────
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // FCM shows notification automatically when the payload has a `notification`
  // field. For data-only messages we must display the local notification
  // ourselves from this isolate.
  if (message.notification == null) {
    final title = message.data['title'] as String? ?? 'MindZep';
    final body  = message.data['body']  as String? ?? '';
    if (title.isEmpty && body.isEmpty) return;

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await plugin.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mindzep_notifications',
          'MindZep Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data['type'] as String?,
    );
  }
}

// Top-level callback for local notifications tapped while in background.
@pragma('vm:entry-point')
void _onBackgroundLocalNotification(NotificationResponse details) {
  // Navigation is not available in background isolate; the tap will be
  // re-processed when the app comes to foreground via getInitialMessage.
}

/// Manages Firebase initialization, FCM token retrieval, and local notification
/// display for foreground messages.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();

  late final FirebaseMessaging _messaging;

  static const _androidChannelId = 'mindzep_notifications';
  static const _androidChannelName = 'MindZep Notifications';
  static const _androidChannelDesc = 'Push notifications for MindZep app';

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Stream that yields the FCM token whenever it changes or is refreshed.
  final _tokenController = StreamController<String>.broadcast();
  Stream<String> get onTokenRefresh => _tokenController.stream;

  // Stream that yields a notification payload when the user taps a notification
  // and the app opens from terminated/background state.
  final _tapController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNotificationTap => _tapController.stream;

  Future<void> initialize() async {
    // 1. Initialize Firebase
    await Firebase.initializeApp();

    // Now safe to access FirebaseMessaging
    _messaging = FirebaseMessaging.instance;

    // 2. Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // 3. Request permission (iOS / Android 13+)
    await _requestPermission();

    // 4. Set up Android local notification channel
    await _setupLocalNotifications();

    // 5. Get and cache FCM token
    _fcmToken = await _messaging.getToken();
    if (_fcmToken != null) {
      debugPrint('[FCM] Token: $_fcmToken');
    } else {
      debugPrint('[FCM] Token unavailable yet — will emit when ready');
    }

    // 6. Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      debugPrint('[FCM] Token refreshed: $token');
      _tokenController.add(token);
    });

    // 7. Foreground messages → show as local notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 8. App opened from background notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 9. App opened from terminated state via notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleNotificationTap(initial);
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    // On Android, also configure foreground presentation
    if (Platform.isAndroid) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
    // settings.authorizationStatus indicates if the user granted permission.
    final _ = settings;
  }

  Future<void> _setupLocalNotifications() async {
    // Android channel
    const androidChannel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDesc,
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Init settings
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // User tapped a local notification shown in foreground
        if (details.payload != null) {
          _tapController.add({'type': details.payload});
        }
      },
      onDidReceiveBackgroundNotificationResponse: _onBackgroundLocalNotification,
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Support both notification-messages and data-only messages.
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body  = notification?.body  ?? message.data['body']  as String?;

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['type'] as String?,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    _tapController.add(message.data);
  }

  void dispose() {
    _tokenController.close();
    _tapController.close();
  }
}
