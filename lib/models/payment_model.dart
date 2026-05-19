import '../core/utils/firebase_timestamp_converters.dart';

enum PaymentStatus { success, failed, pending, refunded }

class PaymentModel {
  final String id;
  final String userId;
  final String? userName; // Denormalized
  final double amount;
  final String currency;
  final String description;
  final String? receiptUrl;
  final DateTime createdAt;
  final PaymentStatus status;
  final String? transactionId;

  PaymentModel({
    required this.id,
    required this.userId,
    this.userName,
    required this.amount,
    this.currency = 'INR',
    required this.description,
    this.receiptUrl,
    required this.createdAt,
    this.status = PaymentStatus.pending,
    this.transactionId,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PaymentModel(
      id: documentId,
      userId: map['userId'] ?? '',
      userName: map['userName'],
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'INR',
      description: map['description'] ?? '',
      receiptUrl: map['receiptUrl'],
      createdAt: timestampToDateTime(map['createdAt']) ?? DateTime.now(),
      status: _parseStatus(map['status']),
      transactionId: map['transactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'currency': currency,
      'description': description,
      'receiptUrl': receiptUrl,
      'createdAt': dateTimeToTimestamp(createdAt),
      'status': status.name,
      'transactionId': transactionId,
    };
  }

  static PaymentStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
        return PaymentStatus.success;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  PaymentModel copyWith({
    String? id,
    String? userId,
    String? userName,
    double? amount,
    String? currency,
    String? description,
    String? receiptUrl,
    DateTime? createdAt,
    PaymentStatus? status,
    String? transactionId,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}
