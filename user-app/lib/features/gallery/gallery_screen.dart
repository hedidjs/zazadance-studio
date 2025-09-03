import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'photo_view_screen.dart';
import '../favorites/favorites_service.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _galleryItems = [];
  String? _selectedCategoryId;
  bool _isLoading = true;
  bool _showingAlbums = true; // מצב תצוגה: אלבומים או תמונות

  @override
  void initState() {
    super.initState();
    _loadGalleryData();
  }

  Future<void> _loadGalleryData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // טעינת אלבומים (שמשמשים כקטגוריות)
      final categoriesResponse = await _supabase
          .from('gallery_albums')
          .select('id, name_he, description_he, cover_image_url')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      // טעינת תמונות מהאלבומים
      final galleryResponse = await _supabase
          .from('gallery_images')
          .select('''
            id, title_he, media_url, thumbnail_url, album_id, likes_count, views_count, created_at,
            gallery_albums(id, name_he, cover_image_url)
          ''')
          .eq('is_active', true)
          .eq('is_published', true)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(categoriesResponse);
          _galleryItems = List<Map<String, dynamic>>.from(galleryResponse);
          _isLoading = false;
        });
        
        // טעינת מצב מועדפים לכל פריטי הגלריה
        final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);
        for (final item in _galleryItems) {
          favoritesNotifier.loadFavoriteState('gallery', item['id']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת הגלריה: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredGalleryItems {
    if (_selectedCategoryId == null) return _galleryItems;
    return _galleryItems.where((item) => 
      item['album_id'] == _selectedCategoryId
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: _showingAlbums ? AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'גלריית תמונות',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ) : AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          _categories.firstWhere((cat) => cat['id'] == _selectedCategoryId, 
              orElse: () => {'name_he': 'אלבום'})['name_he'] ?? 'אלבום',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _showingAlbums = true;
              _selectedCategoryId = null;
            });
          },
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
              onRefresh: _loadGalleryData,
              child: _showingAlbums 
                  ? _buildAlbumsView()
                  : _buildGalleryGrid(),
            ),
    );
  }

  Widget _buildAlbumsView() {
    if (_categories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_album_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'אין אלבומים זמינים',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final album = _categories[index];
        final imageCount = _galleryItems.where((item) => item['album_id'] == album['id']).length;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategoryId = album['id'];
              _showingAlbums = false;
            });
          },
          child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // תמונת כריכת האלבום
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: album['cover_image_url'] != null
                        ? Image.network(
                            album['cover_image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade800,
                              child: const Icon(Icons.photo_album, color: Colors.white54, size: 40),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade800,
                            child: const Icon(Icons.photo_album, color: Colors.white54, size: 40),
                          ),
                  ),
                ),
                
                // פרטי האלבום
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            album['name_he'] ?? 'אלבום ללא שם',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.photo, size: 10, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(
                              '$imageCount',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
              'אלבומי גלריה',
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
                
                final album = _categories[index - 1];
                final isSelected = _selectedCategoryId == album['id'];
                
                return _buildCategoryChip(
                  name: album['name_he'] ?? '',
                  color: const Color(0xFFE91E63), // צבע אחיד לכל האלבומים
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = album['id'];
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

  Widget _buildGalleryGrid() {
    final filteredItems = _filteredGalleryItems;
    
    if (filteredItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'אין תמונות זמינות',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'תמונות חדשות יתווספו בקרוב',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildGalleryCard(item);
      },
    );
  }

  Widget _buildGalleryCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PhotoViewScreen(
              imageUrl: item['media_url'] ?? item['thumbnail_url'] ?? '',
              title: item['title_he'] ?? '',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            // תמונה
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: (item['thumbnail_url'] ?? item['media_url']) != null
                  ? Image.network(
                      item['thumbnail_url'] ?? item['media_url'],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(
                            Icons.photo,
                            size: 40,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(
                          Icons.photo,
                          size: 40,
                          color: Colors.white54,
                        ),
                      ),
                    ),
            ),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // כפתור מועדפים
            Positioned(
              top: 8,
              left: 8,
              child: Consumer(
                builder: (context, ref, child) {
                  final favoritesNotifier = ref.watch(favoritesNotifierProvider.notifier);
                  final favoriteStates = ref.watch(favoritesNotifierProvider);
                  final key = 'gallery_${item['id']}';
                  final isFavorite = favoriteStates[key] ?? false;
                  
                  return GestureDetector(
                    onTap: () async {
                      await favoritesNotifier.toggleFavorite('gallery', item['id']);
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
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        isFavorite ? Icons.star : Icons.star_outline,
                        color: isFavorite ? const Color(0xFFE91E63) : Colors.white,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // כותרת התמונה
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title_he'] ?? 'ללא כותרת',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // קטגוריה ולייקים
                  Row(
                    children: [
                      // אלבום
                      if (item['gallery_albums'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE91E63).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item['gallery_albums']['name_he'] ?? '',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFE91E63),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      
                      const Spacer(),
                      
                      // לייקים
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Color(0xFFE91E63),
                            size: 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${item['likes_count'] ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
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


}