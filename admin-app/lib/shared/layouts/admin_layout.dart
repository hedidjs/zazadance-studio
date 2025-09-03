import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_logo.dart';

class AdminLayout extends ConsumerWidget {
  final Widget child;

  const AdminLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // תפריט צדדי
          _buildSideNavigationRail(context),
          
          // תוכן ראשי
          Expanded(
            child: Column(
              children: [
                // כותרת עליונה
                _buildTopBar(context),
                
                // תוכן הדף
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavigationRail(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          left: BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      child: Column(
        children: [
          // לוגו וכותרת
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    const AppLogo(
                      size: 52,
                      isIcon: true,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'פאנל ניהול',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'סטודיו שרון לריקוד',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(color: Color(0xFF333333)),
          
          // תפריט ניהול
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 8),
                
                // Dashboard
                _buildNavItem(
                  context: context,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  title: 'לוח בקרה',
                  path: '/dashboard',
                  isActive: currentLocation == '/dashboard',
                ),
                
                const SizedBox(height: 16),
                
                // כותרת ניהול תוכן
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'ניהול תוכן',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // ניהול מדריכים
                _buildNavItem(
                  context: context,
                  icon: Icons.video_library_outlined,
                  activeIcon: Icons.video_library,
                  title: 'ניהול מדריכים',
                  path: '/tutorials',
                  isActive: currentLocation == '/tutorials',
                ),
                
                // ניהול גלריה
                _buildNavItem(
                  context: context,
                  icon: Icons.photo_library_outlined,
                  activeIcon: Icons.photo_library,
                  title: 'ניהול גלריה',
                  path: '/gallery',
                  isActive: currentLocation == '/gallery',
                ),
                
                // ניהול עדכונים
                _buildNavItem(
                  context: context,
                  icon: Icons.article_outlined,
                  activeIcon: Icons.article,
                  title: 'ניהול עדכונים',
                  path: '/updates',
                  isActive: currentLocation == '/updates',
                ),
                
                // ניהול קבוצות
                _buildNavItem(
                  context: context,
                  icon: Icons.group_outlined,
                  activeIcon: Icons.group,
                  title: 'ניהול קבוצות',
                  path: '/groups',
                  isActive: currentLocation == '/groups',
                ),
                
                // ניהול חנות
                _buildNavItem(
                  context: context,
                  icon: Icons.store_outlined,
                  activeIcon: Icons.store,
                  title: 'ניהול חנות',
                  path: '/store',
                  isActive: currentLocation == '/store',
                ),
                
                const SizedBox(height: 16),
                
                // כותרת ניהול מערכת
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'ניהול מערכת',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // ניהול כללי
                _buildNavItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  title: 'ניהול כללי',
                  path: '/general',
                  isActive: currentLocation == '/general',
                ),
                
                // עיצוב האפליקציה
                _buildNavItem(
                  context: context,
                  icon: Icons.palette_outlined,
                  activeIcon: Icons.palette,
                  title: 'עיצוב האפליקציה',
                  path: '/theme',
                  isActive: currentLocation == '/theme',
                ),
                
                // ניהול משתמשים
                _buildNavItem(
                  context: context,
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  title: 'ניהול משתמשים',
                  path: '/users',
                  isActive: currentLocation == '/users',
                ),
                
                // ניהול אודות הסטודיו
                _buildNavItem(
                  context: context,
                  icon: Icons.info_outline,
                  activeIcon: Icons.info,
                  title: 'אודות הסטודיו',
                  path: '/about',
                  isActive: currentLocation == '/about',
                ),
                
                // ניהול תקנון ופרטיות
                _buildNavItem(
                  context: context,
                  icon: Icons.description_outlined,
                  activeIcon: Icons.description,
                  title: 'תקנון ופרטיות',
                  path: '/terms',
                  isActive: currentLocation == '/terms',
                ),
                
                // ניהול יצירת קשר
                _buildNavItem(
                  context: context,
                  icon: Icons.contact_support_outlined,
                  activeIcon: Icons.contact_support,
                  title: 'ניהול יצירת קשר',
                  path: '/contact',
                  isActive: currentLocation == '/contact',
                ),
              ],
            ),
          ),
          
          // כפתור יציאה
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildNavItem(
              context: context,
              icon: Icons.logout,
              activeIcon: Icons.logout,
              title: 'יציאה',
              path: '/login',
              isActive: false,
              isDestructive: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required String path,
    required bool isActive,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(path),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE91E63).withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive 
                    ? const Color(0xFFE91E63).withOpacity(0.3) 
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isDestructive 
                      ? Colors.red
                      : (isActive ? const Color(0xFFE91E63) : Colors.white70),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDestructive 
                          ? Colors.red
                          : (isActive ? const Color(0xFFE91E63) : Colors.white70),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE91E63),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF333333), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // כותרת הדף הנוכחי
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getPageTitle(GoRouterState.of(context).matchedLocation),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _getPageSubtitle(GoRouterState.of(context).matchedLocation),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            // כפתורי פעולה
            Row(
              children: [
                // הודעות
                IconButton(
                  icon: Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white70,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE91E63),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    // TODO: הצגת הודעות
                  },
                ),
                
                const SizedBox(width: 8),
                
                // פרופיל אדמין
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFFE91E63),
                        child: Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'מנהל מערכת',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPageTitle(String location) {
    switch (location) {
      case '/dashboard':
        return 'לוח בקרה';
      case '/tutorials':
        return 'ניהול מדריכים';
      case '/gallery':
        return 'ניהול גלריה';
      case '/updates':
        return 'ניהול עדכונים';
      case '/store':
        return 'ניהול חנות';
      case '/orders':
        return 'ניהול הזמנות';
      case '/general':
        return 'ניהול כללי';
      case '/theme':
        return 'עיצוב האפליקציה';
      case '/users':
        return 'ניהול משתמשים';
      case '/about':
        return 'ניהול אודות הסטודיו';
      case '/terms':
        return 'ניהול תקנון ופרטיות';
      case '/contact':
        return 'ניהול יצירת קשר';
      default:
        return 'פאנל ניהול';
    }
  }

  String _getPageSubtitle(String location) {
    switch (location) {
      case '/dashboard':
        return 'סקירה כללית של המערכת';
      case '/tutorials':
        return 'הוספה ועריכה של מדריכי וידאו';
      case '/gallery':
        return 'ניהול תמונות ואלבומים';
      case '/updates':
        return 'פרסום עדכונים והודעות';
      case '/store':
        return 'ניהול קטגוריות ומוצרים';
      case '/orders':
        return 'ניהול הזמנות לקוחות';
      case '/general':
        return 'הגדרות כלליות של האפליקציה';
      case '/users':
        return 'ניהול תלמידים והורים';
      case '/about':
        return 'עריכת תוכן אודות הסטודיו';
      case '/terms':
        return 'עריכת תנאי שימוש ופרטיות';
      case '/contact':
        return 'עריכת פרטי יצירת קשר';
      default:
        return 'ZaZa Dance';
    }
  }
}