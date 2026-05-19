import '../core/utils/firebase_timestamp_converters.dart';

enum SubscriptionStatus { active, expired, cancelled, pending }

class SubscriptionModel {
  final String id;
  final String userId;
  final String planName;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.planName,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.status = SubscriptionStatus.pending,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SubscriptionModel(
      id: documentId,
      userId: map['userId'] ?? '',
      planName: map['planName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      startDate: timestampToDateTime(map['startDate']) ?? DateTime.now(),
      endDate: timestampToDateTime(map['endDate']) ?? DateTime.now(),
      status: _parseStatus(map['status']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'planName': planName,
      'amount': amount,
      'startDate': dateTimeToTimestamp(startDate),
      'endDate': dateTimeToTimestamp(endDate),
      'status': status.name,
    };
  }

  static SubscriptionStatus _parseStatus(String? statusString) {
    if (statusString == null) return SubscriptionStatus.pending;
    switch (statusString.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      default:
        return SubscriptionStatus.pending;
    }
  }

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? planName,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    SubscriptionStatus? status,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planName: planName ?? this.planName,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }
}
