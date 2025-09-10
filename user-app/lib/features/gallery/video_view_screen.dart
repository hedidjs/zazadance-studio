import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:shared_core/models/gallery_image.dart';
import 'photo_view_screen.dart';
import '../favorites/favorites_service.dart';

class VideoViewScreen extends ConsumerStatefulWidget {
  final String videoUrl;
  final String title;
  final GalleryImage image;
  final List<GalleryImage>? images;
  final int? initialIndex;

  const VideoViewScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.image,
    this.images,
    this.initialIndex,
  });

  @override
  ConsumerState<VideoViewScreen> createState() => _VideoViewScreenState();
}

class _VideoViewScreenState extends ConsumerState<VideoViewScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    _initializePlayer();
  }

  void _initializePlayer() {
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (videoId == null) return;

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        mute: false,
        autoPlay: true,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    );

    _controller.addListener(_listener);
  }

  void _listener() {
    if (_isPlayerReady) {
      setState(() {});
    }
  }

  void _navigateToNext() {
    if (widget.images == null || _currentIndex >= widget.images!.length - 1) return;
    
    final nextIndex = _currentIndex + 1;
    final nextItem = widget.images![nextIndex];
    
    if (nextItem.isVideo) {
      // Navigate to next video
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => VideoViewScreen(
            videoUrl: nextItem.mediaUrl,
            title: nextItem.titleHe,
            image: nextItem,
            images: widget.images,
            initialIndex: nextIndex,
          ),
        ),
      );
    } else {
      // Navigate to photo view
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PhotoViewScreen(
            imageUrl: nextItem.mediaUrl,
            title: nextItem.titleHe,
            image: nextItem,
            images: widget.images,
            initialIndex: nextIndex,
          ),
        ),
      );
    }
  }

  void _navigateToPrevious() {
    if (widget.images == null || _currentIndex <= 0) return;
    
    final prevIndex = _currentIndex - 1;
    final prevItem = widget.images![prevIndex];
    
    if (prevItem.isVideo) {
      // Navigate to previous video
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => VideoViewScreen(
            videoUrl: prevItem.mediaUrl,
            title: prevItem.titleHe,
            image: prevItem,
            images: widget.images,
            initialIndex: prevIndex,
          ),
        ),
      );
    } else {
      // Navigate to photo view
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PhotoViewScreen(
            imageUrl: prevItem.mediaUrl,
            title: prevItem.titleHe,
            image: prevItem,
            images: widget.images,
            initialIndex: prevIndex,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onEnterFullScreen: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      },
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFFE91E63),
        onReady: () {
          setState(() {
            _isPlayerReady = true;
          });
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black.withOpacity(0.5),
            elevation: 0,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
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
                    const SnackBar(content: Text('שיתוף הסרטון')),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, child) {
                  final favoritesNotifier = ref.watch(favoritesNotifierProvider.notifier);
                  final favoriteStates = ref.watch(favoritesNotifierProvider);
                  final key = 'gallery_${widget.image.id}';
                  final isFavorite = favoriteStates[key] ?? false;
                  
                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_outline, 
                      color: isFavorite ? const Color(0xFFE91E63) : Colors.white,
                    ),
                    onPressed: () async {
                      await favoritesNotifier.toggleFavorite('gallery', widget.image.id);
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
          body: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (widget.images == null || widget.images!.length <= 1) return;
              
              // Swipe right to left (next)
              if (details.primaryVelocity! < -200) {
                _navigateToNext();
              }
              // Swipe left to right (previous)
              else if (details.primaryVelocity! > 200) {
                _navigateToPrevious();
              }
            },
            child: Stack(
              children: [
                Column(
                  children: [
                    // YouTube Player
                    player,
                    
                    // Video details
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Description if available
                              if (widget.image.descriptionHe != null && widget.image.descriptionHe!.isNotEmpty) ...[
                                const Text(
                                  'תיאור',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.image.descriptionHe!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 100), // Space for navigation
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Navigation buttons overlay (only show if there are multiple items)
                if (widget.images != null && widget.images!.length > 1) ...[
                  // Previous button
                  if (_currentIndex > 0)
                    Positioned(
                      left: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _navigateToPrevious,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Next button
                  if (_currentIndex < widget.images!.length - 1)
                    Positioned(
                      right: 16,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: _navigateToNext,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}