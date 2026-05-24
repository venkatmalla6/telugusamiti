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
import '../screens/auth/pending_approval_screen.dart';
import '../screens/dashboards/admin_dashboard.dart';
import '../screens/dashboards/super_admin_dashboard.dart';
import '../screens/dashboards/volunteer_dashboard.dart';
import '../screens/dashboards/user_dashboard.dart';
import '../screens/features/gallery/create_album_screen.dart';
import '../screens/features/gallery/album_view_screen.dart';
import '../screens/features/gallery/add_media_screen.dart';
import '../screens/features/gallery/gallery_tab.dart';
import '../models/album_model.dart';
import '../screens/features/super_admin/audit_logs_screen.dart';
import '../screens/dashboards/super_admin/membership_bulk_upload_screen.dart';
import '../screens/dashboards/super_admin/admin_membership_table_screen.dart';
import '../screens/features/super_admin/event_registration_logs_screen.dart';
import '../screens/features/super_admin/event_registrations_detail_screen.dart';
import '../screens/features/volunteer/scan_qr_screen.dart';
import '../screens/dashboards/admin/admin_send_notification_screen.dart';
import '../screens/dashboards/admin/admin_manage_notifications_screen.dart';
import '../screens/dashboards/admin/admin_approve_members_screen.dart';
import '../screens/dashboards/admin/admin_member_detail_screen.dart';
import '../screens/features/volunteer/qr_validation_screen.dart';

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
import '../screens/dashboards/admin/create_event_screen.dart';

/// Provides a [GoRouter] instance that handles authentication redirects
/// and defines all app routes, including the new album‑creation screen.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userState = ref.watch(currentUserProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (authState.isLoading) return '/splash';

      final isLoggedIn = authState.asData?.value != null;
      
      // Unauthenticated users stay within the auth flow.
      if (!isLoggedIn) {
        const authRoutes = [
          '/login',
          '/otp',
          '/forgot_password',
        ];
        if (state.uri.path == '/splash' || !authRoutes.contains(state.uri.path)) {
          return '/login';
        }
        return null;
      }

      if (userState.isLoading) return '/splash';
      if (userState.hasError) return '/login';

      // Authenticated: redirect away from auth screens to the appropriate dashboard.
      final user = userState.asData?.value;
      if (user != null &&
          (state.uri.path.startsWith('/splash') ||
              state.uri.path.startsWith('/welcome') ||
              state.uri.path.startsWith('/login') ||
              state.uri.path.startsWith('/otp') ||
              state.uri.path.startsWith('/pending_approval') ||
              state.uri.path.startsWith('/forgot_password'))) {
              
        // Block unapproved users
        if (user.approvalStatus != ApprovalStatus.approved) {
          if (state.uri.path != '/pending_approval') {
            return '/pending_approval';
          }
          return null; // Already on pending approval screen
        }

        switch (user.role) {
          case UserRole.superAdmin:
            return '/super_admin_dashboard';
          case UserRole.admin:
            return '/admin_dashboard';
          case UserRole.volunteer:
            return '/volunteer_dashboard';
          default:
            return '/user_dashboard';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/otp', builder: (c, s) => OtpVerificationScreen(verificationId: s.extra as String? ?? '')),
      GoRoute(path: '/forgot_password', builder: (c, s) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/pending_approval', 
        builder: (c, s) {
          final user = ref.read(currentUserProvider).value;
          return PendingApprovalScreen(status: user?.approvalStatus ?? ApprovalStatus.pending);
        }
      ),
      GoRoute(path: '/admin_dashboard', builder: (c, s) => const AdminDashboard()),
      GoRoute(path: '/super_admin_dashboard', builder: (c, s) => const SuperAdminDashboard()),
      GoRoute(path: '/volunteer_dashboard', builder: (c, s) => const VolunteerDashboard()),
      GoRoute(path: '/user_dashboard', builder: (c, s) => const UserDashboard()),
      
      // Event routes
      GoRoute(path: '/events/:id', builder: (c, s) => EventDetailScreen(eventId: s.pathParameters['id'] ?? '')),
      GoRoute(path: '/events/:id/register', builder: (c, s) => EventRegistrationScreen(eventId: s.pathParameters['id'] ?? '')),
      GoRoute(path: '/events/:id/ticket/:registrationId', builder: (c, s) => TicketScreen(eventId: s.pathParameters['id'] ?? '', registrationId: s.pathParameters['registrationId'] ?? '')),
      
      // Admin event routes
      GoRoute(path: '/admin/events/create', builder: (c, s) => const CreateEventScreen()),
      GoRoute(path: '/admin/events/edit/:id', builder: (c, s) => CreateEventScreen(eventId: s.pathParameters['id'])),

      // Gallery routes
      GoRoute(path: '/gallery', builder: (c, s) => const GalleryTab()),
      GoRoute(path: '/gallery/create', builder: (c, s) => const CreateAlbumScreen()),
      GoRoute(
        path: '/gallery/album/:id', 
        builder: (c, s) => AlbumViewScreen(album: s.extra as Album),
      ),
      GoRoute(
        path: '/gallery/album/:id/add_media',
        builder: (c, s) => AddMediaScreen(albumId: s.pathParameters['id'] ?? ''),
      ),
      // Admin routes
      GoRoute(path: '/admin/notifications/manage', builder: (c, s) => const AdminManageNotificationsScreen()),
      GoRoute(path: '/admin/notifications/send', builder: (c, s) => const AdminSendNotificationScreen()),
      GoRoute(path: '/admin/approve_members', builder: (c, s) => const AdminApproveMembersScreen()),
      GoRoute(path: '/admin/members/:id', builder: (c, s) => AdminMemberDetailScreen(uid: s.pathParameters['id'] ?? '')),
      // Super‑admin routes
      GoRoute(path: '/super_admin/audit_logs', builder: (c, s) => const AuditLogsScreen()),
      GoRoute(path: '/super_admin/membership_upload', builder: (c, s) => const MembershipBulkUploadScreen()),
        GoRoute(
          path: '/super_admin/membership_table',
          builder: (context, state) => const AdminMembershipTableScreen(),
        ),
        GoRoute(
          path: '/super_admin/event_registration_logs',
          builder: (context, state) => const EventRegistrationLogsScreen(),
        ),
        GoRoute(
          path: '/super_admin/event_registration_logs/:eventId',
          builder: (context, state) => EventRegistrationsDetailScreen(
            eventId: state.pathParameters['eventId'] ?? '',
            eventTitle: state.extra as String? ?? 'Event Registrations',
          ),
        ),
      // Volunteer routes
      GoRoute(path: '/volunteer/scan', builder: (c, s) => const ScanQRScreen()),
      GoRoute(path: '/volunteer/validate/:eventId/:registrationId', builder: (c, s) => QRValidationScreen(eventId: s.pathParameters['eventId'] ?? '', registrationId: s.pathParameters['registrationId'] ?? '')),

      // Profile
      GoRoute(path: '/profile/edit', builder: (c, s) => const EditProfileScreen()),
      GoRoute(path: '/profile/family', builder: (c, s) => const FamilyMembersScreen()),
      GoRoute(path: '/profile/family/add', builder: (c, s) => const AddFamilyMemberScreen()),
      // Membership
      GoRoute(path: '/membership/plans', builder: (c, s) => const MembershipPlansScreen()),
      GoRoute(path: '/membership/payments', builder: (c, s) => const PaymentHistoryScreen()),
      GoRoute(path: '/membership/subscriptions', builder: (c, s) => const SubscriptionHistoryScreen()),
      // Notifications
      GoRoute(path: '/notifications', builder: (c, s) => const NotificationsScreen()),
    ],
  );
});
