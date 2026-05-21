import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/subscription_model.dart';
import '../models/payment_model.dart';
import '../models/event_registration_model.dart';
import '../repositories/admin_repository.dart';

// ─── Analytics ───────────────────────────────────────────────────────────────
final adminAnalyticsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  return ref.watch(adminRepositoryProvider).getAnalyticsStats();
});

// ─── All Users Stream ─────────────────────────────────────────────────────────
final allUsersStreamProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  return ref.watch(adminRepositoryProvider).streamAllUsers();
});

// ─── Search Query ─────────────────────────────────────────────────────────────
class _StringNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final adminSearchQueryProvider = NotifierProvider<_StringNotifier, String>(_StringNotifier.new);

final adminSearchResultsProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final query = ref.watch(adminSearchQueryProvider);
  final repo = ref.watch(adminRepositoryProvider);

  if (query.isEmpty) {
    return repo.getAllUsers();
  }

  final isPhone = RegExp(r'^[+\d]+$').hasMatch(query) && query.length >= 6;
  if (isPhone) {
    return repo.searchUsersByPhone(query);
  }
  return repo.searchUsersByName(query);
});

// ─── Member Filter ────────────────────────────────────────────────────────────
enum MemberFilter { all, active, expired, pending }

class _MemberFilterNotifier extends Notifier<MemberFilter> {
  @override
  MemberFilter build() => MemberFilter.all;
  void set(MemberFilter value) => state = value;
}

final memberFilterProvider = NotifierProvider<_MemberFilterNotifier, MemberFilter>(_MemberFilterNotifier.new);

// ─── User Detail ──────────────────────────────────────────────────────────────
final adminUserDetailProvider = FutureProvider.family.autoDispose<UserModel?, String>((ref, uid) {
  return ref.watch(adminRepositoryProvider).getUserById(uid);
});

final adminUserSubscriptionProvider = FutureProvider.family.autoDispose<SubscriptionModel?, String>((ref, uid) {
  return ref.watch(adminRepositoryProvider).getUserLatestSubscription(uid);
});

final adminUserPaymentsProvider = FutureProvider.family.autoDispose<List<PaymentModel>, String>((ref, uid) {
  return ref.watch(adminRepositoryProvider).getUserPayments(uid);
});

final adminUserEventHistoryProvider = FutureProvider.family.autoDispose<List<EventRegistrationModel>, String>((ref, uid) {
  return ref.watch(adminRepositoryProvider).getUserEventRegistrations(uid);
});

// ─── Bottom Nav Tab ───────────────────────────────────────────────────────────
class _TabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int value) => state = value;
}

final adminTabProvider = NotifierProvider<_TabNotifier, int>(_TabNotifier.new);
