import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';
import '../../models/event_model.dart';

import '../../models/user_model.dart';
import '../../models/subscription_model.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/notification_repository.dart';

/// Coordinates business-logic workflows for generating, saving, and simulating
/// push notifications for events, announcements, membership expirations and broadcasts.
class NotificationWorkflowService {
  final NotificationRepository _notificationRepo;
  final EventRepository _eventRepo;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  NotificationWorkflowService({
    required NotificationRepository notificationRepo,
    required EventRepository eventRepo,
  })  : _notificationRepo = notificationRepo,
        _eventRepo = eventRepo;

  // --------------------------------------------------------------------------
  // 1. Admin Broadcasts
  // --------------------------------------------------------------------------
  /// Sends a broadcast message to all registered application members.
  /// Saves to the global `notifications` collection and also copies to individual inboxes.
  Future<void> sendAdminBroadcast({
    required String title,
    required String body,
    required String sentBy,
  }) async {
    try {
      log('[Workflow] Starting admin broadcast: $title');
      
      // Save to global notifications first
      final globalNotif = NotificationModel(
        id: '',
        title: title,
        body: body,
        createdAt: DateTime.now(),
        type: NotificationType.adminBroadcast,
        topic: 'all_users',
        data: {'sentBy': sentBy},
      );
      final globalNotifId = await _notificationRepo.saveGlobalNotification(globalNotif);

      // Write to each user's personal inbox
      final usersSnap = await _db.collection('users').get();
      final batch = _db.batch();

      for (final userDoc in usersSnap.docs) {
        final notifRef = _db
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc(); // Generate random ID

        final userNotif = globalNotif.copyWith(
          id: notifRef.id,
          targetUid: userDoc.id,
          data: {
            'sentBy': sentBy,
            'globalNotificationId': globalNotifId,
          },
        );
        batch.set(notifRef, userNotif.toMap());
      }

      await batch.commit();
      log('[Workflow] Admin broadcast complete, notified ${usersSnap.docs.length} users.');
    } catch (e) {
      log('[Workflow] Error sending admin broadcast: $e');
      rethrow;
    }
  }



  // --------------------------------------------------------------------------
  // 3. Event Reminders
  // --------------------------------------------------------------------------
  /// Sends event reminder notifications to all users registered for the specified event.
  Future<void> sendEventReminder(EventModel event) async {
    try {
      log('[Workflow] Starting event reminder workflow for event: ${event.title}');
      
      // Get all registered users for this event
      final registrations = await _eventRepo.getEventRegistrations(event.id);
      if (registrations.isEmpty) {
        log('[Workflow] No registered users to remind for event: ${event.title}');
        return;
      }

      final batch = _db.batch();
      for (final reg in registrations) {
        final notifRef = _db
            .collection('users')
            .doc(reg.userId)
            .collection('notifications')
            .doc();

        final notif = NotificationModel(
          id: notifRef.id,
          title: 'Upcoming Event: ${event.title}',
          body: 'Hi ${reg.userName ?? 'Member'}, don\'t forget that the event starts on ${event.startDate.toString()} at ${event.location}. See you there!',
          createdAt: DateTime.now(),
          type: NotificationType.eventReminder,
          targetUid: reg.userId,
          data: {
            'eventId': event.id,
            'registrationId': reg.id,
          },
        );
        batch.set(notifRef, notif.toMap());
      }

      await batch.commit();
      log('[Workflow] Event reminder workflow complete, notified ${registrations.length} users.');
    } catch (e) {
      log('[Workflow] Error in event reminder workflow: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // 4. Membership Expiry Alerts
  // --------------------------------------------------------------------------
  /// Checks subscription expiry and notifies the user if within the 7-day window.
  /// Deduplicates to prevent sending redundant notifications.
  Future<void> checkAndNotifyMembershipExpiry(UserModel user) async {
    try {
      log('[Workflow] Checking membership expiry for user: ${user.uid}');
      
      // Get latest active subscription
      final subsSnap = await _db
          .collection('subscriptions')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .get();

      if (subsSnap.docs.isEmpty) {
        log('[Workflow] No active subscription found for user: ${user.uid}');
        return;
      }

      final List<SubscriptionModel> subs = subsSnap.docs
          .map((d) => SubscriptionModel.fromMap(d.data(), d.id))
          .toList();
      subs.sort((a, b) => b.endDate.compareTo(a.endDate));
      final activeSub = subs.first;

      final now = DateTime.now();
      final difference = activeSub.endDate.difference(now);
      
      // If subscription expires within 7 days
      if (difference.inDays >= 0 && difference.inDays <= 7) {
        // Check if a membershipExpiry notification was already created in the last 7 days
        final recentNotifs = await _db
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .where('type', isEqualTo: NotificationType.membershipExpiry.name)
            .get();

        bool alreadyNotified = false;
        for (final doc in recentNotifs.docs) {
          final notif = NotificationModel.fromMap(doc.data(), doc.id);
          if (now.difference(notif.createdAt).inDays < 7) {
            alreadyNotified = true;
            break;
          }
        }

        if (!alreadyNotified) {
          final notifRef = _db
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .doc();

          final notif = NotificationModel(
            id: notifRef.id,
            title: 'Membership Expiring Soon!',
            body: 'Your "${activeSub.planName}" membership is expiring in ${difference.inDays} days on ${activeSub.endDate.toString().split(' ')[0]}. Renew now to keep your benefits!',
            createdAt: DateTime.now(),
            type: NotificationType.membershipExpiry,
            targetUid: user.uid,
            data: {
              'subscriptionId': activeSub.id,
              'planName': activeSub.planName,
            },
          );

          await notifRef.set(notif.toMap());
          log('[Workflow] Sent membership expiry alert to user: ${user.uid}');
        }
      }
    } catch (e) {
      log('[Workflow] Error in membership expiry check: $e');
    }
  }

  // --------------------------------------------------------------------------
  // 5. New Event Notification
  // --------------------------------------------------------------------------
  /// Sends a notification to all users when a new event is published.
  Future<void> sendNewEventNotification(EventModel event) async {
    try {
      log('[Workflow] Starting new event notification workflow: ${event.title}');
      
      final usersSnap = await _db.collection('users').get();
      final batch = _db.batch();

      for (final userDoc in usersSnap.docs) {
        final notifRef = _db
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc();

        final notif = NotificationModel(
          id: notifRef.id,
          title: 'New Event: ${event.title}',
          body: 'A new event "${event.title}" has been published! Join us at ${event.location} on ${event.startDate.toString().split(' ')[0]}. Register now!',
          createdAt: DateTime.now(),
          type: NotificationType.eventReminder,
          targetUid: userDoc.id,
          data: {
            'eventId': event.id,
          },
        );
        batch.set(notifRef, notif.toMap());
      }

      await batch.commit();
      log('[Workflow] New event notification workflow complete, notified ${usersSnap.docs.length} users.');
    } catch (e) {
      log('[Workflow] Error in new event notification workflow: $e');
      rethrow;
    }
  }
}
