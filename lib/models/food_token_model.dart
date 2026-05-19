import '../core/utils/firebase_timestamp_converters.dart';

class FoodTokenModel {
  final String id; // The QR Code hash or token ID
  final String eventId;
  final String userId;
  final bool isRedeemed;
  final DateTime? redeemedAt;
  final String? redeemedByVolunteerId;

  FoodTokenModel({
    required this.id,
    required this.eventId,
    required this.userId,
    this.isRedeemed = false,
    this.redeemedAt,
    this.redeemedByVolunteerId,
  });

  factory FoodTokenModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FoodTokenModel(
      id: documentId,
      eventId: map['eventId'] ?? '',
      userId: map['userId'] ?? '',
      isRedeemed: map['isRedeemed'] ?? false,
      redeemedAt: timestampToDateTime(map['redeemedAt']),
      redeemedByVolunteerId: map['redeemedByVolunteerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'isRedeemed': isRedeemed,
      'redeemedAt': dateTimeToTimestamp(redeemedAt),
      'redeemedByVolunteerId': redeemedByVolunteerId,
    };
  }

  FoodTokenModel copyWith({
    String? id,
    String? eventId,
    String? userId,
    bool? isRedeemed,
    DateTime? redeemedAt,
    String? redeemedByVolunteerId,
  }) {
    return FoodTokenModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      isRedeemed: isRedeemed ?? this.isRedeemed,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      redeemedByVolunteerId: redeemedByVolunteerId ?? this.redeemedByVolunteerId,
    );
  }
}
