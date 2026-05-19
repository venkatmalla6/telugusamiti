class VolunteerProfileModel {
  final String id; // Matches the User UID
  final List<String> skills;
  final bool isAvailable;
  final List<String> assignedEventIds;
  final int totalHoursLogged;

  VolunteerProfileModel({
    required this.id,
    this.skills = const [],
    this.isAvailable = true,
    this.assignedEventIds = const [],
    this.totalHoursLogged = 0,
  });

  factory VolunteerProfileModel.fromMap(Map<String, dynamic> map, String documentId) {
    return VolunteerProfileModel(
      id: documentId,
      skills: List<String>.from(map['skills'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
      assignedEventIds: List<String>.from(map['assignedEventIds'] ?? []),
      totalHoursLogged: map['totalHoursLogged'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'skills': skills,
      'isAvailable': isAvailable,
      'assignedEventIds': assignedEventIds,
      'totalHoursLogged': totalHoursLogged,
    };
  }

  VolunteerProfileModel copyWith({
    String? id,
    List<String>? skills,
    bool? isAvailable,
    List<String>? assignedEventIds,
    int? totalHoursLogged,
  }) {
    return VolunteerProfileModel(
      id: id ?? this.id,
      skills: skills ?? this.skills,
      isAvailable: isAvailable ?? this.isAvailable,
      assignedEventIds: assignedEventIds ?? this.assignedEventIds,
      totalHoursLogged: totalHoursLogged ?? this.totalHoursLogged,
    );
  }
}
