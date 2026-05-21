import '../core/utils/firebase_timestamp_converters.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final bool isPublished;
  final int maxCapacity;
  final bool hasFood;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.location,
    required this.startDate,
    required this.endDate,
    this.isPublished = false,
    this.maxCapacity = 0,
    this.hasFood = false,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String documentId) {
    return EventModel(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      location: map['location'] ?? '',
      startDate: timestampToDateTime(map['startDate']) ?? DateTime.now(),
      endDate: timestampToDateTime(map['endDate']) ?? DateTime.now(),
      isPublished: map['isPublished'] ?? false,
      maxCapacity: map['maxCapacity'] ?? 0,
      hasFood: map['hasFood'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'location': location,
      'startDate': dateTimeToTimestamp(startDate),
      'endDate': dateTimeToTimestamp(endDate),
      'isPublished': isPublished,
      'maxCapacity': maxCapacity,
      'hasFood': hasFood,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    bool? isPublished,
    int? maxCapacity,
    bool? hasFood,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isPublished: isPublished ?? this.isPublished,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      hasFood: hasFood ?? this.hasFood,
    );
  }
}
