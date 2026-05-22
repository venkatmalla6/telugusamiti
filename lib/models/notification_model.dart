import '../core/utils/firebase_timestamp_converters.dart';

enum NotificationType {
  eventReminder,
  membershipExpiry,
  announcement,
  adminBroadcast,
  general,
}

extension NotificationTypeX on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.eventReminder:
        return 'Event Reminder';
      case NotificationType.membershipExpiry:
        return 'Membership Expiry';
      case NotificationType.announcement:
        return 'Announcement';
      case NotificationType.adminBroadcast:
        return 'Admin Broadcast';
      case NotificationType.general:
        return 'General';
    }
  }

  static NotificationType fromString(String? value) {
    switch (value) {
      case 'eventReminder':
        return NotificationType.eventReminder;
      case 'membershipExpiry':
        return NotificationType.membershipExpiry;
      case 'announcement':
        return NotificationType.announcement;
      case 'adminBroadcast':
        return NotificationType.adminBroadcast;
      default:
        return NotificationType.general;
    }
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  final NotificationType type;
  final String? topic;
  final String? targetUid;
  final String? imageUrl;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
    this.data,
    this.type = NotificationType.general,
    this.topic,
    this.targetUid,
    this.imageUrl,
  });

  factory NotificationModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    return NotificationModel(
      id: documentId,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: timestampToDateTime(map['createdAt']) ?? DateTime.now(),
      data: map['data'] != null
          ? Map<String, dynamic>.from(map['data'])
          : null,
      type: NotificationTypeX.fromString(map['type']),
      topic: map['topic'],
      targetUid: map['targetUid'],
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': dateTimeToTimestamp(createdAt),
      'data': data,
      'type': type.name,
      'topic': topic,
      'targetUid': targetUid,
      'imageUrl': imageUrl,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
    NotificationType? type,
    String? topic,
    String? targetUid,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
      type: type ?? this.type,
      topic: topic ?? this.topic,
      targetUid: targetUid ?? this.targetUid,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
