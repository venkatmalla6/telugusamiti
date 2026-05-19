import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/dashboards/admin_dashboard.dart';
import '../screens/dashboards/volunteer_dashboard.dart';
import '../screens/dashboards/user_dashboard.dart';
import '../screens/features/announcements/create_announcement_screen.dart';

import '../screens/features/profile/edit_profile_screen.dart';
import '../screens/features/profile/family_members_screen.dart';
import '../screens/features/profile/add_family_member_screen.dart';
import '../screens/features/membership/membership_plans_screen.dart';
import '../screens/features/membership/payment_history_screen.dart';
import '../screens/features/membership/subscription_history_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userState = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authState.value != null;
      final isSplash = state.matchedLocation == '/splash';
      final isLoggingIn = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/welcome' || 
                          state.matchedLocation == '/otp' || 
                          state.matchedLocation == '/forgot-password';

      if (authState.isLoading || userState.isLoading) {
        return '/splash';
      }

      if (!isAuth) {
        return isLoggingIn ? null : '/welcome';
      }

      final user = userState.value;
      if (user != null) {
        if (isSplash || isLoggingIn) {
          switch (user.role) {
            case UserRole.superAdmin:
            case UserRole.admin:
              return '/admin';
            case UserRole.volunteer:
              return '/volunteer';
            case UserRole.user:
            default:
              return '/user';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final verificationId = state.extra as String? ?? '';
          return OtpVerificationScreen(verificationId: verificationId);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/create-announcement',
        builder: (context, state) => const CreateAnnouncementScreen(),
      ),
      GoRoute(
        path: '/volunteer',
        builder: (context, state) => const VolunteerDashboard(),
      ),
      GoRoute(
        path: '/user',
        builder: (context, state) => const UserDashboard(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/family',
        builder: (context, state) => const FamilyMembersScreen(),
      ),
      GoRoute(
        path: '/profile/family/add',
        builder: (context, state) => const AddFamilyMemberScreen(),
      ),
      GoRoute(
        path: '/membership/plans',
        builder: (context, state) => const MembershipPlansScreen(),
      ),
      GoRoute(
        path: '/membership/payments',
        builder: (context, state) => const PaymentHistoryScreen(),
      ),
      GoRoute(
        path: '/membership/history',
        builder: (context, state) => const SubscriptionHistoryScreen(),
      ),
    ],
  );
});
