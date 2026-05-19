import '../core/utils/firebase_timestamp_converters.dart';

class AdminProfileModel {
  final String id; // Matches User UID
  final String department;
  final List<String> permissions;
  final DateTime lastLoginAt;

  AdminProfileModel({
    required this.id,
    this.department = 'General',
    this.permissions = const [],
    required this.lastLoginAt,
  });

  factory AdminProfileModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AdminProfileModel(
      id: documentId,
      department: map['department'] ?? 'General',
      permissions: List<String>.from(map['permissions'] ?? []),
      lastLoginAt: timestampToDateTime(map['lastLoginAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'department': department,
      'permissions': permissions,
      'lastLoginAt': dateTimeToTimestamp(lastLoginAt),
    };
  }

  AdminProfileModel copyWith({
    String? id,
    String? department,
    List<String>? permissions,
    DateTime? lastLoginAt,
  }) {
    return AdminProfileModel(
      id: id ?? this.id,
      department: department ?? this.department,
      permissions: permissions ?? this.permissions,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
