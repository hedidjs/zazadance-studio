import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_notifier.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    
    // מאזין לשינויים ב-auth state
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        if (data.session?.user != null) {
          _loadUserProfile();
        } else {
          setState(() {
            _userProfile = null;
            _isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('users')
            .select('full_name, profile_image_url, email')
            .eq('id', user.id)
            .maybeSingle();
        
        if (mounted) {
          setState(() {
            _userProfile = response ?? {
              'full_name': user.email?.split('@')[0] ?? 'משתמש',
              'profile_image_url': null,
              'email': user.email ?? '',
            };
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _userProfile = {
              'full_name': user.email?.split('@')[0] ?? 'משתמש',
              'profile_image_url': null,
              'email': user.email ?? '',
            };
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);
    final themeData = ref.watch(themeProvider);
    
    return Scaffold(
      // AppBar עליון עם לוגו ותפריט המבורגר
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          centerTitle: true,
          title: Container(
            height: 50,
            constraints: const BoxConstraints(
              maxWidth: 180,
              maxHeight: 50,
            ),
            child: appConfig?.logoUrl != null 
                ? Image.network(
                    appConfig!.logoUrl!,
                    height: 50,
                    width: 180,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/zaza_logo.png',
                        height: 60,
                        width: 200,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      );
                    },
                  )
                : Image.asset(
                    'assets/images/zaza_logo.png',
                    height: 50,
                    width: 180,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
            ),
          ),
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.3),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.white,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          // רק לוגו, בלי actions לפי PRD
        ),
      ),
      
      // תפריט נפתח (Drawer)
      drawer: _buildDrawer(context),
      
      // תוכן הדף
      body: widget.child,
      
      // תפריט תחתון
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final themeData = ref.watch(themeProvider);
    
    return Drawer(
      backgroundColor: themeData.drawerBg,
      child: Column(
        children: [
          // כותרת הDrawer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeData.drawerHeaderGradientStart,
                  themeData.drawerHeaderGradientEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // תמונת פרופיל
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: _userProfile?['profile_image_url'] != null
                      ? ClipOval(
                          child: Image.network(
                            _userProfile!['profile_image_url'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white,
                        ),
                ),
                const SizedBox(height: 12),
                // שם המשתמש
                Text(
                  'שלום, ${_userProfile?['full_name'] ?? 'משתמש'}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // אימייל המשתמש
                Text(
                  _userProfile?['email'] ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // פריטי תפריט
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // איזור אישי
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline,
                  title: 'איזור אישי',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/profile');
                  },
                ),
                
                // עדכונים
                _buildDrawerItem(
                  context,
                  icon: Icons.campaign_outlined,
                  title: 'עדכונים',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/updates');
                  },
                ),
                
                // מועדפים (תמונות, מדריכים, מוצרים)
                _buildDrawerItem(
                  context,
                  icon: Icons.star_outline,
                  title: 'מועדפים',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/favorites');
                  },
                ),
                
                // אודות הסטודיו
                _buildDrawerItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'אודות',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/about');
                  },
                ),
                
                const Divider(color: Colors.grey),
                
                // יצירת קשר
                _buildDrawerItem(
                  context,
                  icon: Icons.phone_outlined,
                  title: 'יצירת קשר',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/contact');
                  },
                ),
                
                // תקנון ופרטיות
                _buildDrawerItem(
                  context,
                  icon: Icons.description_outlined,
                  title: 'תקנון ופרטיות',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/terms');
                  },
                ),
              ],
            ),
          ),
          
          // התנתקות
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: 'התנתקות',
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
              isDestructive: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final themeData = ref.watch(themeProvider);
    
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : themeData.accentTextColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : themeData.primaryTextColor,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      hoverColor: themeData.primaryTextColor.withOpacity(0.1),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final themeData = ref.watch(themeProvider);
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _getCurrentIndex(currentLocation),
        onTap: (index) => _onBottomNavTap(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: themeData.bottomNavBg,
        selectedItemColor: themeData.bottomNavSelected,
        unselectedItemColor: themeData.bottomNavUnselected,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'בית',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'קבוצות',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            activeIcon: Icon(Icons.photo_library),
            label: 'גלריה',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            activeIcon: Icon(Icons.play_circle_fill),
            label: 'מדריכים',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'חנות',
          ),
        ],
      ),
    );
  }

  int _getCurrentIndex(String location) {
    switch (location) {
      case '/':
        return 0;
      case '/groups':
        return 1;
      case '/gallery':
        return 2;
      case '/tutorials':
        return 3;
      case '/store':
        return 4;
      default:
        return 0;
    }
  }

  void _onBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/groups');
        break;
      case 2:
        context.go('/gallery');
        break;
      case 3:
        context.go('/tutorials');
        break;
      case 4:
        context.go('/store');
        break;
    }
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return 'בוקר טוב!';
    } else if (hour >= 12 && hour < 16) {
      return 'צהריים טובים!';
    } else if (hour >= 16 && hour < 20) {
      return 'ערב טוב!';
    } else {
      return 'לילה טוב!';
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'התנתקות',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'האם אתה בטוח שברצונך להתנתק?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ביטול',
              style: TextStyle(color: Color(0xFF00BCD4)),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // התנתקות מGoogle Sign-In ומSupabase
                // התנתקות מהמערכת
                
                // ניווט לעמוד ההתחברות וניקוי כל ההיסטוריה
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('שגיאה בהתנתקות: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'התנתק',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}