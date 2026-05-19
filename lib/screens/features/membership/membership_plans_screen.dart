import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

class MembershipPlansScreen extends ConsumerWidget {
  const MembershipPlansScreen({super.key});

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
        children: const [
          Text(
            'Choose a plan that fits you best',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          _PlanCard(
            title: 'Annual Plan',
            price: '₹500',
            duration: '/ year',
            description: 'Basic membership for individuals.',
            features: [
              'Access to all regular events',
              'Single voting right',
              'Digital ID Card',
            ],
            color: Color(0xFF1565C0), // Blue
          ),
          SizedBox(height: 16),
          _PlanCard(
            title: 'Family Plan',
            price: '₹1000',
            duration: '/ year',
            description: 'Best for families.',
            features: [
              'Add up to 4 family members',
              'Access to all regular events',
              'Priority seating at events',
              'Digital ID Cards for family',
            ],
            color: AppColors.primaryMaroon,
            isPopular: true,
          ),
          SizedBox(height: 16),
          _PlanCard(
            title: 'Lifetime Member',
            price: '₹5000',
            duration: ' one-time',
            description: 'Support the Samiti for life.',
            features: [
              'Lifetime access to events',
              'VIP seating & special recognition',
              'Free family member additions',
              'Premium Gold ID Card',
            ],
            color: AppColors.primaryGold,
            textColor: Colors.black,
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

  const _PlanCard({
    required this.title,
    required this.price,
    required this.duration,
    required this.description,
    required this.features,
    required this.color,
    this.textColor = Colors.white,
    this.isPopular = false,
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
                        onPressed: () {
                          // TODO: Connect to Payment Gateway (Razorpay/Stripe)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Payment gateway integration pending')),
                          );
                        },
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
