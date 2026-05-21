import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/features/membership_providers.dart';

class MembershipPlansScreen extends ConsumerWidget {
  const MembershipPlansScreen({super.key});

  void _showPaymentSheet(BuildContext context, WidgetRef ref, String planName, double amount, int durationInDays) {
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to purchase a membership')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PaymentBottomSheet(
          userId: user.uid,
          userName: user.displayName ?? 'Member',
          planName: planName,
          amount: amount,
          durationInDays: durationInDays,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Plans'),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose a plan that fits you best',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _PlanCard(
            title: 'Annual Plan',
            price: '₹500',
            duration: '/ year',
            description: 'Basic membership for individuals.',
            features: const [
              'Access to all regular events',
              'Single voting right',
              'Digital ID Card',
            ],
            color: const Color(0xFF1565C0), // Blue
            onPressed: () => _showPaymentSheet(context, ref, 'Annual Plan', 500, 365),
          ),
          const SizedBox(height: 16),
          _PlanCard(
            title: 'Family Plan',
            price: '₹1000',
            duration: '/ year',
            description: 'Best for families.',
            features: const [
              'Add up to 4 family members',
              'Access to all regular events',
              'Priority seating at events',
              'Digital ID Cards for family',
            ],
            color: AppColors.primaryMaroon,
            isPopular: true,
            onPressed: () => _showPaymentSheet(context, ref, 'Family Plan', 1000, 365),
          ),
          const SizedBox(height: 16),
          _PlanCard(
            title: 'Lifetime Member',
            price: '₹5000',
            duration: ' one-time',
            description: 'Support the Samiti for life.',
            features: const [
              'Lifetime access to events',
              'VIP seating & special recognition',
              'Free family member additions',
              'Premium Gold ID Card',
            ],
            color: AppColors.primaryGold,
            textColor: Colors.black,
            onPressed: () => _showPaymentSheet(context, ref, 'Lifetime Member', 5000, 36500),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String duration;
  final String description;
  final List<String> features;
  final Color color;
  final Color textColor;
  final bool isPopular;
  final VoidCallback onPressed;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.duration,
    required this.description,
    required this.features,
    required this.color,
    this.textColor = Colors.white,
    this.isPopular = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPopular ? const BorderSide(color: AppColors.primaryGold, width: 2) : BorderSide.none,
          ),
          elevation: isPopular ? 8 : 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(price, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor)),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 4),
                          child: Text(duration, style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.8))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(description, textAlign: TextAlign.center, style: TextStyle(color: textColor.withValues(alpha: 0.9), fontSize: 13)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...features.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: color, size: 20),
                              const SizedBox(width: 12),
                              Expanded(child: Text(f, style: const TextStyle(fontSize: 14))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: onPressed,
                        style: FilledButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: textColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Select Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isPopular)
          Positioned(
            top: -12,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryGold,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: const Text(
                'MOST POPULAR',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
              ),
            ),
          ),
      ],
    );
  }
}

class _PaymentBottomSheet extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String planName;
  final double amount;
  final int durationInDays;

  const _PaymentBottomSheet({
    required this.userId,
    required this.userName,
    required this.planName,
    required this.amount,
    required this.durationInDays,
  });

  @override
  ConsumerState<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends ConsumerState<_PaymentBottomSheet> {
  String _selectedMethod = 'UPI';
  bool _isProcessing = false;
  bool _isFinished = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<MembershipPurchaseState>(
      membershipPurchaseNotifierProvider,
      (prev, next) {
        if (next.isSuccess) {
          setState(() {
            _isProcessing = false;
            _isFinished = true;
          });
        } else if (next.error != null) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!), backgroundColor: AppColors.error),
          );
        }
      },
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isFinished) ...[
              const Icon(Icons.check_circle, color: AppColors.success, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Payment Successful!',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                'Your subscription to ${widget.planName} is now active.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pop(context); // Close plans screen
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Membership'),
              ),
            ] else if (_isProcessing) ...[
              const SizedBox(height: 32),
              const Center(
                child: CircularProgressIndicator(color: AppColors.primaryMaroon),
              ),
              const SizedBox(height: 24),
              const Text(
                'Processing Payment...',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Please do not close the app or go back.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 32),
            ] else ...[
              Text(
                'Payment Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.planName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  Text('₹${widget.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryMaroon)),
                ],
              ),
              const Divider(height: 24),
              const Text('Choose Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              _PaymentMethodOption(
                title: 'UPI (GPay / PhonePe / Paytm)',
                value: 'UPI',
                groupValue: _selectedMethod,
                icon: Icons.account_balance_wallet_outlined,
                onChanged: (val) => setState(() => _selectedMethod = val!),
              ),
              _PaymentMethodOption(
                title: 'Credit / Debit Card',
                value: 'Card',
                groupValue: _selectedMethod,
                icon: Icons.credit_card_outlined,
                onChanged: (val) => setState(() => _selectedMethod = val!),
              ),
              _PaymentMethodOption(
                title: 'Net Banking',
                value: 'NetBanking',
                groupValue: _selectedMethod,
                icon: Icons.account_balance_outlined,
                onChanged: (val) => setState(() => _selectedMethod = val!),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  setState(() => _isProcessing = true);
                  Future.delayed(const Duration(seconds: 1), () {
                    ref.read(membershipPurchaseNotifierProvider.notifier).purchasePlan(
                          userId: widget.userId,
                          userName: widget.userName,
                          planName: widget.planName,
                          amount: widget.amount,
                          durationInDays: widget.durationInDays,
                        );
                  });
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Pay ₹${widget.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  final String title;
  final String value;
  final String groupValue;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _PaymentMethodOption({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primaryMaroon : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: AppColors.primaryMaroon,
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        secondary: Icon(icon, color: isSelected ? AppColors.primaryMaroon : Colors.grey),
      ),
    );
  }
}
