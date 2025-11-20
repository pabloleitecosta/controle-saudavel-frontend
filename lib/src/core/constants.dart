import 'package:flutter/foundation.dart';

class AppConstants {
  static String get apiBaseUrl {
    const env = String.fromEnvironment('API_BASE_URL');
    if (env.isNotEmpty) {
      return env;
    }

    if (kIsWeb) {
      return 'https://controle-saudavel-backend.onrender.com';
    }

    return 'http://10.0.2.2:5001';
  }
}
