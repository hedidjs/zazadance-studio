import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_core/repositories/gallery_repository.dart';
import 'package:shared_core/utils/pagination_result.dart';
import 'package:shared_core/models/gallery_image.dart';
import 'photo_view_screen.dart';
import 'video_view_screen.dart';
import '../favorites/favorites_service.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen>
    with TickerProviderStateMixin {
  final _galleryRepository = SupabaseGalleryRepository();
  
  PaginationResult<GalleryImage>? _paginationResult;
  List<Map<String, String>> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  
  // Zoom state
  final TransformationController _transformationController = 
      TransformationController();
  int _crossAxisCount = 3;
  double _zoomLevel = 1.0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadGalleryData();
    _loadCategories();
    _scrollController.addListener(_onScroll);
    _loadUserPreferences();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _transformationController.dispose();
    _animationController.dispose();
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
      final categories = await (_galleryRepository as SupabaseGalleryRepository).getGalleryCategories();
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

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _crossAxisCount = prefs.getInt('gallery_columns') ?? 3;
    });
  }

  Future<void> _saveUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('gallery_columns', _crossAxisCount);
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    final scale = details.scale;
    
    // Calculate new column count based on scale
    int newCrossAxisCount;
    if (scale < 0.7) {
      newCrossAxisCount = 1; // Zoom in to 1 image
    } else if (scale < 0.8) {
      newCrossAxisCount = 2;
    } else if (scale < 1.2) {
      newCrossAxisCount = 3; // Default
    } else if (scale < 1.5) {
      newCrossAxisCount = 4;
    } else if (scale < 1.8) {
      newCrossAxisCount = 5;
    } else if (scale < 2.2) {
      newCrossAxisCount = 6;
    } else {
      newCrossAxisCount = 7; // Zoom out to 7 columns (max ~50 images)
    }

    if (newCrossAxisCount != _crossAxisCount) {
      HapticFeedback.selectionClick();
      setState(() {
        _crossAxisCount = newCrossAxisCount;
      });
      _animationController.reset();
      _animationController.forward();
      _saveUserPreferences();
    }
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    // Don't reset the transformation - let the user keep their zoom level
    // The column change already happened in _onInteractionUpdate
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
                  Expanded(
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      onInteractionUpdate: _onInteractionUpdate,
                      onInteractionEnd: _onInteractionEnd,
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: _buildGalleryGrid(),
                          );
                        },
                      ),
                    ),
                  ),
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
          final categoryId = category['id']!;
          final categoryName = category['name']!;
          final isSelected = _selectedCategory == categoryId;
          
          return _buildCategoryChip(
            name: categoryName,
            color: const Color(0xFFE91E63), // צבע אחיד לכל הקטגוריות
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedCategory = categoryId;
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
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount,
        crossAxisSpacing: _crossAxisCount == 1 ? 0 : 4,
        mainAxisSpacing: _crossAxisCount == 1 ? 0 : 4,
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
        if (image.isVideo) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VideoViewScreen(
                videoUrl: image.mediaUrl,
                title: image.titleHe,
                image: image,
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PhotoViewScreen(
                imageUrl: image.mediaUrl,
                title: image.titleHe,
                image: image,
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_crossAxisCount == 1 ? 0 : 8),
          boxShadow: _crossAxisCount == 1 
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_crossAxisCount == 1 ? 0 : 8),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: image.getDisplayImageUrl(preferThumbnail: _crossAxisCount > 3),
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
                  child: Center(
                    child: Icon(
                      image.isVideo ? Icons.videocam : Icons.photo,
                      size: 30,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
              
              // Video play overlay
              if (image.isVideo)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(_crossAxisCount == 1 ? 0 : 8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }


}