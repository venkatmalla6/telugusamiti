import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://lgbvevszrmgzpzylybyr.supabase.co';
  static const String anonKey = 'sb_publishable_d_FVVPmj9Rxev-1wSRf_YQ_71ZVq4BH'; // Using the key provided by user

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
    } catch (e) {
      // In case the key is invalid, we don't want to crash the whole app on startup
      print('Failed to initialize Supabase: $e');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
