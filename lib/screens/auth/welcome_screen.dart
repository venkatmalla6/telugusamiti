import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.diversity_1, size: 120, color: AppColors.primaryMaroon),
              const SizedBox(height: 32),
              Text(
                'Welcome to',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                'Telugu Samiti',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.primaryMaroon,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Connecting the community across Tamil Nadu.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Login with Email',
                onPressed: () => context.push('/login'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
