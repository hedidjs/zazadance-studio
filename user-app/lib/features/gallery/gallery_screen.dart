import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_core/repositories/gallery_repository.dart';
import 'package:shared_core/utils/pagination_result.dart';
import 'package:shared_core/models/gallery_image.dart';
import 'photo_view_screen.dart';
import '../favorites/favorites_service.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final _galleryRepository = SupabaseGalleryRepository();
  
  PaginationResult<GalleryImage>? _paginationResult;
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadGalleryData();
    _loadCategories();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore && 
        _paginationResult != null && 
        _paginationResult!.hasMore) {
      _loadMoreImages();
    }
  }

  Future<void> _loadGalleryData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _galleryRepository.getGalleryImages(
        page: 1,
        pageSize: 20,
        category: _selectedCategory,
      );

      if (mounted) {
        if (result.success && result.images != null) {
          setState(() {
            _paginationResult = result.images;
            _isLoading = false;
          });
          
          // Load favorite states for all images
          final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);
          for (final image in _paginationResult!.items) {
            favoritesNotifier.loadFavoriteState('gallery', image.id);
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('שגיאה בטעינת הגלריה: ${result.errorMessage}')),
          );
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

  Future<void> _loadCategories() async {
    try {
      final categories = await _galleryRepository.getGalleryCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      // Categories are optional, so we don't show error
    }
  }

  Future<void> _loadMoreImages() async {
    if (_paginationResult == null || !_paginationResult!.hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _galleryRepository.getGalleryImages(
        page: _paginationResult!.currentPage + 1,
        pageSize: 20,
        category: _selectedCategory,
      );

      if (mounted) {
        if (result.success && result.images != null) {
          setState(() {
            _paginationResult = _paginationResult!.appendPage(result.images!);
            _isLoadingMore = false;
          });
          
          // Load favorite states for new images
          final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);
          for (final image in result.images!.items) {
            favoritesNotifier.loadFavoriteState('gallery', image.id);
          }
        } else {
          setState(() {
            _isLoadingMore = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
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
          'גלריית תמונות',
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
              onRefresh: _loadGalleryData,
              child: Column(
                children: [
                  if (_categories.isNotEmpty) _buildCategoriesSection(),
                  Expanded(child: _buildGalleryGrid()),
                ],
              ),
            ),
    );
  }


  Widget _buildCategoriesSection() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              isSelected: _selectedCategory == null,
              onTap: () {
                setState(() {
                  _selectedCategory = null;
                });
                _loadGalleryData();
              },
            );
          }
          
          final category = _categories[index - 1];
          final isSelected = _selectedCategory == category;
          
          return _buildCategoryChip(
            name: category,
            color: const Color(0xFFE91E63), // צבע אחיד לכל הקטגוריות
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
              _loadGalleryData();
            },
          );
        },
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
    if (_paginationResult == null || _paginationResult!.items.isEmpty) {
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
      controller: _scrollController,
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemCount: _paginationResult!.items.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _paginationResult!.items.length) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFE91E63),
            ),
          );
        }
        
        final image = _paginationResult!.items[index];
        return _buildGalleryCard(image);
      },
    );
  }

  Widget _buildGalleryCard(GalleryImage image) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PhotoViewScreen(
              imageUrl: image.imageUrl,
              title: image.titleHe,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
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
            // תמונה עם caching
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: image.getDisplayImageUrl(preferThumbnail: true),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE91E63),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(
                      Icons.photo,
                      size: 30,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            
            // כפתור מועדפים
            Positioned(
              top: 6,
              left: 6,
              child: Consumer(
                builder: (context, ref, child) {
                  final favoritesNotifier = ref.watch(favoritesNotifierProvider.notifier);
                  final favoriteStates = ref.watch(favoritesNotifierProvider);
                  final key = 'gallery_${image.id}';
                  final isFavorite = favoriteStates[key] ?? false;
                  
                  return GestureDetector(
                    onTap: () async {
                      await favoritesNotifier.toggleFavorite('gallery', image.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isFavorite 
                                ? 'הוסר מהמועדפים' 
                                : 'נוסף למועדפים'),
                            backgroundColor: const Color(0xFF4CAF50),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isFavorite ? Icons.star : Icons.star_outline,
                        color: isFavorite ? const Color(0xFFE91E63) : Colors.white,
                        size: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // כותרת התמונה
            if (image.titleHe.isNotEmpty)
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Text(
                  image.titleHe,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black,
                      ),
                    ],
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


}