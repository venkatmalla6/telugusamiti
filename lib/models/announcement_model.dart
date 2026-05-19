import '../core/utils/firebase_timestamp_converters.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final String? imageUrl;
  final DateTime createdAt;
  final String authorId;
  final String? targetRole; // e.g., 'volunteer', 'user', or null for all

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.createdAt,
    required this.authorId,
    this.targetRole,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AnnouncementModel(
      id: documentId,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: timestampToDateTime(map['createdAt']) ?? DateTime.now(),
      authorId: map['authorId'] ?? '',
      targetRole: map['targetRole'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'createdAt': dateTimeToTimestamp(createdAt),
      'authorId': authorId,
      'targetRole': targetRole,
    };
  }

  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? message,
    String? imageUrl,
    DateTime? createdAt,
    String? authorId,
    String? targetRole,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      authorId: authorId ?? this.authorId,
      targetRole: targetRole ?? this.targetRole,
    );
  }
}
