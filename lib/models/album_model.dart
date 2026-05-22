import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Album extends Equatable {
  final String id;
  final String title;
  final String category;
  final String coverUrl;
  final String createdBy;
  final Timestamp createdAt;

  const Album({
    required this.id,
    required this.title,
    required this.category,
    required this.coverUrl,
    required this.createdBy,
    required this.createdAt,
  });

  factory Album.fromMap(String id, Map<String, dynamic> data) {
    return Album(
      id: id,
      title: data['title'] as String,
      category: data['category'] as String,
      coverUrl: data['coverUrl'] as String,
      createdBy: data['createdBy'] as String,
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'coverUrl': coverUrl,
        'createdBy': createdBy,
        'createdAt': createdAt,
      };

  @override
  List<Object?> get props => [id, title, category, coverUrl, createdBy, createdAt];
}
