import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/snackbar_utils.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authController = ref.read(authControllerProvider);

    try {
      if (_isLogin) {
        await authController.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await authController.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
      // On success, router will auto redirect
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarUtils.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                _isLogin ? 'Welcome Back!' : 'Create Account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'Please sign in to continue.' : 'Sign up to get started.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _emailController,
                labelText: 'Email Address',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _passwordController,
                labelText: 'Password',
                obscureText: true,
                prefixIcon: Icons.lock,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: _isLogin ? 'Login' : 'Sign Up',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isLogin ? "Don't have an account?" : "Already have an account?"),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? 'Sign Up' : 'Login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

