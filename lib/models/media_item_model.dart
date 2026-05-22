import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MediaItem extends Equatable {
  final String id;
  final String type; // 'photo' or 'video'
  final String storagePath;
  final String downloadUrl;
  final String? thumbUrl; // only for video
  final int sizeBytes;
  final String? caption; // optional caption
  final Timestamp uploadedAt;

  const MediaItem({
    required this.id,
    required this.type,
    required this.storagePath,
    required this.downloadUrl,
    this.thumbUrl,
    required this.sizeBytes,
    this.caption,
    required this.uploadedAt,
  });

  factory MediaItem.fromMap(String id, Map<String, dynamic> data) {
    return MediaItem(
      id: id,
      type: data['type'] as String,
      storagePath: data['storagePath'] as String,
      downloadUrl: data['downloadUrl'] as String,
      thumbUrl: data['thumbUrl'] as String?,
      sizeBytes: (data['sizeBytes'] as num).toInt(),
      caption: data['caption'] as String?,
      uploadedAt: data['uploadedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        if (thumbUrl != null) 'thumbUrl': thumbUrl,
        'sizeBytes': sizeBytes,
        if (caption != null) 'caption': caption,
        'uploadedAt': uploadedAt,
      };

  @override
  List<Object?> get props => [id, type, storagePath, downloadUrl, thumbUrl, sizeBytes, caption, uploadedAt];
}
