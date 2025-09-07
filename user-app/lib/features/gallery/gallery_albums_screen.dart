import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_core/repositories/gallery_repository.dart';
import 'package:shared_core/models/gallery_album.dart';
import 'album_detail_screen.dart';
import '../favorites/favorites_service.dart';

class GalleryAlbumsScreen extends ConsumerStatefulWidget {
  const GalleryAlbumsScreen({super.key});

  @override
  ConsumerState<GalleryAlbumsScreen> createState() => _GalleryAlbumsScreenState();
}

class _GalleryAlbumsScreenState extends ConsumerState<GalleryAlbumsScreen> {
  final _galleryRepository = SupabaseGalleryRepository();
  
  List<GalleryAlbum> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await _galleryRepository.getGalleryAlbums();

      if (mounted) {
        if (result.success && result.albums != null) {
          setState(() {
            _albums = result.albums!;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('שגיאה בטעינת האלבומים: ${result.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת האלבומים: $e')),
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
              onRefresh: _loadAlbums,
              child: _albums.isEmpty
                  ? _buildEmptyState()
                  : _buildAlbumsList(),
            ),
    );
  }

  Widget _buildEmptyState() {
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
          SizedBox(height: 8),
          Text(
            'אלבומים חדשים יתווספו בקרוב',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return _buildAlbumCard(album);
      },
    );
  }

  Widget _buildAlbumCard(GalleryAlbum album) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AlbumDetailScreen(
                  album: album,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Album color indicator
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(album.colorValue),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                // Album info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        album.displayDescription,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.photo,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${album.imageCount} תמונות',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Favorite star
                Consumer(
                  builder: (context, ref, child) {
                    final favoritesNotifier = ref.watch(favoritesNotifierProvider.notifier);
                    final isFavorite = ref.watch(favoritesNotifierProvider)['album_${album.id}'] ?? false;
                    
                    return IconButton(
                      onPressed: () {
                        favoritesNotifier.toggleFavorite('album', album.id);
                      },
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite ? Colors.amber : Colors.grey[400],
                        size: 24,
                      ),
                    );
                  },
                ),
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}