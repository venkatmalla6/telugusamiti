import '../core/utils/firebase_timestamp_converters.dart';

class GalleryModel {
  final String id;
  final String eventId;
  final String imageUrl;
  final String? caption;
  final String uploadedBy;
  final DateTime uploadedAt;

  GalleryModel({
    required this.id,
    required this.eventId,
    required this.imageUrl,
    this.caption,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  factory GalleryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return GalleryModel(
      id: documentId,
      eventId: map['eventId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'],
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedAt: timestampToDateTime(map['uploadedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'imageUrl': imageUrl,
      'caption': caption,
      'uploadedBy': uploadedBy,
      'uploadedAt': dateTimeToTimestamp(uploadedAt),
    };
  }

  GalleryModel copyWith({
    String? id,
    String? eventId,
    String? imageUrl,
    String? caption,
    String? uploadedBy,
    DateTime? uploadedAt,
  }) {
    return GalleryModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}
