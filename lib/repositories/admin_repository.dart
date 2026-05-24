import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/volunteer_profile_model.dart';
import '../models/admin_profile_model.dart';
import '../models/app_setting_model.dart';
import '../models/user_model.dart';
import '../models/subscription_model.dart';
import '../models/payment_model.dart';
import '../models/event_registration_model.dart';
import '../models/notification_model.dart';
import '../core/services/firestore_service.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

class AdminRepository {
  final FirestoreService<VolunteerProfileModel> _volunteerService;
  final FirestoreService<AdminProfileModel> _adminService;
  final FirestoreService<AppSettingModel> _settingsService;
  final FirestoreService<UserModel> _userService;
  final FirestoreService<SubscriptionModel> _subscriptionService;
  final FirestoreService<PaymentModel> _paymentService;
  final FirestoreService<EventRegistrationModel> _registrationService;
  final FirestoreService<NotificationModel> _notificationService;

  AdminRepository()
      : _volunteerService = FirestoreService<VolunteerProfileModel>(
          collectionPath: 'volunteers',
          fromMap: VolunteerProfileModel.fromMap,
          toMap: (item) => item.toMap(),
        ),
        _adminService = FirestoreService<AdminProfileModel>(
          collectionPath: 'admins',
          fromMap: AdminProfileModel.fromMap,
          toMap: (item) => item.toMap(),
        ),
        _settingsService = FirestoreService<AppSettingModel>(
          collectionPath: 'settings',
          fromMap: AppSettingModel.fromMap,
          toMap: (item) => item.toMap(),
        ),
        _userService = FirestoreService<UserModel>(
          collectionPath: 'users',
          fromMap: UserModel.fromMap,
          toMap: (item) => item.toMap(),
        ),
        _subscriptionService = FirestoreService<SubscriptionModel>(
          collectionPath: 'subscriptions',
          fromMap: SubscriptionModel.fromMap,
          toMap: (item) => item.toMap(),
        ),
        _paymentService = FirestoreService<PaymentModel>(
          collectionPath: 'payments',
          fromMap: PaymentModel.fromMap,
          toMap: (item) => item.toMap(),
        ),
        _registrationService = FirestoreService<EventRegistrationModel>(
          collectionPath: 'registrations',
          fromMap: EventRegistrationModel.fromMap,
          toMap: (item) => item.toMap(),
        ),
        _notificationService = FirestoreService<NotificationModel>(
          collectionPath: 'notifications',
          fromMap: NotificationModel.fromMap,
          toMap: (item) => item.toMap(),
        );

  Future<void> updateVolunteerProfile(String uid, VolunteerProfileModel profile) =>
      _volunteerService.set(uid, profile);

  Future<AppSettingModel?> getAppSettings() => _settingsService.getById('app_config');

  // ─── User Management ───────────────────────────────────────────────────────

  Stream<List<UserModel>> streamAllUsers() => _userService.streamAll();

  Future<List<UserModel>> getAllUsers() => _userService.getAll();

  Future<UserModel?> getUserById(String uid) => _userService.getById(uid);

  Future<void> updateUserRole(String uid, UserRole role) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': role.name});
  }

  Future<void> deleteUser(String uid) async {
    await _userService.delete(uid);
  }

  Future<void> deleteUsers(List<String> uids) async {
    final db = FirebaseFirestore.instance;
    int i = 0;
    WriteBatch batch = db.batch();
    for (final uid in uids) {
      batch.delete(db.collection('users').doc(uid));
      i++;
      if (i % 500 == 0) {
        await batch.commit();
        batch = db.batch();
      }
    }
    if (i % 500 != 0) {
      await batch.commit();
    }
  }

  /// Search users by displayName prefix (client-side filter for Firestore free tier)
  Future<List<UserModel>> searchUsersByName(String query) async {
    final all = await _userService.getAll();
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((u) => (u.displayName ?? '').toLowerCase().contains(q)).toList();
  }

  /// Search users by phone number
  Future<List<UserModel>> searchUsersByPhone(String phone) async {
    return await _userService.getWhere(field: 'phoneNumber', isEqualTo: phone);
  }

  /// Search users by uid (member ID)
  Future<UserModel?> searchUserById(String uid) => _userService.getById(uid);

  // ─── Subscription Management ────────────────────────────────────────────────

  Future<SubscriptionModel?> getUserLatestSubscription(String uid) async {
    final subs = await _subscriptionService.getWhere(field: 'userId', isEqualTo: uid);
    if (subs.isEmpty) return null;
    subs.sort((a, b) => b.endDate.compareTo(a.endDate));
    return subs.first;
  }

  Future<List<SubscriptionModel>> getAllActiveSubscriptions() async {
    return await _subscriptionService.getWhere(field: 'status', isEqualTo: 'active');
  }



  // ─── Payment Management ─────────────────────────────────────────────────────

  Future<List<PaymentModel>> getUserPayments(String uid) async {
    final payments = await _paymentService.getWhere(field: 'userId', isEqualTo: uid);
    payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return payments;
  }

  Future<List<PaymentModel>> getAllPayments() async {
    final all = await _paymentService.getAll();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  // ─── Event Registrations ────────────────────────────────────────────────────

  Future<List<EventRegistrationModel>> getUserEventRegistrations(String uid) async {
    return await FirebaseFirestore.instance
        .collectionGroup('registrations')
        .where('userId', isEqualTo: uid)
        .get()
        .then((snap) => snap.docs
            .map((d) => EventRegistrationModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ─── Analytics ──────────────────────────────────────────────────────────────

  Future<Map<String, int>> getAnalyticsStats() async {
    final allUsers = await _userService.getAll();
    // Only count approved users who have completed registration
    final registeredUsers = allUsers.where((u) => 
      u.approvalStatus == ApprovalStatus.approved && 
      u.displayName != null && 
      u.displayName!.isNotEmpty
    ).toList();
    
    final activeSubs = await getAllActiveSubscriptions();
    final payments = await getAllPayments();
    final events = await FirebaseFirestore.instance.collection('events').get();

    final totalCollection = payments
        .where((p) => p.status == PaymentStatus.success)
        .fold<double>(0, (sum, p) => sum + p.amount)
        .toInt();

    return {
      'totalMembers': registeredUsers.length,
      'activeSubscriptions': activeSubs.length,
      'totalEvents': events.docs.length,
      'totalCollection': totalCollection,
    };
  }

  // ─── Notifications ──────────────────────────────────────────────────────────

  Future<void> sendNotificationToAll({
    required String title,
    required String body,
    required String sentBy,
  }) async {
    final users = await getAllUsers();
    final db = FirebaseFirestore.instance;
    
    // Save to global/root notifications as well (for audit/history)
    final globalRef = db.collection('notifications').doc();
    final notifData = {
      'title': title,
      'body': body,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'type': NotificationType.adminBroadcast.name,
      'topic': 'all_users',
      'data': {'sentBy': sentBy},
    };
    
    await globalRef.set(notifData);

    // Fan-out to all users' individual notification collections
    // Firestore batch writes are limited to 500 operations.
    int i = 0;
    WriteBatch batch = db.batch();
    
    for (final user in users) {
      if (user.uid.isEmpty) continue;
      
      final userNotifRef = db
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(globalRef.id);
          
      batch.set(userNotifRef, notifData);
      i++;
      
      // Commit and start a new batch if we reach 500
      if (i % 500 == 0) {
        await batch.commit();
        batch = db.batch();
      }
    }
    
    // Commit any remaining operations
    if (i % 500 != 0) {
      await batch.commit();
    }
  }

  Future<void> updateNotification(String id, String title, String body) async {
    final users = await getAllUsers();
    final db = FirebaseFirestore.instance;

    await db.collection('notifications').doc(id).update({
      'title': title,
      'body': body,
    });

    int i = 0;
    WriteBatch batch = db.batch();
    for (final user in users) {
      if (user.uid.isEmpty) continue;
      final ref = db.collection('users').doc(user.uid).collection('notifications').doc(id);
      batch.update(ref, {
        'title': title,
        'body': body,
      });
      i++;
      if (i % 500 == 0) {
        await batch.commit();
        batch = db.batch();
      }
    }
    if (i % 500 != 0) {
      await batch.commit();
    }
  }

  Future<void> deleteNotification(String id) async {
    final users = await getAllUsers();
    final db = FirebaseFirestore.instance;

    await db.collection('notifications').doc(id).delete();

    int i = 0;
    WriteBatch batch = db.batch();
    for (final user in users) {
      if (user.uid.isEmpty) continue;
      final ref = db.collection('users').doc(user.uid).collection('notifications').doc(id);
      batch.delete(ref);
      i++;
      if (i % 500 == 0) {
        await batch.commit();
        batch = db.batch();
      }
    }
    if (i % 500 != 0) {
      await batch.commit();
    }
  }

  Future<void> clearAllTestData() async {
    await FirestoreService<dynamic>(collectionPath: 'events', fromMap: (_, __) => null, toMap: (_) => {}).clearCollection();
    await FirestoreService<dynamic>(collectionPath: 'announcements', fromMap: (_, __) => null, toMap: (_) => {}).clearCollection();
    await FirestoreService<dynamic>(collectionPath: 'gallery', fromMap: (_, __) => null, toMap: (_) => {}).clearCollection();
    await FirestoreService<dynamic>(collectionPath: 'subscriptions', fromMap: (_, __) => null, toMap: (_) => {}).clearCollection();
    await FirestoreService<dynamic>(collectionPath: 'payments', fromMap: (_, __) => null, toMap: (_) => {}).clearCollection();
  }
  Future<Map<String, dynamic>> bulkUploadMembership(List<Map<String, dynamic>> parsedData) async {
    final batch = FirebaseFirestore.instance.batch();
    int successCount = 0;
    int errorCount = 0;
    List<String> errors = [];

    for (var row in parsedData) {
      try {
        final String uidStr = row['UserId']?.toString().trim() ?? '';
        final DateTime? paymentDate = row['PaymentDate'] as DateTime?;
        final double amount = (row['Amount'] as num?)?.toDouble() ?? 0.0;

        if (uidStr.isEmpty || paymentDate == null) {
          errorCount++;
          errors.add("Invalid row data: Missing UserId or PaymentDate.");
          continue;
        }

        String finalUid = uidStr;
        
        // Match by legacy User ID (what the Excel has) to the actual Firebase UID if they are registered
        final matchedLegacy = await _userService.getWhere(field: 'legacyUserId', isEqualTo: uidStr);
        if (matchedLegacy.isNotEmpty) {
          finalUid = matchedLegacy.first.uid;
        } else {
          // If not found by legacy, check if they used their real UID in the Excel
          final matchedUid = await _userService.getById(uidStr);
          if (matchedUid != null) {
            finalUid = matchedUid.uid;
          }
        }

        final renewalDate = DateTime(paymentDate.year + 1, paymentDate.month, paymentDate.day);
        final isExpired = renewalDate.isBefore(DateTime.now());

        final membershipData = {
          'paymentDate': Timestamp.fromDate(paymentDate),
          'renewalDate': Timestamp.fromDate(renewalDate),
          'amount': amount,
          'status': isExpired ? 'expired' : 'active',
        };

        // Update the user's document directly with the membership map
        final userRef = FirebaseFirestore.instance.collection('users').doc(finalUid);
        batch.set(userRef, {
          'membership': membershipData,
          if (finalUid != uidStr) 'legacyUserId': uidStr, 
        }, SetOptions(merge: true));

        successCount++;
      } catch (e) {
        errorCount++;
        errors.add("Error processing row: $e");
      }
    }

    if (successCount > 0) {
      await batch.commit();
    }

    return {
      'successCount': successCount,
      'errorCount': errorCount,
      'errors': errors,
    };
  }

  Future<List<UserModel>> getAllUsersWithMembership() async {
    final users = await _userService.getAll();
    return users.where((u) => u.membership != null).toList();
  }
}
