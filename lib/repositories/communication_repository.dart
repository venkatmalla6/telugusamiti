import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/announcement_model.dart';
import '../models/notification_model.dart';
import '../core/services/firestore_service.dart';

final communicationRepositoryProvider = Provider<CommunicationRepository>((ref) {
  return CommunicationRepository();
});

class CommunicationRepository {
  final FirestoreService<AnnouncementModel> _announcementService;

  CommunicationRepository()
      : _announcementService = FirestoreService<AnnouncementModel>(
          collectionPath: 'announcements',
          fromMap: AnnouncementModel.fromMap,
          toMap: (item) => item.toMap(),
        );

  Future<String> postAnnouncement(AnnouncementModel announcement) =>
      _announcementService.add(announcement);

  Stream<List<AnnouncementModel>> streamAnnouncements() {
    return _announcementService.streamAll();
  }

  FirestoreService<NotificationModel> _notificationService(String uid) =>
      FirestoreService<NotificationModel>(
        collectionPath: 'users/$uid/notifications',
        fromMap: NotificationModel.fromMap,
        toMap: (item) => item.toMap(),
      );

  Future<void> sendNotification(String uid, NotificationModel notification) async {
    await _notificationService(uid).set(notification.id, notification);
  }
}
