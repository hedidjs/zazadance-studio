import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_core/repositories/gallery_repository.dart';
import 'package:shared_core/utils/pagination_result.dart';
import 'package:shared_core/models/gallery_image.dart';
import 'package:shared_core/models/gallery_album.dart';
import 'photo_view_screen.dart';
import 'video_view_screen.dart';
import '../favorites/favorites_service.dart';

class AlbumDetailScreen extends ConsumerStatefulWidget {
  final GalleryAlbum album;

  const AlbumDetailScreen({
    super.key,
    required this.album,
  });

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen>
    with TickerProviderStateMixin {
  final _galleryRepository = SupabaseGalleryRepository();
  
  PaginationResult<GalleryImage>? _paginationResult;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  
  // Fixed grid
  int _crossAxisCount = 5; // Fixed 5 columns

  @override
  void initState() {
    super.initState();
    _loadAlbumImages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  Future<void> _loadAlbumImages() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _galleryRepository.getGalleryImages(
        page: 1,
        pageSize: 40,
        category: widget.album.id,
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
            SnackBar(content: Text('שגיאה בטעינת תמונות האלבום: ${result.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת תמונות האלבום: $e')),
        );
      }
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
        pageSize: 40,
        category: widget.album.id,
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
        title: Text(
          widget.album.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final favoritesNotifier = ref.watch(favoritesNotifierProvider.notifier);
              final isFavorite = ref.watch(favoritesNotifierProvider)['album_${widget.album.id}'] ?? false;
              
              return IconButton(
                onPressed: () {
                  favoritesNotifier.toggleFavorite('album', widget.album.id);
                },
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : Colors.grey[400],
                  size: 24,
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFE91E63),
            ),
          )
        : _buildPhotosGrid(),
    );
  }

  Widget _buildPhotosGrid() {
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
              'אין תמונות באלבום זה',
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

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.8 &&
            !_isLoadingMore && 
            _paginationResult != null && 
            _paginationResult!.hasMore) {
          _loadMoreImages();
        }
        return false;
      },
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _crossAxisCount,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
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
          return _buildPhotoCard(image);
        },
      ),
    );
  }

  Widget _buildPhotoCard(GalleryImage image) {
    return RepaintBoundary(
      child: GestureDetector(
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
            final currentIndex = _paginationResult!.items.indexOf(image);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PhotoViewScreen(
                  imageUrl: image.mediaUrl,
                  title: image.titleHe,
                  image: image,
                  images: _paginationResult!.items,
                  initialIndex: currentIndex,
                ),
              ),
            );
          }
        },
        child: Container(
          decoration: const BoxDecoration(),
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: image.getDisplayImageUrl(preferThumbnail: _crossAxisCount > 3),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  memCacheWidth: _crossAxisCount > 5 ? 200 : 400,
                  memCacheHeight: _crossAxisCount > 5 ? 200 : 400,
                  maxWidthDiskCache: 800,
                  maxHeightDiskCache: 800,
                  cacheKey: '${image.id}_${_crossAxisCount > 3 ? 'thumb' : 'full'}',
                  fadeInDuration: const Duration(milliseconds: 200),
                  fadeOutDuration: const Duration(milliseconds: 100),
                  placeholder: (context, url) => _buildPlaceholder(),
                  errorWidget: (context, url, error) => _buildErrorWidget(),
                ),
                
                // Video play overlay
                if (image.isVideo)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                          size: _crossAxisCount > 8 ? 20 : (_crossAxisCount > 5 ? 30 : 40),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[850],
      child: Center(
        child: SizedBox(
          width: _crossAxisCount > 8 ? 12 : 20,
          height: _crossAxisCount > 8 ? 12 : 20,
          child: CircularProgressIndicator(
            color: Colors.grey[600],
            strokeWidth: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[850],
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: _crossAxisCount > 8 ? 16 : (_crossAxisCount > 5 ? 20 : 30),
          color: Colors.grey[600],
        ),
      ),
    );
  }
}