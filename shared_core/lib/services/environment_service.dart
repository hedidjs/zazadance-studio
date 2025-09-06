import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for managing environment variables and configuration
class EnvironmentService {
  static const String _supabaseUrl = 'SUPABASE_URL';
  static const String _supabaseAnonKey = 'SUPABASE_ANON_KEY';
  static const String _adminEmail = 'ADMIN_EMAIL';
  static const String _adminPassword = 'ADMIN_PASSWORD';

  /// Load environment variables from .env file
  static Future<void> load({String fileName = '.env'}) async {
    await dotenv.load(fileName: fileName);
  }

  /// Get Supabase URL
  static String get supabaseUrl => dotenv.env[_supabaseUrl] ?? '';

  /// Get Supabase anonymous key
  static String get supabaseAnonKey => dotenv.env[_supabaseAnonKey] ?? '';

  /// Get admin email (for admin app)
  static String get adminEmail => dotenv.env[_adminEmail] ?? '';

  /// Get admin password (for admin app)
  static String get adminPassword => dotenv.env[_adminPassword] ?? '';

  /// Check if running in development mode
  static bool get isDevelopment => dotenv.env['ENVIRONMENT'] == 'development';

  /// Check if running in production mode
  static bool get isProduction => dotenv.env['ENVIRONMENT'] == 'production';

  /// Get environment name
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  /// Validate that all required environment variables are set
  static bool validateEnvironment({bool requireAdminCredentials = false}) {
    final requiredVars = [_supabaseUrl, _supabaseAnonKey];
    
    if (requireAdminCredentials) {
      requiredVars.addAll([_adminEmail, _adminPassword]);
    }

    for (final varName in requiredVars) {
      final value = dotenv.env[varName];
      if (value == null || value.isEmpty) {
        print('Missing required environment variable: $varName');
        return false;
      }
    }

    return true;
  }

  /// Get all environment variables (for debugging - don't use in production)
  static Map<String, String> getAllVariables() {
    if (isProduction) {
      throw Exception('getAllVariables() should not be used in production');
    }
    return dotenv.env;
  }
}