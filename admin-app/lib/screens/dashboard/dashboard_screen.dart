import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // טעינת סטטיסטיקות בסיסיות
      final results = await Future.wait([
        _supabase.from('user_profiles').select('*'),
        _supabase.from('tutorials').select('*'),
        _supabase.from('gallery_images').select('*'),
        _supabase.from('news_updates').select('*'),
      ]);

      if (mounted) {
        setState(() {
          _stats = {
            'users': (results[0] as List).length,
            'tutorials': (results[1] as List).length,
            'gallery': (results[2] as List).length,
            'updates': (results[3] as List).length,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // סטטיסטיקות עיקריות
          _buildStatsCards(),
          
          const SizedBox(height: 32),
          
          // הודעת ברוכים הבאים
          _buildWelcomeCard(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          'משתמשים',
          '${_stats['users'] ?? 0}',
          Icons.people,
          const Color(0xFF4CAF50),
        ),
        _buildStatCard(
          'מדריכים',
          '${_stats['tutorials'] ?? 0}',
          Icons.video_library,
          const Color(0xFFE91E63),
        ),
        _buildStatCard(
          'תמונות',
          '${_stats['gallery'] ?? 0}',
          Icons.photo_library,
          const Color(0xFF00BCD4),
        ),
        _buildStatCard(
          'עדכונים',
          '${_stats['updates'] ?? 0}',
          Icons.article,
          const Color(0xFF9C27B0),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              flex: 2,
              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              flex: 2,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              flex: 1,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👋 ברוכים הבאים לפאנל הניהול',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'מכאן תוכלו לנהל את כל התוכן באפליקציית הסטודיו:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildFeatureChip('📹 ניהול מדריכי וידאו'),
                _buildFeatureChip('📸 ניהול גלריית תמונות'),
                _buildFeatureChip('📝 פרסום עדכונים'),
                _buildFeatureChip('👥 ניהול משתמשים'),
                _buildFeatureChip('📊 צפייה בסטטיסטיקות'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '💡 טיפ: כל שינוי שתבצעו כאן יתעדכן מיידית באפליקציה',
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE91E63).withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}