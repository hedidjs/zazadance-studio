import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'providers/app_config_provider.dart';
import 'providers/theme_provider.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure image cache limits
  PaintingBinding.instance.imageCache.maximumSize = 1000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MB
  
  // Set URL strategy to use path instead of hash
  usePathUrlStrategy();
  
  // אתחול Supabase with production config
  await Supabase.initialize(
    url: 'https://yyvoavzgapsyycjwirmg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl5dm9hdnpnYXBzeXljandpcm1nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUyOTgyMzgsImV4cCI6MjA3MDg3NDIzOH0.IU_dW_8K-yuV1grWIWJdetU7jK-b-QDPFYp_m5iFP90',
  );
  
  
  runApp(
    const ProviderScope(
      child: DanceStudioApp(),
    ),
  );
}

class DanceStudioApp extends ConsumerWidget {
  const DanceStudioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(appConfigProvider);
    final themeData = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: appConfig?.appName ?? 'ZaZa Dance',
      debugShowCheckedModeBanner: false,
      
      // תמיכה בעברית ו-RTL
      locale: const Locale('he', 'IL'),
      supportedLocales: const [
        Locale('he', 'IL'), // עברית
        Locale('en', 'US'), // אנגלית כגיבוי
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      // כיוון RTL
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      
      // Theme דינמי מותאם
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: themeData.backgroundColor,
        primarySwatch: Colors.pink,
        primaryColor: themeData.primaryColor,
        colorScheme: ColorScheme.dark(
          primary: themeData.primaryColor,
          secondary: themeData.secondaryColor,
          surface: themeData.surfaceColor,
          onPrimary: themeData.buttonPrimaryText,
          onSecondary: themeData.buttonSecondaryText,
          onSurface: themeData.primaryTextColor,
          outline: themeData.inputBorder,
        ),
        textTheme: GoogleFonts.heeboTextTheme(
          ThemeData.dark().textTheme.apply(
            bodyColor: themeData.primaryTextColor,
            displayColor: themeData.primaryTextColor,
          ),
        ),
        cardTheme: CardThemeData(
          color: themeData.cardColor,
          elevation: 4,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: themeData.surfaceColor,
          foregroundColor: themeData.primaryTextColor,
          elevation: 2,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: themeData.buttonPrimaryBg,
            foregroundColor: themeData.buttonPrimaryText,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: themeData.inputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: themeData.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: themeData.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: themeData.inputFocusBorder),
          ),
          labelStyle: TextStyle(color: themeData.inputLabel),
        ),
      ),
      
      routerConfig: AppRouter.router(ref),
    );
  }
}