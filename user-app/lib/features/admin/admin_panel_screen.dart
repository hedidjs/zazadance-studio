import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'פאנל ניהול',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
      ),
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildAdminCard(
              context,
              icon: Icons.people,
              title: 'ניהול משתמשים',
              subtitle: 'הוספה, עריכה ומחיקה',
              onTap: () => context.go('/admin/users'),
            ),
            _buildAdminCard(
              context,
              icon: Icons.campaign,
              title: 'ניהול עדכונים',
              subtitle: 'הודעות וחדשות',
              onTap: () => _showComingSoon(context),
            ),
            _buildAdminCard(
              context,
              icon: Icons.photo_library,
              title: 'ניהול גלריה',
              subtitle: 'תמונות ומדיה',
              onTap: () => _showComingSoon(context),
            ),
            _buildAdminCard(
              context,
              icon: Icons.play_circle,
              title: 'ניהול מדריכים',
              subtitle: 'סרטונים והדרכות',
              onTap: () => _showComingSoon(context),
            ),
            _buildAdminCard(
              context,
              icon: Icons.store,
              title: 'ניהול חנות',
              subtitle: 'מוצרים ומכירות',
              onTap: () => _showComingSoon(context),
            ),
            _buildAdminCard(
              context,
              icon: Icons.analytics,
              title: 'דוחות וסטטיסטיקות',
              subtitle: 'נתונים וניתוחים',
              onTap: () => _showComingSoon(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE91E63),
                      Color(0xFF00BCD4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('תכונה זו תהיה זמינה בקרוב'),
        backgroundColor: Color(0xFF00BCD4),
      ),
    );
  }
}