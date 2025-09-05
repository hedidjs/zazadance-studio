import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/home/home_screen.dart';
import 'features/tutorials/tutorials_screen.dart';
import 'features/gallery/gallery_screen.dart';
import 'features/updates/updates_screen.dart';
import 'features/store/store_screen.dart';
import 'features/cart/cart_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/profile/profile_simple_screen.dart';
import 'features/contact/contact_screen.dart';
import 'features/about/about_screen.dart';
import 'features/favorites/favorites_full_screen.dart';
import 'features/terms/terms_screen.dart';
import 'features/orders/my_orders_screen.dart';
import 'features/groups/groups_screen.dart';
import 'features/public/public_terms_screen.dart';
import 'features/public/public_contact_screen_db.dart';
import 'shared/widgets/main_scaffold.dart';
import 'providers/auth_notifier.dart';

class AppRouter {
  static final _supabase = Supabase.instance.client;
  
  static GoRouter router(WidgetRef ref) => GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;
      
      // Allow public routes without any authentication check
      if (path == '/privacy' || path == '/support') {
        return null; // Don't redirect, allow access
      }
      
      final isLoggedIn = _supabase.auth.currentUser != null;
      final isLoggingIn = path == '/login';
      final isRegistering = path == '/register';
      
      // אם המשתמש לא מחובר ולא בדף התחברות/הרשמה - הפנה להתחברות
      if (!isLoggedIn && !isLoggingIn && !isRegistering) {
        return '/login';
      }
      
      // אם המשתמש מחובר ובדף התחברות/הרשמה - הפנה לעמוד הבית
      if (isLoggedIn && (isLoggingIn || isRegistering)) {
        return '/';
      }
      
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      
      // Main app shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          // בית
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          
          // עדכונים  
          GoRoute(
            path: '/updates',
            builder: (context, state) => const UpdatesScreen(),
          ),
          
          // גלריה
          GoRoute(
            path: '/gallery',
            builder: (context, state) => const GalleryScreen(),
          ),
          
          // מדריכים
          GoRoute(
            path: '/tutorials',
            builder: (context, state) => const TutorialsScreen(),
          ),
          
          // קבוצות
          GoRoute(
            path: '/groups',
            builder: (context, state) => const GroupsScreen(),
          ),
          
          // חנות
          GoRoute(
            path: '/store', 
            builder: (context, state) => const StoreScreen(),
          ),
          
          // סל קניות
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),
          
          // ההזמנות שלי
          GoRoute(
            path: '/my-orders',
            builder: (context, state) => const MyOrdersScreen(),
          ),
          
          // דפי Drawer
          
          // איזור אישי (פרופיל מפושט לפי PRD)
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileSimpleScreen(),
          ),
          
          // יצירת קשר
          GoRoute(
            path: '/contact',
            builder: (context, state) => const ContactScreen(),
          ),
          
          // אודות הסטודיו
          GoRoute(
            path: '/about',
            builder: (context, state) => const AboutScreen(),
          ),
          
          // מועדפים
          GoRoute(
            path: '/favorites',
            builder: (context, state) => const FavoritesFullScreen(),
          ),
          
          // תקנון ופרטיות
          GoRoute(
            path: '/terms',
            builder: (context, state) {
              final tabParam = state.uri.queryParameters['tab'];
              final initialTab = tabParam != null ? int.tryParse(tabParam) : null;
              return TermsScreen(initialTab: initialTab);
            },
          ),
          
          
        ],
      ),
      
      // נתיבים ציבוריים (נגישים גם ללא התחברות)
      GoRoute(
        path: '/privacy',
        builder: (context, state) {
          // Show privacy tab (index 1) in the terms screen
          return const PublicTermsScreen(initialTab: 1);
        },
      ),
      
      GoRoute(
        path: '/support',
        builder: (context, state) => const PublicContactScreenDb(),
      ),
    ],
  );
}