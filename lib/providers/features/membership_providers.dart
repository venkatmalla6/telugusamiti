import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/payment_model.dart';
import '../../models/subscription_model.dart';
import '../../repositories/payment_repository.dart';
import '../auth_provider.dart';
import '../dashboard_providers.dart';
import 'profile_providers.dart';

class MembershipPurchaseState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const MembershipPurchaseState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  MembershipPurchaseState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return MembershipPurchaseState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class MembershipPurchaseNotifier extends Notifier<MembershipPurchaseState> {
  late final PaymentRepository _paymentRepo;

  @override
  MembershipPurchaseState build() {
    _paymentRepo = ref.watch(paymentRepositoryProvider);
    return const MembershipPurchaseState();
  }

  Future<void> purchasePlan({
    required String userId,
    required String userName,
    required String planName,
    required double amount,
    required int durationInDays,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final now = DateTime.now();
      
      // 1. Create and Record Payment
      final payment = PaymentModel(
        id: '', // Firestore will auto-generate document ID on add
        userId: userId,
        userName: userName,
        amount: amount,
        description: 'Payment for $planName',
        createdAt: now,
        status: PaymentStatus.success,
        transactionId: 'TXN_${now.millisecondsSinceEpoch}',
      );
      
      await _paymentRepo.recordPayment(payment);

      // 2. Create and Record Subscription
      final subscription = SubscriptionModel(
        id: '', // Firestore will auto-generate document ID on add
        userId: userId,
        planName: planName,
        amount: amount,
        startDate: now,
        endDate: now.add(Duration(days: durationInDays)),
        status: SubscriptionStatus.active,
      );

      await _paymentRepo.createSubscription(subscription);

      // 3. Invalidate relevant providers to force reload in UI
      ref.invalidate(userSubscriptionProvider);
      ref.invalidate(paymentHistoryProvider);
      ref.invalidate(subscriptionHistoryProvider);

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final membershipPurchaseNotifierProvider =
    NotifierProvider<MembershipPurchaseNotifier, MembershipPurchaseState>(
  MembershipPurchaseNotifier.new,
);

final subscriptionHistoryProvider = FutureProvider.autoDispose<List<SubscriptionModel>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return [];
  
  final repo = ref.watch(paymentRepositoryProvider);
  final subs = await repo.getUserSubscriptions(user.uid);

  // Inject the manually uploaded/legacy membership so it shows in the history list!
  if (user.membership != null) {
    subs.insert(0, SubscriptionModel(
      id: 'bulk_upload_membership',
      userId: user.uid,
      planName: 'Manual Membership',
      amount: user.membership!.amount,
      startDate: user.membership!.paymentDate,
      endDate: user.membership!.renewalDate,
      status: user.membership!.renewalDate.isAfter(DateTime.now()) 
          ? SubscriptionStatus.active 
          : SubscriptionStatus.expired,
    ));
  }

  return subs;
});
