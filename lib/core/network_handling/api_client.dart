import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  // Base setup for Dio or Http clients can go here
  // For now, this serves as the foundational structure
  ApiClient();

  Future<dynamic> get(String url) async {
    // Implementation for GET request
  }

  Future<dynamic> post(String url, dynamic data) async {
    // Implementation for POST request
  }
}
