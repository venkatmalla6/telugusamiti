import 'package:flutter_riverpod/flutter_riverpod.dart';

// Root level providers can be defined here
final initialSetupProvider = FutureProvider<void>((ref) async {
  // Any initial async setup like getting user preferences or auth state
});
