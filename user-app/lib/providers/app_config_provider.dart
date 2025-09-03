import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  final String appName;
  final String appDescription;
  final String appSubtitle;
  final String? logoUrl;
  final String? iconUrl;
  final String primaryColor;
  final String secondaryColor;

  const AppConfig({
    required this.appName,
    required this.appDescription,
    required this.appSubtitle,
    this.logoUrl,
    this.iconUrl,
    required this.primaryColor,
    required this.secondaryColor,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      appName: json['app_name'] ?? 'ZaZa Dance',
      appDescription: json['app_description'] ?? 'סטודיו שרון לריקוד',
      appSubtitle: json['app_subtitle'] ?? 'סטודיו שרון לריקוד',
      logoUrl: json['app_logo_url'],
      iconUrl: json['app_icon_url'],
      primaryColor: json['primary_color'] ?? '#E91E63',
      secondaryColor: json['secondary_color'] ?? '#00BCD4',
    );
  }

  factory AppConfig.defaultConfig() {
    return const AppConfig(
      appName: 'ZaZa Dance',
      appDescription: 'סטודיו שרון לריקוד - האפליקציה הרשמית',
      appSubtitle: 'סטודיו שרון לריקוד',
      primaryColor: '#E91E63',
      secondaryColor: '#00BCD4',
    );
  }
}

class AppConfigNotifier extends StateNotifier<AppConfig?> {
  final SupabaseClient _supabase;

  AppConfigNotifier(this._supabase) : super(null) {
    loadConfig();
  }

  Future<void> loadConfig() async {
    try {
      final response = await _supabase
          .from('app_configuration')
          .select('*')
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        state = AppConfig.fromJson(response);
      } else {
        state = AppConfig.defaultConfig();
      }
    } catch (e) {
      // במקרה של שגיאה נשתמש בערכי ברירת מחדל
      state = AppConfig.defaultConfig();
      debugPrint('Error loading app config: $e');
    }
  }
}

final appConfigProvider = StateNotifierProvider<AppConfigNotifier, AppConfig?>((ref) {
  final supabase = Supabase.instance.client;
  return AppConfigNotifier(supabase);
});