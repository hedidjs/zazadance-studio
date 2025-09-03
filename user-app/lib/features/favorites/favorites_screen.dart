import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../tutorials/video_player_screen.dart';
import '../gallery/photo_view_screen.dart';
import '../store/product_detail_screen.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  
  List<Map<String, dynamic>> _favoriteTutorials = [];
  List<Map<String, dynamic>> _favoriteGalleryItems = [];
  List<Map<String, dynamic>> _favoriteProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // טעינת מדריכים מועדפים
      final favoriteTutorialsResponse = await _supabase
          .from('user_favorites')
          .select('''
            *,
            tutorials!inner(
              *,
              tutorial_categories(id, name, color)
            )
          ''')
          .eq('user_id', user.id)
          .eq('content_type', 'tutorial')
          .eq('tutorials.is_active', true)
          .eq('tutorials.is_published', true);

      // טעינת תמונות מועדפות מהגלריה
      final favoriteGalleryResponse = await _supabase
          .from('user_favorites')
          .select('''
            *,
            gallery_images!inner(
              *,
              gallery_albums(id, name_he)
            )
          ''')
          .eq('user_id', user.id)
          .eq('content_type', 'gallery')
          .eq('gallery_images.is_active', true);

      // טעינת מוצרים מועדפים
      final favoriteProductsResponse = await _supabase
          .from('user_favorites')
          .select('''
            *,
            products!inner(
              *,
              product_categories(id, name_he)
            )
          ''')
          .eq('user_id', user.id)
          .eq('content_type', 'product')
          .eq('products.is_active', true);

      if (mounted) {
        setState(() {
          _favoriteTutorials = List<Map<String, dynamic>>.from(
            favoriteTutorialsResponse.map((item) => item['tutorials']),
          );
          _favoriteGalleryItems = List<Map<String, dynamic>>.from(
            favoriteGalleryResponse.map((item) => item['gallery_images']),
          );
          _favoriteProducts = List<Map<String, dynamic>>.from(
            favoriteProductsResponse.map((item) => item['products']),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת המועדפים: $e')),
        );
      }
    }
  }

  Future<void> _removeFromFavorites(String contentType, String contentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('content_type', contentType)
          .eq('content_id', contentId);

      // עדכון הרשימות המקומיות
      setState(() {
        if (contentType == 'tutorial') {
          _favoriteTutorials.removeWhere((item) => item['id'] == contentId);
        } else if (contentType == 'gallery') {
          _favoriteGalleryItems.removeWhere((item) => item['id'] == contentId);
        } else if (contentType == 'product') {
          _favoriteProducts.removeWhere((item) => item['id'] == contentId);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הוסר מהמועדפים'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בהסרת המועדף: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'המועדפים שלי',
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE91E63),
          labelColor: const Color(0xFFE91E63),
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              icon: const Icon(Icons.play_circle_outline),
              text: 'מדריכים (${_favoriteTutorials.length})',
            ),
            Tab(
              icon: const Icon(Icons.photo_library_outlined),
              text: 'גלריה (${_favoriteGalleryItems.length})',
            ),
            Tab(
              icon: const Icon(Icons.shopping_bag_outlined),
              text: 'מוצרים (${_favoriteProducts.length})',
            ),
          ],
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
              onRefresh: _loadFavorites,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTutorialsFavorites(),
                  _buildGalleryFavorites(),
                  _buildProductsFavorites(),
                ],
              ),
            ),
    );
  }

  Widget _buildTutorialsFavorites() {
    if (_favoriteTutorials.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'אין מדריכים מועדפים',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'התחל לצפות במדריכים ולשמור אותם כמועדפים',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteTutorials.length,
      itemBuilder: (context, index) {
        final tutorial = _favoriteTutorials[index];
        return _buildTutorialCard(tutorial);
      },
    );
  }

  Widget _buildGalleryFavorites() {
    if (_favoriteGalleryItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'אין תמונות מועדפות',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'עיין בגלריה ושמור תמונות כמועדפים',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _favoriteGalleryItems.length,
      itemBuilder: (context, index) {
        final item = _favoriteGalleryItems[index];
        return _buildGalleryCard(item);
      },
    );
  }

  Widget _buildTutorialCard(Map<String, dynamic> tutorial) {
    return Container(
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
        children: [
          // Thumbnail וידאו
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(tutorial: tutorial),
                ),
              );
            },
            child: Container(
              height: 180,
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
                  // אייקון Play
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  
                  // כפתור הסרה מהמועדפים
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () => _removeFromFavorites('tutorial', tutorial['id']),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Color(0xFFE91E63),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // תיאור קצר
                if (tutorial['description_he'] != null)
                  Text(
                    tutorial['description_he'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                const SizedBox(height: 12),
                
                // מידע נוסף
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
                            fontSize: 11,
                            color: _parseColor(
                              tutorial['tutorial_categories']['color'],
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    
                    const Spacer(),
                    
                    // סטטיסטיקות
                    Row(
                      children: [
                        const Icon(
                          Icons.visibility,
                          color: Colors.white60,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tutorial['views_count'] ?? 0}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
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
    );
  }

  Widget _buildGalleryCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PhotoViewScreen(
              imageUrl: item['media_url'] ?? '',
              title: item['title_he'] ?? '',
            ),
          ),
        );
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
        child: Stack(
          children: [
            // תמונה
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item['media_url'] != null
                  ? Image.network(
                      item['media_url'],
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
                borderRadius: BorderRadius.circular(12),
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
            
            // כפתור הסרה מהמועדפים
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () => _removeFromFavorites('gallery', item['id']),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Color(0xFFE91E63),
                    size: 18,
                  ),
                ),
              ),
            ),
            
            // כותרת התמונה
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                item['title_he'] ?? 'ללא כותרת',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsFavorites() {
    if (_favoriteProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'אין מוצרים מועדפים',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'עיין בחנות ושמור מוצרים כמועדפים',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _favoriteProducts.length,
      itemBuilder: (context, index) {
        final product = _favoriteProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // תמונת מוצר
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: product['image_url'] != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.network(
                              product['image_url'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.store, size: 40, color: Colors.white54),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.store, size: 40, color: Colors.white54),
                          ),
                  ),
                  
                  // כפתור הסרה מהמועדפים
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () => _removeFromFavorites('product', product['id']),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Color(0xFFE91E63),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // פרטי מוצר
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name_he'] ?? 'ללא שם',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    Text(
                      '₪${product['price']?.toString() ?? '0'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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