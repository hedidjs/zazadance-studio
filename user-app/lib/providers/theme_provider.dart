import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppThemeData {
  // Background Settings
  final String backgroundType;
  final Color backgroundColor;
  final Color gradientStartColor;
  final Color gradientEndColor;
  final String gradientDirection;
  final String? backgroundImageUrl;
  final double backgroundImageOpacity;
  final String backgroundImageFit;
  final Color? overlayColor;
  final double overlayOpacity;

  // Text Colors
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentTextColor;

  // UI Colors
  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final Color cardColor;

  // Button Colors
  final Color buttonPrimaryBg;
  final Color buttonPrimaryText;
  final Color buttonSecondaryBg;
  final Color buttonSecondaryText;

  // Navigation Colors
  final Color bottomNavBg;
  final Color bottomNavSelected;
  final Color bottomNavUnselected;
  final Color drawerBg;
  final Color drawerHeaderGradientStart;
  final Color drawerHeaderGradientEnd;

  // Input Colors
  final Color inputBg;
  final Color inputBorder;
  final Color inputFocusBorder;
  final Color inputText;
  final Color inputLabel;

  const AppThemeData({
    this.backgroundType = 'solid',
    this.backgroundColor = const Color(0xFF121212),
    this.gradientStartColor = const Color(0xFFE91E63),
    this.gradientEndColor = const Color(0xFF00BCD4),
    this.gradientDirection = 'topLeft-bottomRight',
    this.backgroundImageUrl,
    this.backgroundImageOpacity = 1.0,
    this.backgroundImageFit = 'cover',
    this.overlayColor,
    this.overlayOpacity = 0.5,
    this.primaryTextColor = Colors.white,
    this.secondaryTextColor = Colors.white70,
    this.accentTextColor = const Color(0xFF00BCD4),
    this.primaryColor = const Color(0xFFE91E63),
    this.secondaryColor = const Color(0xFF00BCD4),
    this.surfaceColor = const Color(0xFF1E1E1E),
    this.cardColor = const Color(0xFF1E1E1E),
    this.buttonPrimaryBg = const Color(0xFFE91E63),
    this.buttonPrimaryText = Colors.white,
    this.buttonSecondaryBg = const Color(0xFF00BCD4),
    this.buttonSecondaryText = Colors.white,
    this.bottomNavBg = const Color(0xFF1E1E1E),
    this.bottomNavSelected = const Color(0xFFE91E63),
    this.bottomNavUnselected = Colors.grey,
    this.drawerBg = const Color(0xFF1E1E1E),
    this.drawerHeaderGradientStart = const Color(0xFFE91E63),
    this.drawerHeaderGradientEnd = const Color(0xFF00BCD4),
    this.inputBg = const Color(0xFF2A2A2A),
    this.inputBorder = const Color(0xFF333333),
    this.inputFocusBorder = const Color(0xFFE91E63),
    this.inputText = Colors.white,
    this.inputLabel = const Color(0xFF00BCD4),
  });

  factory AppThemeData.fromJson(Map<String, dynamic> json) {
    return AppThemeData(
      backgroundType: json['background_type'] ?? 'solid',
      backgroundColor: _colorFromHex(json['background_color']) ?? const Color(0xFF121212),
      gradientStartColor: _colorFromHex(json['gradient_start_color']) ?? const Color(0xFFE91E63),
      gradientEndColor: _colorFromHex(json['gradient_end_color']) ?? const Color(0xFF00BCD4),
      gradientDirection: json['gradient_direction'] ?? 'topLeft-bottomRight',
      backgroundImageUrl: json['background_image_url'],
      backgroundImageOpacity: (json['background_image_opacity'] as num?)?.toDouble() ?? 1.0,
      backgroundImageFit: json['background_image_fit'] ?? 'cover',
      overlayColor: _colorFromHex(json['overlay_color']),
      overlayOpacity: (json['overlay_opacity'] as num?)?.toDouble() ?? 0.5,
      primaryTextColor: _colorFromHex(json['primary_text_color']) ?? Colors.white,
      secondaryTextColor: _colorFromHex(json['secondary_text_color']) ?? Colors.white70,
      accentTextColor: _colorFromHex(json['accent_text_color']) ?? const Color(0xFF00BCD4),
      primaryColor: _colorFromHex(json['primary_color']) ?? const Color(0xFFE91E63),
      secondaryColor: _colorFromHex(json['secondary_color']) ?? const Color(0xFF00BCD4),
      surfaceColor: _colorFromHex(json['surface_color']) ?? const Color(0xFF1E1E1E),
      cardColor: _colorFromHex(json['card_color']) ?? const Color(0xFF1E1E1E),
      buttonPrimaryBg: _colorFromHex(json['button_primary_bg']) ?? const Color(0xFFE91E63),
      buttonPrimaryText: _colorFromHex(json['button_primary_text']) ?? Colors.white,
      buttonSecondaryBg: _colorFromHex(json['button_secondary_bg']) ?? const Color(0xFF00BCD4),
      buttonSecondaryText: _colorFromHex(json['button_secondary_text']) ?? Colors.white,
      bottomNavBg: _colorFromHex(json['bottom_nav_bg']) ?? const Color(0xFF1E1E1E),
      bottomNavSelected: _colorFromHex(json['bottom_nav_selected']) ?? const Color(0xFFE91E63),
      bottomNavUnselected: _colorFromHex(json['bottom_nav_unselected']) ?? Colors.grey,
      drawerBg: _colorFromHex(json['drawer_bg']) ?? const Color(0xFF1E1E1E),
      drawerHeaderGradientStart: _colorFromHex(json['drawer_header_gradient_start']) ?? const Color(0xFFE91E63),
      drawerHeaderGradientEnd: _colorFromHex(json['drawer_header_gradient_end']) ?? const Color(0xFF00BCD4),
      inputBg: _colorFromHex(json['input_bg']) ?? const Color(0xFF2A2A2A),
      inputBorder: _colorFromHex(json['input_border']) ?? const Color(0xFF333333),
      inputFocusBorder: _colorFromHex(json['input_focus_border']) ?? const Color(0xFFE91E63),
      inputText: _colorFromHex(json['input_text']) ?? Colors.white,
      inputLabel: _colorFromHex(json['input_label']) ?? const Color(0xFF00BCD4),
    );
  }

  static Color? _colorFromHex(String? hexString) {
    if (hexString == null) return null;
    try {
      if (hexString.length == 9) {
        // Handle colors with alpha
        return Color(int.parse(hexString.substring(1), radix: 16));
      } else {
        return Color(int.parse(hexString.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (e) {
      return null;
    }
  }

  Alignment getGradientAlignment(String position) {
    switch (position) {
      case 'topLeft':
        return Alignment.topLeft;
      case 'topRight':
        return Alignment.topRight;
      case 'bottomLeft':
        return Alignment.bottomLeft;
      case 'bottomRight':
        return Alignment.bottomRight;
      case 'topCenter':
        return Alignment.topCenter;
      case 'bottomCenter':
        return Alignment.bottomCenter;
      case 'centerLeft':
        return Alignment.centerLeft;
      case 'centerRight':
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }

  LinearGradient getGradient() {
    switch (gradientDirection) {
      case 'topLeft-bottomRight':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStartColor, gradientEndColor],
        );
      case 'topRight-bottomLeft':
        return LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [gradientStartColor, gradientEndColor],
        );
      case 'top-bottom':
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gradientStartColor, gradientEndColor],
        );
      case 'left-right':
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [gradientStartColor, gradientEndColor],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStartColor, gradientEndColor],
        );
    }
  }

  RadialGradient getRadialGradient() {
    return RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [gradientStartColor, gradientEndColor],
    );
  }

  BoxFit getImageBoxFit() {
    switch (backgroundImageFit) {
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'cover':
      default:
        return BoxFit.cover;
    }
  }

  Decoration getBackgroundDecoration() {
    switch (backgroundType) {
      case 'solid':
        return BoxDecoration(color: backgroundColor);
        
      case 'gradient':
        if (gradientDirection == 'center-radial') {
          return BoxDecoration(gradient: getRadialGradient());
        } else {
          return BoxDecoration(gradient: getGradient());
        }
        
      case 'image':
        if (backgroundImageUrl != null) {
          return BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(backgroundImageUrl!),
              fit: getImageBoxFit(),
              opacity: backgroundImageOpacity,
            ),
          );
        }
        return BoxDecoration(color: backgroundColor);
        
      case 'image_with_overlay':
        if (backgroundImageUrl != null) {
          return BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(backgroundImageUrl!),
              fit: getImageBoxFit(),
              opacity: backgroundImageOpacity,
            ),
            color: overlayColor?.withOpacity(overlayOpacity),
          );
        }
        return BoxDecoration(color: backgroundColor);
        
      default:
        return BoxDecoration(color: backgroundColor);
    }
  }
}

class ThemeNotifier extends StateNotifier<AppThemeData> {
  final SupabaseClient _supabase = Supabase.instance.client;

  ThemeNotifier() : super(const AppThemeData()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final response = await _supabase
          .from('app_theme')
          .select('*')
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        state = AppThemeData.fromJson(response);
      } else {
        // Use default theme if no data found
        state = const AppThemeData();
      }
    } catch (e) {
      // Keep default theme on error
      state = const AppThemeData();
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> refreshTheme() async {
    await _loadTheme();
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeData>((ref) {
  return ThemeNotifier();
});