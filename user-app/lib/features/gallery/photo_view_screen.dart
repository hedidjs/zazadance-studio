import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shared_core/models/gallery_image.dart';
import 'video_view_screen.dart';
import '../favorites/favorites_service.dart';

class PhotoViewScreen extends ConsumerStatefulWidget {
  final String imageUrl;
  final String title;
  final GalleryImage? image;
  final List<GalleryImage>? images;
  final int? initialIndex;

  const PhotoViewScreen({
    super.key,
    required this.imageUrl,
    required this.title,
    this.image,
    this.images,
    this.initialIndex,
  });

  @override
  ConsumerState<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends ConsumerState<PhotoViewScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  GalleryImage get currentImage {
    if (widget.images != null && widget.images!.isNotEmpty) {
      return widget.images![_currentIndex];
    }
    return widget.image!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentImage.titleHe,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (widget.images != null && widget.images!.length > 1)
              Text(
                '${_currentIndex + 1} / ${widget.images!.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('שיתוף התמונה')),
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final favoritesNotifier = ref.watch(favoritesNotifierProvider.notifier);
              final favoriteStates = ref.watch(favoritesNotifierProvider);
              final key = 'gallery_${currentImage.id}';
              final isFavorite = favoriteStates[key] ?? false;
              
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_outline, 
                  color: isFavorite ? const Color(0xFFE91E63) : Colors.white,
                ),
                onPressed: () async {
                  await favoritesNotifier.toggleFavorite('gallery', currentImage.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isFavorite 
                          ? 'הוסר מהמועדפים' 
                          : 'נוסף למועדפים'),
                      backgroundColor: const Color(0xFF4CAF50),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: widget.images != null && widget.images!.length > 1
          ? PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                final image = widget.images![index];
                
                // If this is a video, show a video placeholder with play icon
                if (image.isVideo) {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_circle_filled,
                              size: 80,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'החלק לצפייה בסרטון',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.contained,
                  );
                }
                
                // Regular image display
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(image.mediaUrl),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2.0,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.white60,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'שגיאה בטעינת התמונה',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              itemCount: widget.images!.length,
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE91E63),
                ),
              ),
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
              pageController: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                
                // Check if the current item is a video and navigate to VideoViewScreen
                final currentItem = widget.images![index];
                if (currentItem.isVideo) {
                  // Navigate to video screen
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => VideoViewScreen(
                          videoUrl: currentItem.mediaUrl,
                          title: currentItem.titleHe,
                          image: currentItem,
                          images: widget.images,
                          initialIndex: index,
                        ),
                      ),
                    );
                  });
                }
              },
            )
          : PhotoView(
              imageProvider: NetworkImage(widget.imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.0,
              initialScale: PhotoViewComputedScale.contained,
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.white60,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'שגיאה בטעינת התמונה',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}