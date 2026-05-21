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
import '../screens/dashboards/super_admin_dashboard.dart';
import '../screens/dashboards/volunteer_dashboard.dart';
import '../screens/dashboards/user_dashboard.dart';
import '../screens/features/super_admin/manage_admins_screen.dart';
import '../screens/features/super_admin/admin_permissions_screen.dart';
import '../screens/features/super_admin/organization_settings_screen.dart';
import '../screens/features/super_admin/audit_logs_screen.dart';
import '../screens/features/volunteer/scan_qr_screen.dart';
import '../screens/features/volunteer/qr_validation_screen.dart';
import '../screens/features/announcements/create_announcement_screen.dart';

import '../screens/features/profile/edit_profile_screen.dart';
import '../screens/features/profile/family_members_screen.dart';
import '../screens/features/profile/add_family_member_screen.dart';
import '../screens/features/membership/membership_plans_screen.dart';
import '../screens/features/membership/payment_history_screen.dart';
import '../screens/features/membership/subscription_history_screen.dart';
import '../screens/features/notifications/notifications_screen.dart';

import '../screens/features/events/event_detail_screen.dart';
import '../screens/features/events/event_registration_screen.dart';
import '../screens/features/events/ticket_screen.dart';
import '../screens/dashboards/admin/admin_events_screen.dart';
import '../screens/dashboards/admin/create_event_screen.dart';
import '../screens/dashboards/admin/admin_member_detail_screen.dart';
import '../screens/dashboards/admin/admin_send_notification_screen.dart';

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
              return '/super-admin';
            case UserRole.admin:
              return '/admin';
            case UserRole.volunteer:
              return '/volunteer';
            case UserRole.user:
            default:
              return '/user';
          }
        }

        // Route Protection
        final isSuperAdminRoute = state.matchedLocation.startsWith('/super-admin');
        final isAdminRoute = state.matchedLocation.startsWith('/admin');
        final isVolunteerRoute = state.matchedLocation.startsWith('/volunteer');

        if (isSuperAdminRoute && user.role != UserRole.superAdmin) {
          return '/user'; // unauthorized
        }

        if (isAdminRoute && user.role != UserRole.admin && user.role != UserRole.superAdmin) {
          return '/user'; // unauthorized
        }

        if (isVolunteerRoute && user.role == UserRole.user) {
          return '/user'; // unauthorized
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
        path: '/super-admin',
        builder: (context, state) => const SuperAdminDashboard(),
      ),
      GoRoute(
        path: '/super-admin/manage-admins',
        builder: (context, state) => const ManageAdminsScreen(),
      ),
      GoRoute(
        path: '/super-admin/manage-admins/permissions/:id',
        builder: (context, state) => AdminPermissionsScreen(adminId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/super-admin/settings',
        builder: (context, state) => const OrganizationSettingsScreen(),
      ),
      GoRoute(
        path: '/super-admin/audit-logs',
        builder: (context, state) => const AuditLogsScreen(),
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
        path: '/volunteer/scan',
        builder: (context, state) => const ScanQRScreen(),
      ),
      GoRoute(
        path: '/volunteer/validate/:eventId/:registrationId',
        builder: (context, state) => QRValidationScreen(
          eventId: state.pathParameters['eventId']!,
          registrationId: state.pathParameters['registrationId']!,
        ),
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
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/events/:id',
        builder: (context, state) => EventDetailScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/events/:id/register',
        builder: (context, state) => EventRegistrationScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/events/:eventId/ticket/:registrationId',
        builder: (context, state) => TicketScreen(
          eventId: state.pathParameters['eventId']!,
          registrationId: state.pathParameters['registrationId']!,
        ),
      ),
      GoRoute(
        path: '/admin/events',
        builder: (context, state) => const AdminEventsScreen(),
      ),
      GoRoute(
        path: '/admin/events/create',
        builder: (context, state) => const CreateEventScreen(),
      ),
      GoRoute(
        path: '/admin/events/edit/:id',
        builder: (context, state) => CreateEventScreen(eventId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/admin/members/:uid',
        builder: (context, state) => AdminMemberDetailScreen(uid: state.pathParameters['uid']!),
      ),
      GoRoute(
        path: '/admin/notifications/send',
        builder: (context, state) => const AdminSendNotificationScreen(),
      ),
    ],
  );
});
