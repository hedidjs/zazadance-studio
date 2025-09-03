import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../favorites/favorites_service.dart';

class UpdatesScreen extends ConsumerStatefulWidget {
  const UpdatesScreen({super.key});

  @override
  ConsumerState<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends ConsumerState<UpdatesScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _updates = [];
  bool _isLoading = true;
  Set<String> _viewedUpdates = {};

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _supabase
          .from('updates')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      // טעינת סוגי עדכונים בנפרד
      final updateTypesResponse = await _supabase
          .from('update_types')
          .select('*')
          .eq('is_active', true);

      if (mounted) {
        // יצירת מפה של סוגי עדכונים לפי ID
        final updateTypesMap = <String, Map<String, dynamic>>{};
        for (final updateType in updateTypesResponse) {
          updateTypesMap[updateType['id']] = updateType;
        }
        
        // חיבור סוגי העדכונים לעדכונים
        final updatesWithTypes = List<Map<String, dynamic>>.from(response);
        for (final update in updatesWithTypes) {
          if (update['update_type_id'] != null) {
            update['update_types'] = updateTypesMap[update['update_type_id']];
          }
        }
        
        setState(() {
          _updates = updatesWithTypes;
          _isLoading = false;
        });
        
        // טעינת מצב מועדפים לכל העדכונים
        final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);
        for (final update in _updates) {
          favoritesNotifier.loadFavoriteState('update', update['id']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת העדכונים: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'עדכוני הסטודיו',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
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
              onRefresh: _loadUpdates,
              child: _updates.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'אין עדכונים זמינים',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _updates.length,
                      itemBuilder: (context, index) {
                        final update = _updates[index];
                        return _buildUpdateCard(update, index);
                      },
                    ),
            ),
    );
  }

  Widget _buildUpdateCard(Map<String, dynamic> update, int index) {
    return VisibilityDetector(
      key: Key('update_${update['id']}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5 && !_viewedUpdates.contains(update['id'])) {
          _viewedUpdates.add(update['id']);
          _trackView(update['id']);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          // כותרת ותאריך
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // סוג עדכון
                    if (update['update_types'] != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _parseColor(update['update_types']['color']).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          update['update_types']['name_he'] ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            color: _parseColor(update['update_types']['color']),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    
                    Expanded(
                      child: Text(
                        update['title_he'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatDate(update['created_at']),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE91E63),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // שם מחבר (אם קיים)
                if (update['author_name'] != null && update['author_name'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'באמצעות ${update['author_name']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // תמונה (אם קיימת)
                if (update['image_url'] != null && update['image_url'].toString().isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        update['image_url'],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                
                // תוכן העדכון
                Text(
                  update['content_he'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // פעולות
                Row(
                  children: [
                    // צפיות
                    Row(
                      children: [
                        const Icon(
                          Icons.visibility,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${update['views_count'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // לייקים
                    Consumer(
                      builder: (context, ref, child) {
                        final favoritesNotifier = ref.watch(favoritesNotifierProvider.notifier);
                        final favoriteStates = ref.watch(favoritesNotifierProvider);
                        final key = 'update_${update['id']}';
                        final isLiked = favoriteStates[key] ?? false;
                        
                        return GestureDetector(
                          onTap: () async {
                            await _toggleLike(update['id']);
                            await favoritesNotifier.toggleFavorite('update', update['id']);
                          },
                          child: Row(
                            children: [
                              Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 16,
                                color: isLiked ? const Color(0xFFE91E63) : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${update['likes_count'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    const Spacer(),
                    
                    // כפתור לייק
                    Consumer(
                      builder: (context, ref, child) {
                        final favoritesNotifier = ref.watch(favoritesNotifierProvider.notifier);
                        final favoriteStates = ref.watch(favoritesNotifierProvider);
                        final key = 'update_${update['id']}';
                        final isLiked = favoriteStates[key] ?? false;
                        
                        return IconButton(
                          onPressed: () async {
                            await _toggleLike(update['id']);
                            await favoritesNotifier.toggleFavorite('update', update['id']);
                          },
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? const Color(0xFFE91E63) : Colors.white70,
                            size: 20,
                          ),
                        );
                      },
                    ),
                    
                    // כפתור שיתוף
                    IconButton(
                      onPressed: () {
                        _shareUpdate(update);
                      },
                      icon: const Icon(
                        Icons.share,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _trackView(String updateId) async {
    try {
      // עדכון פשוט של מונה הצפיות במסד הנתונים
      final currentUpdate = _updates.firstWhere((u) => u['id'] == updateId);
      final currentCount = currentUpdate['views_count'] ?? 0;
      final newCount = currentCount + 1;
      
      await _supabase
          .from('updates')
          .update({'views_count': newCount})
          .eq('id', updateId);
      
      // עדכון מקומי של מונה הצפיות
      setState(() {
        final index = _updates.indexWhere((u) => u['id'] == updateId);
        if (index != -1) {
          _updates[index]['views_count'] = newCount;
        }
      });
    } catch (e) {
      // שגיאות מעקב לא צריכות להפריע לחוויית המשתמש
      debugPrint('Error tracking view: $e');
    }
  }

  Future<void> _toggleLike(String updateId) async {
    try {
      // עדכון פשוט של מונה הלייקים במסד הנתונים
      final currentUpdate = _updates.firstWhere((u) => u['id'] == updateId);
      final currentCount = currentUpdate['likes_count'] ?? 0;
      final newCount = currentCount + 1;
      
      await _supabase
          .from('updates')
          .update({'likes_count': newCount})
          .eq('id', updateId);
      
      // עדכון מקומי
      setState(() {
        final index = _updates.indexWhere((u) => u['id'] == updateId);
        if (index != -1) {
          _updates[index]['likes_count'] = newCount;
        }
      });
    } catch (e) {
      debugPrint('Error tracking like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה בעדכון הלייק')),
        );
      }
    }
  }

  void _shareUpdate(Map<String, dynamic> update) async {
    final title = update['title_he'] ?? 'עדכון מהסטודיו';
    final content = update['content_he'] ?? '';
    final shareText = '$title\n\n$content\n\nסטודיו שרון לריקוד - ZaZa Dance';
    
    try {
      await Share.share(
        shareText,
        subject: title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה בשיתוף העדכון')),
        );
      }
    }
  }

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return const Color(0xFFE91E63); // צבע ברירת מחדל
    }
    
    try {
      String cleanColor = colorString.replaceAll('#', '');
      if (cleanColor.length == 6) {
        return Color(int.parse('0xFF$cleanColor'));
      }
      return const Color(0xFFE91E63);
    } catch (e) {
      return const Color(0xFFE91E63);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'עכשיו';
      } else if (difference.inHours < 1) {
        return 'לפני ${difference.inMinutes} דקות';
      } else if (difference.inDays < 1) {
        return 'לפני ${difference.inHours} שעות';
      } else if (difference.inDays == 1) {
        return 'אתמול';
      } else if (difference.inDays < 7) {
        return 'לפני ${difference.inDays} ימים';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}