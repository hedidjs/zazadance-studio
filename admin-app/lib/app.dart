import 'package:go_router/go_router.dart';
import 'screens/login/simple_login.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/tutorials/tutorials_management_screen.dart';
import 'screens/gallery/gallery_management_screen.dart';
import 'screens/updates/updates_management_screen.dart';
import 'screens/store/store_management_screen.dart';
import 'screens/users/users_management_screen.dart';
import 'screens/about/about_management_screen.dart';
import 'screens/terms/terms_management_screen.dart';
import 'screens/contact/contact_management_screen.dart';
import 'screens/general/general_management_screen.dart';
import 'screens/theme/theme_management_screen.dart';
import 'screens/groups/groups_management_screen.dart';
import 'shared/layouts/admin_layout.dart';

class AdminRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Login route
      GoRoute(
        path: '/login',
        builder: (context, state) => const SimpleLoginScreen(),
      ),
      
      // Redirect /admin to /updates
      GoRoute(
        path: '/admin',
        redirect: (context, state) => '/updates',
      ),
      
      // Admin routes with layout
      ShellRoute(
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          
          // ניהול מדריכים
          GoRoute(
            path: '/tutorials',
            builder: (context, state) => const TutorialsManagementScreen(),
          ),
          
          // ניהול גלריה
          GoRoute(
            path: '/gallery',
            builder: (context, state) => const GalleryManagementScreen(),
          ),
          
          // ניהול עדכונים
          GoRoute(
            path: '/updates',
            builder: (context, state) => const UpdatesManagementScreen(),
          ),
          
          // ניהול קבוצות
          GoRoute(
            path: '/groups',
            builder: (context, state) => const GroupsManagementScreen(),
          ),
          
          // ניהול חנות
          GoRoute(
            path: '/store',
            builder: (context, state) => const StoreManagementScreen(),
          ),
          
          
          // ניהול משתמשים
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersManagementScreen(),
          ),
          
          // ניהול תוכן אודות הסטודיו
          GoRoute(
            path: '/about',
            builder: (context, state) => const AboutManagementScreen(),
          ),
          
          // ניהול תקנון ופרטיות
          GoRoute(
            path: '/terms',
            builder: (context, state) => const TermsManagementScreen(),
          ),
          
          // ניהול יצירת קשר
          GoRoute(
            path: '/contact',
            builder: (context, state) => const ContactManagementScreen(),
          ),
          
          // ניהול כללי
          GoRoute(
            path: '/general',
            builder: (context, state) => const GeneralManagementScreen(),
          ),
          
          // עיצוב האפליקציה
          GoRoute(
            path: '/theme',
            builder: (context, state) => const ThemeManagementScreen(),
          ),
        ],
      ),
    ],
  );
}