import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import '../models/subscription_model.dart';
import '../core/services/firestore_service.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

class PaymentRepository {
  final FirestoreService<PaymentModel> _paymentService;
  final FirestoreService<SubscriptionModel> _subscriptionService;

  PaymentRepository()
      : _paymentService = FirestoreService<PaymentModel>(
          collectionPath: 'payments',
          fromMap: PaymentModel.fromMap,
          toMap: (item) => item.toMap(),
        ),
        _subscriptionService = FirestoreService<SubscriptionModel>(
          collectionPath: 'subscriptions',
          fromMap: SubscriptionModel.fromMap,
          toMap: (item) => item.toMap(),
        );

  Future<String> recordPayment(PaymentModel payment) => _paymentService.add(payment);
  Future<List<PaymentModel>> getUserPayments(String userId) =>
      _paymentService.getWhere(field: 'userId', isEqualTo: userId);

  Future<String> createSubscription(SubscriptionModel sub) => _subscriptionService.add(sub);
  Future<List<SubscriptionModel>> getUserSubscriptions(String userId) =>
      _subscriptionService.getWhere(field: 'userId', isEqualTo: userId);
}
