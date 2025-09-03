import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../tutorials/video_player_screen.dart';
import '../gallery/photo_view_screen.dart';
import '../store/product_detail_screen.dart';

class FavoritesFullScreen extends ConsumerStatefulWidget {
  const FavoritesFullScreen({super.key});

  @override
  ConsumerState<FavoritesFullScreen> createState() => _FavoritesFullScreenState();
}

class _FavoritesFullScreenState extends ConsumerState<FavoritesFullScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  
  late TabController _tabController;
  
  List<Map<String, dynamic>> _favoriteTutorials = [];
  List<Map<String, dynamic>> _favoriteGallery = [];
  List<Map<String, dynamic>> _favoriteProducts = [];
  
  bool _isLoadingTutorials = true;
  bool _isLoadingGallery = true;
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllFavorites() async {
    await Future.wait([
      _loadFavoriteTutorials(),
      _loadFavoriteGallery(),
      _loadFavoriteProducts(),
    ]);
  }

  Future<void> _loadFavoriteTutorials() async {
    try {
      setState(() {
        _isLoadingTutorials = true;
      });

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get favorite tutorial IDs
      final favoritesResponse = await _supabase
          .from('user_favorites')
          .select('content_id')
          .eq('user_id', user.id)
          .eq('content_type', 'tutorial');

      if (favoritesResponse.isEmpty) {
        setState(() {
          _favoriteTutorials = [];
          _isLoadingTutorials = false;
        });
        return;
      }

      final tutorialIds = favoritesResponse.map((f) => f['content_id']).toList();

      // Get actual tutorial data
      final tutorialsResponse = await _supabase
          .from('tutorials')
          .select('*')
          .inFilter('id', tutorialIds)
          .eq('is_active', true)
          .eq('is_published', true);

      if (mounted) {
        setState(() {
          _favoriteTutorials = List<Map<String, dynamic>>.from(tutorialsResponse);
          _isLoadingTutorials = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTutorials = false;
        });
        _showErrorSnackBar('שגיאה בטעינת המדריכים המועדפים: $e');
      }
    }
  }

  Future<void> _loadFavoriteGallery() async {
    try {
      setState(() {
        _isLoadingGallery = true;
      });

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get favorite gallery IDs
      final favoritesResponse = await _supabase
          .from('user_favorites')
          .select('content_id')
          .eq('user_id', user.id)
          .eq('content_type', 'gallery');

      if (favoritesResponse.isEmpty) {
        setState(() {
          _favoriteGallery = [];
          _isLoadingGallery = false;
        });
        return;
      }

      final galleryIds = favoritesResponse.map((f) => f['content_id']).toList();

      // Get actual gallery data
      final galleryResponse = await _supabase
          .from('gallery_images')
          .select('''
            id, title_he, media_url, thumbnail_url, created_at,
            gallery_albums(id, name_he, cover_image_url)
          ''')
          .inFilter('id', galleryIds)
          .eq('is_active', true)
          .eq('is_published', true);

      if (mounted) {
        setState(() {
          _favoriteGallery = List<Map<String, dynamic>>.from(galleryResponse);
          _isLoadingGallery = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGallery = false;
        });
        _showErrorSnackBar('שגיאה בטעינת התמונות המועדפות: $e');
      }
    }
  }

  Future<void> _loadFavoriteProducts() async {
    try {
      setState(() {
        _isLoadingProducts = true;
      });

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get favorite product IDs
      final favoritesResponse = await _supabase
          .from('user_favorites')
          .select('content_id')
          .eq('user_id', user.id)
          .eq('content_type', 'product');

      if (favoritesResponse.isEmpty) {
        setState(() {
          _favoriteProducts = [];
          _isLoadingProducts = false;
        });
        return;
      }

      final productIds = favoritesResponse.map((f) => f['content_id']).toList();

      // Get actual product data
      final productsResponse = await _supabase
          .from('products')
          .select('id, name_he, description_he, price, image_url, purchase_url, category_id')
          .inFilter('id', productIds)
          .eq('is_active', true)
          .eq('availability', true);

      if (mounted) {
        setState(() {
          _favoriteProducts = List<Map<String, dynamic>>.from(productsResponse);
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
        _showErrorSnackBar('שגיאה בטעינת המוצרים המועדפים: $e');
      }
    }
  }

  Future<void> _removeFavorite(String contentType, String contentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('content_type', contentType)
          .eq('content_id', contentId);

      // Reload the appropriate tab
      switch (contentType) {
        case 'tutorial':
          _loadFavoriteTutorials();
          break;
        case 'gallery':
          _loadFavoriteGallery();
          break;
        case 'product':
          _loadFavoriteProducts();
          break;
      }

      _showSuccessSnackBar('הוסר מהמועדפים');
    } catch (e) {
      _showErrorSnackBar('שגיאה בהסרה מהמועדפים: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'המועדפים שלי',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE91E63),
          labelColor: const Color(0xFFE91E63),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(
              icon: Icon(Icons.play_circle_outline),
              text: 'מדריכים',
            ),
            Tab(
              icon: Icon(Icons.photo_library_outlined),
              text: 'תמונות',
            ),
            Tab(
              icon: Icon(Icons.shopping_bag_outlined),
              text: 'מוצרים',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTutorialsTab(),
          _buildGalleryTab(),
          _buildProductsTab(),
        ],
      ),
    );
  }

  Widget _buildTutorialsTab() {
    if (_isLoadingTutorials) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      );
    }

    if (_favoriteTutorials.isEmpty) {
      return _buildEmptyState(
        icon: Icons.play_circle_outline,
        title: 'אין מדריכים מועדפים',
        subtitle: 'המדריכים שתוסיפו למועדפים יופיעו כאן',
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFE91E63),
      onRefresh: _loadFavoriteTutorials,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteTutorials.length,
        itemBuilder: (context, index) {
          final tutorial = _favoriteTutorials[index];
          return _buildTutorialCard(tutorial);
        },
      ),
    );
  }

  Widget _buildGalleryTab() {
    if (_isLoadingGallery) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      );
    }

    if (_favoriteGallery.isEmpty) {
      return _buildEmptyState(
        icon: Icons.photo_library_outlined,
        title: 'אין תמונות מועדפות',
        subtitle: 'התמונות שתוסיפו למועדפים יופיעו כאן',
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFE91E63),
      onRefresh: _loadFavoriteGallery,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: _favoriteGallery.length,
        itemBuilder: (context, index) {
          final image = _favoriteGallery[index];
          return _buildGalleryCard(image);
        },
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_isLoadingProducts) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      );
    }

    if (_favoriteProducts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'אין מוצרים מועדפים',
        subtitle: 'המוצרים שתוסיפו למועדפים יופיעו כאן',
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFE91E63),
      onRefresh: _loadFavoriteProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteProducts.length,
        itemBuilder: (context, index) {
          final product = _favoriteProducts[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialCard(Map<String, dynamic> tutorial) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  tutorial: tutorial,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: tutorial['thumbnail_url'] != null
                      ? Image.network(
                          tutorial['thumbnail_url'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.play_circle_outline,
                              color: Colors.white54,
                              size: 30,
                            ),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.play_circle_outline,
                            color: Colors.white54,
                            size: 30,
                          ),
                        ),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Spacer(),

                          if (tutorial['duration'] != null)
                            Text(
                              tutorial['duration'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white60,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Remove button
                IconButton(
                  onPressed: () => _removeFavorite('tutorial', tutorial['id']),
                  icon: const Icon(
                    Icons.favorite,
                    color: Color(0xFFE91E63),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryCard(Map<String, dynamic> image) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PhotoViewScreen(
              imageUrl: image['media_url'] ?? image['thumbnail_url'] ?? '',
              title: image['title_he'] ?? '',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
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
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (image['thumbnail_url'] ?? image['media_url']) != null
                  ? Image.network(
                      image['thumbnail_url'] ?? image['media_url'],
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

            // Remove button
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () => _removeFavorite('gallery', image['id']),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Color(0xFFE91E63),
                    size: 18,
                  ),
                ),
              ),
            ),

            // Title
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                image['title_he'] ?? 'ללא כותרת',
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

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: const Color(0xFF1E1E1E),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(product: product),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product['image_url'] != null
                      ? Image.network(
                          product['image_url'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white54,
                              size: 30,
                            ),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.white54,
                            size: 30,
                          ),
                        ),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name_he'] ?? 'ללא שם',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      if (product['description_he'] != null)
                        Text(
                          product['description_he'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Spacer(),

                          if (product['price'] != null)
                            Text(
                              '₪${product['price']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE91E63),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Remove button
                IconButton(
                  onPressed: () => _removeFavorite('product', product['id']),
                  icon: const Icon(
                    Icons.favorite,
                    color: Color(0xFFE91E63),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }
}