import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/snackbar_utils.dart';
import '../../providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String verificationId;
  const OtpVerificationScreen({super.key, required this.verificationId});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      SnackbarUtils.showError(context, 'Please enter a valid 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider).verifyOTP(widget.verificationId, otp);
      // Success triggers GoRouter redirect
    } catch (e) {
      setState(() => _isLoading = false);
      SnackbarUtils.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'Enter Verification Code',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a 6-digit code to your phone number.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _otpController,
              labelText: 'OTP Code',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.message,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Verify',
              isLoading: _isLoading,
              onPressed: _verify,
            ),
          ],
        ),
      ),
    );
  }
}
