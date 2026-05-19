import '../core/utils/firebase_timestamp_converters.dart';

class AttendanceModel {
  final String id;
  final String eventId;
  final String userId;
  final String? userName;
  final DateTime checkInTime;
  final String? checkedInByVolunteerId;

  AttendanceModel({
    required this.id,
    required this.eventId,
    required this.userId,
    this.userName,
    required this.checkInTime,
    this.checkedInByVolunteerId,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AttendanceModel(
      id: documentId,
      eventId: map['eventId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'],
      checkInTime: timestampToDateTime(map['checkInTime']) ?? DateTime.now(),
      checkedInByVolunteerId: map['checkedInByVolunteerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'checkInTime': dateTimeToTimestamp(checkInTime),
      'checkedInByVolunteerId': checkedInByVolunteerId,
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userName,
    DateTime? checkInTime,
    String? checkedInByVolunteerId,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      checkInTime: checkInTime ?? this.checkInTime,
      checkedInByVolunteerId: checkedInByVolunteerId ?? this.checkedInByVolunteerId,
    );
  }
}
