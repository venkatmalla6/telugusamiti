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
  final int numberOfAdults;
  final int numberOfChildren;
  final bool foodClaimed;
  final DateTime? foodClaimedAt;
  final bool attended;
  final DateTime? attendedAt;

  EventRegistrationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    this.userName,
    required this.registrationDate,
    this.status = RegistrationStatus.pending,
    this.numberOfGuests = 0,
    this.numberOfAdults = 0,
    this.numberOfChildren = 0,
    this.foodClaimed = false,
    this.foodClaimedAt,
    this.attended = false,
    this.attendedAt,
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
      numberOfAdults: map['numberOfAdults'] ?? 0,
      numberOfChildren: map['numberOfChildren'] ?? 0,
      foodClaimed: map['foodClaimed'] ?? false,
      foodClaimedAt: timestampToDateTime(map['foodClaimedAt']),
      attended: map['attended'] ?? false,
      attendedAt: timestampToDateTime(map['attendedAt']),
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
      'numberOfAdults': numberOfAdults,
      'numberOfChildren': numberOfChildren,
      'foodClaimed': foodClaimed,
      'foodClaimedAt': dateTimeToTimestamp(foodClaimedAt),
      'attended': attended,
      'attendedAt': dateTimeToTimestamp(attendedAt),
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
    int? numberOfAdults,
    int? numberOfChildren,
    bool? foodClaimed,
    DateTime? foodClaimedAt,
    bool? attended,
    DateTime? attendedAt,
  }) {
    return EventRegistrationModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      registrationDate: registrationDate ?? this.registrationDate,
      status: status ?? this.status,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      numberOfAdults: numberOfAdults ?? this.numberOfAdults,
      numberOfChildren: numberOfChildren ?? this.numberOfChildren,
      foodClaimed: foodClaimed ?? this.foodClaimed,
      foodClaimedAt: foodClaimedAt ?? this.foodClaimedAt,
      attended: attended ?? this.attended,
      attendedAt: attendedAt ?? this.attendedAt,
    );
  }
}
