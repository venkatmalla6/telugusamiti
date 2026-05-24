import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../models/notification_model.dart';
import '../../../models/user_model.dart';
import 'local_notification_service.dart';

// ---------------------------------------------------------------------------
// Background message handler — MUST be a top-level function.
// ---------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this is called.
  log('[FCM] Background message received: ${message.messageId}');

  // Persist to Firestore so the user sees it in their inbox later.
  final uid = message.data['targetUid'];
  if (uid != null && uid.toString().isNotEmpty) {
    try {
      final notif = _remoteMessageToModel(message);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid.toString())
          .collection('notifications')
          .add(notif.toMap());
    } catch (e) {
      log('[FCM] Failed to store background notification: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// Helper — converts [RemoteMessage] → [NotificationModel]
// ---------------------------------------------------------------------------
NotificationModel _remoteMessageToModel(RemoteMessage message) {
  return NotificationModel(
    id: message.messageId ?? '',
    title: message.notification?.title ?? message.data['title'] ?? '',
    body: message.notification?.body ?? message.data['body'] ?? '',
    isRead: false,
    createdAt: message.sentTime ?? DateTime.now(),
    type: NotificationTypeX.fromString(message.data['type']),
    topic: message.data['topic'],
    targetUid: message.data['targetUid'],
    imageUrl: message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl,
    data: Map<String, dynamic>.from(message.data),
  );
}

// ---------------------------------------------------------------------------
// FcmService
// ---------------------------------------------------------------------------

/// Manages device token registration, topic subscriptions and message routing.
class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final LocalNotificationService _localNotif;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Topics automatically subscribed for every authenticated user.
  static const List<String> _globalTopics = [
    'all_users',
    'announcements',
  ];

  FcmService(this._localNotif);

  // --------------------------------------------------------------------------
  // Public API
  // --------------------------------------------------------------------------

  /// Call once after successful login. Requests permissions, registers the
  /// device token, subscribes to role-based topics, and wires message handlers.
  Future<void> initialize({
    required String uid,
    required UserRole role,
  }) async {
    await _requestPermission();
    await _saveDeviceToken(uid);
    await _subscribeToTopics(role);
    _setupForegroundHandler(uid);
    _setupOnOpenedAppHandler();

    // Listen for token refreshes.
    _messaging.onTokenRefresh.listen((newToken) async {
      await _upsertToken(uid, newToken);
    });
  }

  /// Call on sign-out to clean up the current device token.
  Future<void> unregisterDevice(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _db
            .collection('users')
            .doc(uid)
            .collection('fcmTokens')
            .doc(_tokenDocId(token))
            .delete();
      }
      for (final topic in _globalTopics) {
        await _messaging.unsubscribeFromTopic(topic);
      }
    } catch (e) {
      log('[FCM] unregisterDevice error: $e');
    }
  }

  /// Manually subscribe to a single FCM topic (e.g. 'events').
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    log('[FCM] Subscribed to topic: $topic');
  }

  /// Manually unsubscribe from a single FCM topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    log('[FCM] Unsubscribed from topic: $topic');
  }

  /// Returns the current FCM token (may be null if not yet available).
  Future<String?> getToken() => _messaging.getToken();

  // --------------------------------------------------------------------------
  // Permission
  // --------------------------------------------------------------------------

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    log('[FCM] Permission status: ${settings.authorizationStatus}');
  }

  // --------------------------------------------------------------------------
  // Token management
  // --------------------------------------------------------------------------

  Future<void> _saveDeviceToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _upsertToken(uid, token);
  }

  Future<void> _upsertToken(String uid, String token) async {
    try {
      final docId = _tokenDocId(token);
      await _db
          .collection('users')
          .doc(uid)
          .collection('fcmTokens')
          .doc(docId)
          .set({
        'token': token,
        'platform': _platform(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also set the token on the main user document for easy Cloud Function queries
      await _db.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
      log('[FCM] Token saved for uid=$uid');
    } catch (e) {
      log('[FCM] Failed to save token for uid=$uid: $e');
    }
  }

  String _tokenDocId(String token) =>
      token.substring(token.length - 20); // last 20 chars as doc ID

  String _platform() {
    try {
      // ignore: do_not_use_environment
      const isAndroid = bool.fromEnvironment('dart.library.io');
      return isAndroid ? 'android' : 'ios';
    } catch (_) {
      return 'unknown';
    }
  }

  // --------------------------------------------------------------------------
  // Topic subscriptions
  // --------------------------------------------------------------------------

  Future<void> _subscribeToTopics(UserRole role) async {
    for (final topic in _globalTopics) {
      await _messaging.subscribeToTopic(topic);
    }
    await _messaging.subscribeToTopic('role_${role.name}');
    log('[FCM] Topics subscribed for role: ${role.name}');
  }

  // --------------------------------------------------------------------------
  // Foreground message handler
  // --------------------------------------------------------------------------

  void _setupForegroundHandler(String uid) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      log('[FCM] Foreground message: ${message.messageId}');

      final notif = _remoteMessageToModel(message);

      // 1. Show a local heads-up notification.
      await _localNotif.showNotification(
        id: message.hashCode,
        title: notif.title,
        body: notif.body,
        payload: jsonEncode(message.data),
        imageUrl: notif.imageUrl,
      );

      // 2. Persist to the user's Firestore inbox.
      try {
        await _db
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .add(notif.toMap());
      } catch (e) {
        log('[FCM] Failed to store foreground notification: $e');
      }
    });
  }

  // --------------------------------------------------------------------------
  // Notification tap / app-opened handler
  // --------------------------------------------------------------------------

  void _setupOnOpenedAppHandler() {
    // App was in background and user tapped notification.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Handle the initial message when the app was terminated and launched via
  /// a notification tap. Call this from main() after FCM initialisation.
  Future<void> checkInitialMessage() async {
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleNotificationTap(initial);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    log('[FCM] Notification tapped: ${message.data}');
    // Navigation is handled by listening to a stream/notifier in the router.
    // Emit to the shared stream so GoRouter redirect can pick it up.
    notificationTapController.add(message.data);
  }

  // Stream for notification taps so the router / screens can react.
  static final StreamController<Map<String, dynamic>> notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get onNotificationTap =>
      notificationTapController.stream;
}
