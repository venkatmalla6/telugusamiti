import '../core/utils/firebase_timestamp_converters.dart';

class FamilyMemberModel {
  final String id;
  final String name;
  final String relationship;
  final DateTime? dateOfBirth;
  final String? gender;

  FamilyMemberModel({
    required this.id,
    required this.name,
    required this.relationship,
    this.dateOfBirth,
    this.gender,
  });

  factory FamilyMemberModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FamilyMemberModel(
      id: documentId,
      name: map['name'] ?? '',
      relationship: map['relationship'] ?? '',
      dateOfBirth: timestampToDateTime(map['dateOfBirth']),
      gender: map['gender'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relationship': relationship,
      'dateOfBirth': dateTimeToTimestamp(dateOfBirth),
      'gender': gender,
    };
  }

  FamilyMemberModel copyWith({
    String? id,
    String? name,
    String? relationship,
    DateTime? dateOfBirth,
    String? gender,
  }) {
    return FamilyMemberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
    );
  }
}
