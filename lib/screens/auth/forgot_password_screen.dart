import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/snackbar_utils.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      SnackbarUtils.showError(context, 'Please enter your email');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider).sendPasswordReset(_emailController.text.trim());
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Password reset link sent to your email.');
        context.pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      SnackbarUtils.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'Reset Password',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your email address and we will send you a link to reset your password.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _emailController,
              labelText: 'Email Address',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Send Reset Link',
              isLoading: _isLoading,
              onPressed: _resetPassword,
            ),
          ],
        ),
      ),
    );
  }
}
