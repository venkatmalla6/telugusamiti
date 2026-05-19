import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/router.dart';
import 'config/supabase_config.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (Assuming default options are generated later or provided natively)
  await Firebase.initializeApp();
  
  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: TeluguSamitiApp(),
    ),
  );
}

class TeluguSamitiApp extends ConsumerWidget {
  const TeluguSamitiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Telugu Samiti Tamil Nadu',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Switch automatically based on system preferences
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
