import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // GoRouter redirect handles the actual navigation based on auth state.
    // This screen just shows branding while Firebase initializes or loads user.
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primaryMaroon,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.diversity_1, size: 100, color: AppColors.primaryGold),
            SizedBox(height: 24),
            Text(
              'Telugu Samiti\nTamil Nadu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(color: AppColors.primaryGold),
          ],
        ),
      ),
    );
  }
}
