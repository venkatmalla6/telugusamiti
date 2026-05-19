import '../core/utils/firebase_timestamp_converters.dart';

enum RegistrationStatus { pending, confirmed, cancelled }

class EventRegistrationModel {
  final String id;
  final String eventId;
  final String userId;
  final String? userName; // Denormalized
  final DateTime registrationDate;
  final RegistrationStatus status;
  final int numberOfGuests;

  EventRegistrationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    this.userName,
    required this.registrationDate,
    this.status = RegistrationStatus.pending,
    this.numberOfGuests = 0,
  });

  factory EventRegistrationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return EventRegistrationModel(
      id: documentId,
      eventId: map['eventId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'],
      registrationDate: timestampToDateTime(map['registrationDate']) ?? DateTime.now(),
      status: _parseStatus(map['status']),
      numberOfGuests: map['numberOfGuests'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'registrationDate': dateTimeToTimestamp(registrationDate),
      'status': status.name,
      'numberOfGuests': numberOfGuests,
    };
  }

  static RegistrationStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed': return RegistrationStatus.confirmed;
      case 'cancelled': return RegistrationStatus.cancelled;
      default: return RegistrationStatus.pending;
    }
  }

  EventRegistrationModel copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userName,
    DateTime? registrationDate,
    RegistrationStatus? status,
    int? numberOfGuests,
  }) {
    return EventRegistrationModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      registrationDate: registrationDate ?? this.registrationDate,
      status: status ?? this.status,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
    );
  }
}
