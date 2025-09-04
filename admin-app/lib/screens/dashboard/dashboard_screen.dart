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
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // קביעת מספר עמודות לפי גודל המסך
        int crossAxisCount;
        double childAspectRatio;
        
        if (screenWidth < 400) {
          // Mobile - עמודה אחת
          crossAxisCount = 1;
          childAspectRatio = 4.0;
        } else if (screenWidth < 600) {
          // Mobile - שתי עמודות
          crossAxisCount = 2;
          childAspectRatio = 1.5;
        } else if (screenWidth < 900) {
          // Tablet - שתי עמודות
          crossAxisCount = 2;
          childAspectRatio = 1.3;
        } else {
          // Desktop - ארבע עמודות
          crossAxisCount = 4;
          childAspectRatio = 1.3;
        }
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: screenWidth < 600 ? 8 : 16,
          mainAxisSpacing: screenWidth < 600 ? 8 : 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              'משתמשים',
              '${_stats['users'] ?? 0}',
              Icons.people,
              const Color(0xFF4CAF50),
              screenWidth < 600,
            ),
            _buildStatCard(
              'מדריכים',
              '${_stats['tutorials'] ?? 0}',
              Icons.video_library,
              const Color(0xFFE91E63),
              screenWidth < 600,
            ),
            _buildStatCard(
              'תמונות',
              '${_stats['gallery'] ?? 0}',
              Icons.photo_library,
              const Color(0xFF00BCD4),
              screenWidth < 600,
            ),
            _buildStatCard(
              'עדכונים',
              '${_stats['updates'] ?? 0}',
              Icons.article,
              const Color(0xFF9C27B0),
              screenWidth < 600,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isMobile) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 8 : 12),
        child: isMobile && MediaQuery.of(context).size.width < 400
            ? Row(
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    flex: 2,
                    child: Icon(
                      icon,
                      size: isMobile ? 24 : 28,
                      color: color,
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 6),
                  Flexible(
                    flex: 2,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
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
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 12,
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Card(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '👋 ברוכים הבאים לפאנל הניהול',
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'מכאן תוכלו לנהל את כל התוכן באפליקציית הסטודיו:',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Wrap(
              spacing: isMobile ? 8 : 16,
              runSpacing: isMobile ? 6 : 8,
              children: [
                _buildFeatureChip('📹 ניהול מדריכי וידאו', isMobile),
                _buildFeatureChip('📸 ניהול גלריית תמונות', isMobile),
                _buildFeatureChip('📝 פרסום עדכונים', isMobile),
                _buildFeatureChip('👥 ניהול משתמשים', isMobile),
                _buildFeatureChip('📊 צפייה בסטטיסטיקות', isMobile),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              '💡 טיפ: כל שינוי שתבצעו כאן יתעדכן מיידית באפליקציה',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: Colors.amber,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String text, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 12,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(
          color: const Color(0xFFE91E63).withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isMobile ? 10 : 12,
          color: Colors.white,
        ),
      ),
    );
  }
}