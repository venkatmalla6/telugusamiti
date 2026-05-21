import '../core/utils/firebase_timestamp_converters.dart';

class AuditLogModel {
  final String id;
  final String actionType;
  final String performedBy; // UID of admin
  final String? targetId; // UID of affected user, or setting ID
  final Map<String, dynamic> details;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.actionType,
    required this.performedBy,
    this.targetId,
    this.details = const {},
    required this.timestamp,
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AuditLogModel(
      id: documentId,
      actionType: map['actionType'] ?? 'unknown',
      performedBy: map['performedBy'] ?? '',
      targetId: map['targetId'],
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      timestamp: timestampToDateTime(map['timestamp']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'actionType': actionType,
      'performedBy': performedBy,
      'targetId': targetId,
      'details': details,
      'timestamp': dateTimeToTimestamp(timestamp),
    };
  }
}
