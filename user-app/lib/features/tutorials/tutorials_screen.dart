import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'video_player_screen.dart';
import '../favorites/favorites_service.dart';

class TutorialsScreen extends ConsumerStatefulWidget {
  const TutorialsScreen({super.key});

  @override
  ConsumerState<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends ConsumerState<TutorialsScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _tutorials = [];
  String? _selectedCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTutorialsData();
  }

  Future<void> _loadTutorialsData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // טעינת קטגוריות מדריכים
      final categoriesResponse = await _supabase
          .from('tutorial_categories')
          .select('*')
          .eq('is_active', true)
          .order('name');

      // טעינת מדריכים (בלי סינון קטגוריה בהתחלה)
      final tutorialsResponse = await _supabase
          .from('tutorials')
          .select('''
            *,
            tutorial_categories(id, name, color)
          ''')
          .eq('is_active', true)
          .eq('is_published', true)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(categoriesResponse);
          _tutorials = List<Map<String, dynamic>>.from(tutorialsResponse);
          _isLoading = false;
        });
        
        // טעינת מצב מועדפים לכל המדריכים
        final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);
        for (final tutorial in _tutorials) {
          favoritesNotifier.loadFavoriteState('tutorial', tutorial['id']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת המדריכים: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredTutorials {
    if (_selectedCategoryId == null) return _tutorials;
    return _tutorials.where((tutorial) => 
      tutorial['category_id'] == _selectedCategoryId
    ).toList();
  }

  Future<void> _shareVideo(Map<String, dynamic> tutorial) async {
    try {
      final title = tutorial['title_he'] ?? 'מדריך ריקוד';
      final videoUrl = tutorial['video_url'] ?? '';
      final description = tutorial['description_he'] ?? '';
      
      final shareText = '$title\n\n$description\n\nצפו במדריך: $videoUrl\n\nמסטודיו שרון לריקוד';
      
      await Share.share(
        shareText,
        subject: title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשיתוף המדריך: $e'),
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
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'מדריכי וידאו',
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
              onRefresh: _loadTutorialsData,
              child: Column(
                children: [
                  // קטגוריות מדריכים
                  if (_categories.isNotEmpty) _buildCategoriesSection(),
                  
                  // רשימת מדריכים
                  Expanded(
                    child: _buildTutorialsList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'קטגוריות מדריכים',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length + 1, // +1 עבור "הכל"
              itemBuilder: (context, index) {
                if (index == 0) {
                  // כפתור "הכל"
                  return _buildCategoryChip(
                    name: 'הכל',
                    color: const Color(0xFF00BCD4),
                    isSelected: _selectedCategoryId == null,
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = null;
                      });
                    },
                  );
                }
                
                final category = _categories[index - 1];
                final isSelected = _selectedCategoryId == category['id'];
                
                return _buildCategoryChip(
                  name: category['name'] ?? '',
                  color: _parseColor(category['color']),
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = category['id'];
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String name,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: 1.5,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialsList() {
    final filteredTutorials = _filteredTutorials;
    
    if (filteredTutorials.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'אין מדריכים זמינים',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'מדריכים חדשים יתווספו בקרוב',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTutorials.length,
      itemBuilder: (context, index) {
        final tutorial = filteredTutorials[index];
        return _buildTutorialCard(tutorial);
      },
    );
  }

  Widget _buildTutorialCard(Map<String, dynamic> tutorial) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(tutorial: tutorial),
          ),
        );
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
        children: [
          // Thumbnail וידאו
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // אייקון YouTube
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                // מידע נוסף על הוידאו
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tutorial['views_count'] ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // אייקון לייק
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Color(0xFFE91E63),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tutorial['likes_count'] ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // פרטי המדריך
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // כותרת המדריך
                Text(
                  tutorial['title_he'] ?? 'ללא כותרת',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // תיאור המדריך
                if (tutorial['description_he'] != null)
                  Text(
                    tutorial['description_he'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                const SizedBox(height: 12),
                
                // מידע נוסף ופעולות
                Row(
                  children: [
                    // קטגוריה
                    if (tutorial['tutorial_categories'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _parseColor(
                            tutorial['tutorial_categories']['color'],
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tutorial['tutorial_categories']['name'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: _parseColor(
                              tutorial['tutorial_categories']['color'],
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    
                    const Spacer(),
                    
                    // כפתור שמירה למועדפים
                    Consumer(
                      builder: (context, ref, child) {
                        final favoritesNotifier = ref.watch(favoritesNotifierProvider.notifier);
                        final favoriteStates = ref.watch(favoritesNotifierProvider);
                        final key = 'tutorial_${tutorial['id']}';
                        final isFavorite = favoriteStates[key] ?? false;
                        
                        return IconButton(
                          onPressed: () async {
                            await favoritesNotifier.toggleFavorite('tutorial', tutorial['id']);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isFavorite 
                                      ? 'הוסר מהמועדפים' 
                                      : 'נוסף למועדפים'),
                                  backgroundColor: const Color(0xFF4CAF50),
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_outline,
                            color: isFavorite ? const Color(0xFFE91E63) : const Color(0xFF00BCD4),
                          ),
                        );
                      },
                    ),
                    
                    // כפתור שיתוף
                    IconButton(
                      onPressed: () => _shareVideo(tutorial),
                      icon: const Icon(
                        Icons.share,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null) return const Color(0xFF00BCD4);
    
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF00BCD4);
    }
  }
}