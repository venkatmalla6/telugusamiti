import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import '../core/services/firestore_service.dart';

final communicationRepositoryProvider = Provider<CommunicationRepository>((ref) {
  return CommunicationRepository();
});

class CommunicationRepository {


  FirestoreService<NotificationModel> _notificationService(String uid) =>
      FirestoreService<NotificationModel>(
        collectionPath: 'users/$uid/notifications',
        fromMap: NotificationModel.fromMap,
        toMap: (item) => item.toMap(),
      );

  Future<void> sendNotification(String uid, NotificationModel notification) async {
    await _notificationService(uid).set(notification.id, notification);
  }

  Future<void> markNotificationAsRead(String uid, String notificationId) async {
    await _notificationService(uid).update(notificationId, {'isRead': true});
  }

  Future<void> clearAllNotifications(String uid) async {
    await _notificationService(uid).clearCollection();
  }
}
