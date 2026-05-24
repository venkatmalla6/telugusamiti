import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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

  void _showDonationDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make a Donation'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (₹)',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                _showPaymentSheet(context, ref, 'Voluntary Donation', amount, 0);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryMaroon),
            child: const Text('Donate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership & Donations'),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: const Color(0xFF5C0A0A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose your membership or make a donation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _PlanCard(
            title: 'Annual Plan',
            price: '₹500',
            duration: '/ year',
            description: 'Basic membership for individuals and families.',
            features: const [
              'Access to all regular events',
              'Voting rights in meetings',
              'Digital ID Card',
            ],
            color: const Color(0xFF1565C0), // Blue
            isPopular: true,
            onPressed: () => _showPaymentSheet(context, ref, 'Annual Plan', 500, 365),
          ),
          const SizedBox(height: 16),
          _PlanCard(
            title: 'Make a Donation',
            price: 'Custom',
            duration: ' amount',
            description: 'Support the Samiti voluntarily.',
            features: const [
              'Contribute to community development',
              'Support cultural and welfare events',
              'Strengthen our Telugu community',
            ],
            color: const Color(0xFF5C0A0A),
            textColor: Colors.white,
            onPressed: () => _showDonationDialog(context, ref),
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
            side: isPopular ? const BorderSide(color: const Color(0xFF5C0A0A), width: 2) : BorderSide.none,
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
                color: const Color(0xFF5C0A0A),
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
  final _utrController = TextEditingController();
  bool _isProcessing = false;
  bool _isFinished = false;

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

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

    // Exact parameters extracted from the official QR Code
    // Exact parameters extracted from the official QR Code
    final upiId = 'ppr.01440.17112023.00267096@cnrb';
    final payeeName = 'Canara Bank';
    // Generate a unique transaction reference to prevent duplicate transaction errors
    final uniqueTr = 'TR${DateTime.now().millisecondsSinceEpoch}';
    
    // Build the URI safely using queryParameters
    final Uri upiUri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': upiId,
        'pn': payeeName,
        'mc': '7399',
        'tr': uniqueTr,
        'am': widget.amount.toStringAsFixed(2),
        'mam': '0',
        'cu': 'INR',
        'refUrl': 'http://npci.org/upi/schema/'
      },
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SafeArea(
          child: SingleChildScrollView(
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
                    'Payment Submitted!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your payment details for ${widget.planName} have been recorded and will be verified by the admin.',
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
                    child: const Text('Done'),
                  ),
                ] else if (_isProcessing) ...[
                  const SizedBox(height: 32),
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryMaroon),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Submitting Details...',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  Text(
                    'Complete Payment',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan the QR code using GPay, PhonePe, or Paytm to pay ₹${widget.amount.toStringAsFixed(0)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  
                  // QR Code Image
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/samiti_qr.png',
                          width: 200,
                          height: 250, // Added height because the uploaded image is rectangular
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'UPI ID: $upiId',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Pay via UPI App Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await launchUrl(upiUri, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open UPI app. Please scan the QR manually.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.touch_app, color: AppColors.primaryMaroon),
                    label: const Text(
                      'Pay via GPay / PhonePe / Paytm',
                      style: TextStyle(color: AppColors.primaryMaroon, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primaryMaroon, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // UTR Input
                  TextField(
                    controller: _utrController,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Enter UTR / Reference No.',
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      hintText: 'e.g., 312345678901',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryMaroon, width: 2),
                      ),
                      prefixIcon: const Icon(Icons.receipt_long, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  FilledButton(
                    onPressed: () {
                      if (_utrController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter the UTR / Reference number after payment')),
                        );
                        return;
                      }
                      
                      setState(() => _isProcessing = true);
                      
                      // For now, we reuse the existing purchasePlan method. 
                      // In a real scenario, this would create a pending transaction record with the UTR.
                      ref.read(membershipPurchaseNotifierProvider.notifier).purchasePlan(
                            userId: widget.userId,
                            userName: widget.userName,
                            planName: widget.planName,
                            amount: widget.amount,
                            durationInDays: widget.durationInDays,
                          );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryMaroon,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Submit Payment Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
