import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _aboutContent = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAboutContent();
  }

  Future<void> _loadAboutContent() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _supabase
          .from('about_content')
          .select('*')
          .eq('is_active', true)
          .order('sort_order');

      if (mounted) {
        setState(() {
          _aboutContent = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בטעינת התוכן: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'אודות הסטודיו',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE91E63),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFFE91E63),
              onRefresh: _loadAboutContent,
              child: _aboutContent.isEmpty
                  ? _buildEmptyState()
                  : _buildContentList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'אין תוכן זמין',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'התוכן יתווסף בקרוב',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _aboutContent.length,
      itemBuilder: (context, index) {
        final content = _aboutContent[index];
        return _buildContentCard(content, index == 0);
      },
    );
  }

  Widget _buildContentCard(Map<String, dynamic> content, bool isFirst) {
    return Container(
      margin: EdgeInsets.only(
        bottom: 24,
        top: isFirst ? 0 : 0,
      ),
      child: Card(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // תמונה אם קיימת
              if (content['image_url'] != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    content['image_url'],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // כותרת
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFE91E63),
                          Color(0xFF00BCD4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      content['title_he'] ?? 'ללא כותרת',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // תוכן
              Text(
                content['content_he'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.6,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.justify,
              ),

              // תאריך עדכון אחרון
              if (content['updated_at'] != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00BCD4).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.update,
                        size: 14,
                        color: Color(0xFF00BCD4),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'עודכן לאחרונה: ${_formatDate(content['updated_at'])}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00BCD4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return 'לפני ${difference.inDays} ימים';
      } else if (difference.inHours > 0) {
        return 'לפני ${difference.inHours} שעות';
      } else {
        return 'לפני כמה דקות';
      }
    } catch (e) {
      return 'תאריך לא ידוע';
    }
  }
}