import '../core/utils/firebase_timestamp_converters.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return NotificationModel(
      id: documentId,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      isRead: map['isRead'] ?? false,
      createdAt: timestampToDateTime(map['createdAt']) ?? DateTime.now(),
      data: map['data'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': dateTimeToTimestamp(createdAt),
      'data': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }
}
