import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/fcm_service.dart';
import '../core/services/local_notification_service.dart';
import '../core/services/notification_workflow_service.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../repositories/event_repository.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Service providers
// ---------------------------------------------------------------------------

final localNotificationServiceProvider =
    Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref.watch(localNotificationServiceProvider));
});

final notificationWorkflowServiceProvider = Provider<NotificationWorkflowService>((ref) {
  return NotificationWorkflowService(
    notificationRepo: ref.watch(notificationRepositoryProvider),
    eventRepo: ref.watch(eventRepositoryProvider),
  );
});

final notificationTapStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return FcmService.onNotificationTap;
});

final fcmInitializationProvider = Provider.autoDispose<void>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  userAsync.whenData((user) {
    if (user != null) {
      ref.read(fcmServiceProvider).initialize(uid: user.uid, role: user.role);
      
      // Check membership expiry alert
      ref.read(notificationWorkflowServiceProvider).checkAndNotifyMembershipExpiry(user);
    }
  });
});

// ---------------------------------------------------------------------------
// Notification repository provider
// ---------------------------------------------------------------------------

// Already declared in notification_repository.dart:
// final notificationRepositoryProvider

// ---------------------------------------------------------------------------
// Per-user notification stream
// ---------------------------------------------------------------------------

/// Streams the authenticated user's notifications in real-time.
final userNotificationsProvider = StreamProvider.family
    .autoDispose<List<NotificationModel>, String>((ref, uid) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.streamUserNotifications(uid);
});

// ---------------------------------------------------------------------------
// Unread count derived from the stream
// ---------------------------------------------------------------------------

/// Number of unread notifications for [uid].
final unreadNotificationCountProvider =
    Provider.family.autoDispose<int, String>((ref, uid) {
  final asyncNotifs = ref.watch(userNotificationsProvider(uid));
  return asyncNotifs.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

// ---------------------------------------------------------------------------
// Global (admin) broadcast stream
// ---------------------------------------------------------------------------

final globalNotificationsProvider =
    StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  return ref.watch(notificationRepositoryProvider).streamGlobalNotifications();
});

// ---------------------------------------------------------------------------
// Notification controller — for UI actions
// ---------------------------------------------------------------------------

final notificationControllerProvider =
    Provider<NotificationController>((ref) {
  return NotificationController(
    ref.watch(notificationRepositoryProvider),
    ref.watch(fcmServiceProvider),
  );
});

class NotificationController {
  final NotificationRepository _repo;
  final FcmService _fcmService;

  NotificationController(this._repo, this._fcmService);

  Future<void> markAsRead(String uid, String notifId) =>
      _repo.markAsRead(uid, notifId);

  Future<void> markAllAsRead(String uid) => _repo.markAllAsRead(uid);

  Future<void> deleteNotification(String uid, String notifId) =>
      _repo.deleteUserNotification(uid, notifId);

  Future<void> clearAll(String uid) => _repo.clearUserNotifications(uid);

  /// Admin: send a broadcast to a topic.  Firestore trigger / Cloud Function
  /// will pick this up and dispatch via FCM.
  Future<String> sendBroadcast(NotificationModel notification) =>
      _repo.saveGlobalNotification(notification);

  Future<void> subscribeToTopic(String topic) =>
      _fcmService.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      _fcmService.unsubscribeFromTopic(topic);
}
