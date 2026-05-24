import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/router.dart';
import 'config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/services/fcm_service.dart';
import 'core/services/local_notification_service.dart';
import 'providers/notification_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize local notifications — wrapped so a MissingPluginException on
  // first install / hot-restart never prevents runApp() from being called.
  try {
    await LocalNotificationService().initialize();
  } catch (e) {
    debugPrint('[main] LocalNotificationService init failed (non-fatal): $e');
  }

  // Register FCM background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: TeluguSamitiApp(),
    ),
  );
}

class TeluguSamitiApp extends ConsumerStatefulWidget {
  const TeluguSamitiApp({super.key});

  @override
  ConsumerState<TeluguSamitiApp> createState() => _TeluguSamitiAppState();
}

class _TeluguSamitiAppState extends ConsumerState<TeluguSamitiApp> {
  @override
  void initState() {
    super.initState();
    // Check if the app was launched from a terminated notification tap state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmServiceProvider).checkInitialMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Keep FCM Service initialized and check subscription expiry on login
    ref.watch(fcmInitializationProvider);

    // Listen for notification taps to route the user
    ref.listen<AsyncValue<Map<String, dynamic>>>(notificationTapStreamProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        final data = next.value!;
        final type = data['type'] as String?;
        final eventId = data['eventId'] as String?;
        
        switch (type) {
          case 'eventReminder':
            if (eventId != null) {
              router.push('/events/$eventId');
            } else {
              router.push('/user_dashboard');
            }
            break;
          case 'membershipExpiry':
            router.push('/membership/plans');
            break;

          case 'adminBroadcast':
          default:
            router.push('/notifications');
            break;
        }
      }
    });

    return MaterialApp.router(
      title: 'Telugu Samiti Tamil Nadu',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Enforce light theme everywhere
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
