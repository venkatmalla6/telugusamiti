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
    final users = await _userService.getAll();
    final activeSubs = await getAllActiveSubscriptions();
    final payments = await getAllPayments();
    final events = await FirebaseFirestore.instance.collection('events').get();

    final totalCollection = payments
        .where((p) => p.status == PaymentStatus.success)
        .fold<double>(0, (sum, p) => sum + p.amount)
        .toInt();

    return {
      'totalMembers': users.length,
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
    final users = await _userService.getAll();
    final batch = FirebaseFirestore.instance.batch();
    
    // Save to global/root notifications
    final globalRef = FirebaseFirestore.instance.collection('notifications').doc();
    batch.set(globalRef, {
      'title': title,
      'body': body,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'type': NotificationType.adminBroadcast.name,
      'topic': 'all_users',
      'data': {'sentBy': sentBy},
    });

    for (final user in users) {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc();
      batch.set(ref, {
        'title': title,
        'body': body,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'type': NotificationType.adminBroadcast.name,
        'topic': 'all_users',
        'targetUid': user.uid,
        'data': {
          'sentBy': sentBy,
          'globalNotificationId': globalRef.id,
        },
      });
    }
    await batch.commit();
  }

  Future<void> clearAllTestData() async {
    await FirestoreService<dynamic>(collectionPath: 'events', fromMap: (_, __) => null, toMap: (_) => {}).clearCollection();
    await FirestoreService<dynamic>(collectionPath: 'announcements', fromMap: (_, __) => null, toMap: (_) => {}).clearCollection();
    await FirestoreService<dynamic>(collectionPath: 'gallery', fromMap: (_, __) => null, toMap: (_) => {}).clearCollection();
    await FirestoreService<dynamic>(collectionPath: 'subscriptions', fromMap: (_, __) => null, toMap: (_) => {}).clearCollection();
    await FirestoreService<dynamic>(collectionPath: 'payments', fromMap: (_, __) => null, toMap: (_) => {}).clearCollection();
  }
}
