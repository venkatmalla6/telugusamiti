import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(),
);

/// Handles all Firestore reads/writes for notification documents.
///
/// Per-user inbox  → `users/{uid}/notifications/{notifId}`
/// Global/admin    → `notifications/{notifId}`
class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --------------------------------------------------------------------------
  // Per-user inbox
  // --------------------------------------------------------------------------

  CollectionReference<NotificationModel> _userNotifCollection(String uid) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .withConverter<NotificationModel>(
            fromFirestore: (snap, _) =>
                NotificationModel.fromMap(snap.data()!, snap.id),
            toFirestore: (model, _) => model.toMap(),
          );

  /// Save a notification to the user's personal inbox.
  Future<String> saveUserNotification(
      String uid, NotificationModel notification) async {
    final ref = await _userNotifCollection(uid).add(notification);
    return ref.id;
  }

  /// Real-time stream of a user's notifications (newest first).
  Stream<List<NotificationModel>> streamUserNotifications(String uid) {
    return _userNotifCollection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Fetch notifications once (newest first, optional limit).
  Future<List<NotificationModel>> getUserNotifications(
    String uid, {
    int limit = 50,
  }) async {
    final snap = await _userNotifCollection(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String uid, String notifId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  /// Mark ALL unread notifications as read in a single batch.
  Future<void> markAllAsRead(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Delete a single notification from the user's inbox.
  Future<void> deleteUserNotification(String uid, String notifId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notifId)
        .delete();
  }

  /// Delete all notifications in the user's inbox.
  Future<void> clearUserNotifications(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // --------------------------------------------------------------------------
  // Global / admin broadcasts
  // --------------------------------------------------------------------------

  CollectionReference<NotificationModel> get _globalNotifCollection =>
      _db.collection('notifications').withConverter<NotificationModel>(
            fromFirestore: (snap, _) =>
                NotificationModel.fromMap(snap.data()!, snap.id),
            toFirestore: (model, _) => model.toMap(),
          );

  /// Save a global/broadcast notification (admin use).
  Future<String> saveGlobalNotification(NotificationModel notification) async {
    final ref = await _globalNotifCollection.add(notification);
    return ref.id;
  }

  /// Real-time stream of global notifications (newest first).
  Stream<List<NotificationModel>> streamGlobalNotifications() {
    return _globalNotifCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Delete a global notification.
  Future<void> deleteGlobalNotification(String notifId) async {
    await _globalNotifCollection.doc(notifId).delete();
  }
}
