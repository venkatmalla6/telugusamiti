import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/subscription_model.dart';
import '../../../repositories/payment_repository.dart';
import '../../../providers/auth_provider.dart';

// Provider just for this screen
final subscriptionHistoryProvider = FutureProvider.autoDispose<List<SubscriptionModel>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return [];
  
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getUserSubscriptions(user.uid);
});

class SubscriptionHistoryScreen extends ConsumerWidget {
  const SubscriptionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(subscriptionHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription History'),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
      ),
      body: subsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (subscriptions) {
          if (subscriptions.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.card_membership,
              title: 'No Subscriptions',
              subtitle: 'You have not subscribed to any plan yet.',
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              final sub = subscriptions[index];
              return _SubscriptionTile(subscription: sub);
            },
          );
        },
      ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  final SubscriptionModel subscription;
  const _SubscriptionTile({required this.subscription});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (subscription.status) {
      case SubscriptionStatus.active:
        statusColor = AppColors.success;
        break;
      case SubscriptionStatus.expired:
        statusColor = AppColors.error;
        break;
      case SubscriptionStatus.cancelled:
        statusColor = Colors.grey;
        break;
      case SubscriptionStatus.pending:
        statusColor = Colors.orange;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subscription.planName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    subscription.status.name.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DateColumn('Valid From', subscription.startDate),
                _DateColumn('Valid Until', subscription.endDate),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Amount', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      '₹${subscription.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateColumn extends StatelessWidget {
  final String label;
  final DateTime date;
  const _DateColumn(this.label, this.date);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          DateFormat('dd MMM yyyy').format(date),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
