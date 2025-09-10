import '../models/gallery_image.dart';
import '../models/gallery_album.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/pagination_result.dart';
import '../exceptions/app_exceptions.dart';

/// Result class for gallery operations
class GalleryOperationResult {
  final bool success;
  final String? errorMessage;
  final GalleryImage? image;
  final PaginationResult<GalleryImage>? images;
  final List<GalleryAlbum>? albums;

  const GalleryOperationResult({
    required this.success,
    this.errorMessage,
    this.image,
    this.images,
    this.albums,
  });

  factory GalleryOperationResult.success({
    GalleryImage? image,
    PaginationResult<GalleryImage>? images,
    List<GalleryAlbum>? albums,
  }) {
    return GalleryOperationResult(
      success: true,
      image: image,
      images: images,
      albums: albums,
    );
  }

  factory GalleryOperationResult.failure(String errorMessage) {
    return GalleryOperationResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// Abstract interface for gallery data access
abstract class GalleryRepository {
  Future<GalleryOperationResult> getGalleryImages({
    int page = 1,
    int pageSize = 20,
    String? searchQuery,
    String? category,
  });
  
  Future<GalleryOperationResult> getGalleryImage(String imageId);
  Future<GalleryOperationResult> uploadGalleryImage(GalleryImage image);
  Future<GalleryOperationResult> uploadGalleryVideo(GalleryImage video);
  Future<GalleryOperationResult> updateGalleryImage(String imageId, GalleryImage updatedImage);
  Future<GalleryOperationResult> deleteGalleryImage(String imageId);
  Future<int> getTotalGalleryImagesCount({String? category});
  
  // Album methods
  Future<GalleryOperationResult> getGalleryAlbums();
}

/// Supabase implementation of GalleryRepository with pagination
class SupabaseGalleryRepository implements GalleryRepository {
  static const String _tableName = 'gallery_images';
  static const String _albumsTableName = 'gallery_albums';

  @override
  Future<GalleryOperationResult> getGalleryImages({
    int page = 1,
    int pageSize = 20,
    String? searchQuery,
    String? category,
  }) async {
    try {
      final pagination = PaginationParams(page: page, pageSize: pageSize);
      
      // Build query with filters
      var query = Supabase.instance.client
          .from(_tableName)
          .select('id, title_he, title_en, description_he, description_en, media_url, thumbnail_url, album_id, is_active, media_type, created_at, updated_at');

      // Apply filters
      if (category != null && category.isNotEmpty) {
        query = query.eq('album_id', category);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.or('title_he.ilike.%$searchQuery%,title_en.ilike.%$searchQuery%');
      }

      // Only show active images
      query = query.eq('is_active', true);

      // Get total count for the specific category
      int totalCount = 0;
      try {
        var countQuery = Supabase.instance.client
            .from(_tableName)
            .select('id')
            .eq('is_active', true);
        
        // Apply category filter if provided
        if (category != null && category.isNotEmpty) {
          countQuery = countQuery.eq('album_id', category);
        }
        
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          countQuery = countQuery.or('title_he.ilike.%$searchQuery%,title_en.ilike.%$searchQuery%');
        }
        
        final countResponse = await countQuery;
        totalCount = countResponse.length;
      } catch (e) {
        totalCount = 0;
      }
      

      // Apply pagination and ordering
      final response = await query
          .range(pagination.offset, pagination.offset + pagination.pageSize - 1)
          .order('created_at', ascending: false);

      final images = response
          .map<GalleryImage>((imageData) => GalleryImage.fromJson(imageData))
          .toList();

      final paginationResult = PaginationResult<GalleryImage>(
        items: images,
        totalCount: totalCount,
        currentPage: page,
        pageSize: pageSize,
      );

      return GalleryOperationResult.success(images: paginationResult);
    } catch (e) {
      return GalleryOperationResult.failure('Failed to load gallery images: ${e.toString()}');
    }
  }

  @override
  Future<GalleryOperationResult> getGalleryImage(String imageId) async {
    try {
      final response = await Supabase.instance.client
          .from(_tableName)
          .select('*')
          .eq('id', imageId)
          .single();

      final image = GalleryImage.fromJson(response);
      return GalleryOperationResult.success(image: image);
    } catch (e) {
      return GalleryOperationResult.failure('Failed to load gallery image: ${e.toString()}');
    }
  }

  @override
  Future<GalleryOperationResult> uploadGalleryImage(GalleryImage image) async {
    try {
      final response = await Supabase.instance.client
          .from(_tableName)
          .insert(image.toJson())
          .select()
          .single();

      final uploadedImage = GalleryImage.fromJson(response);
      return GalleryOperationResult.success(image: uploadedImage);
    } catch (e) {
      return GalleryOperationResult.failure('Failed to upload gallery image: ${e.toString()}');
    }
  }

  @override
  Future<GalleryOperationResult> uploadGalleryVideo(GalleryImage video) async {
    try {
      // Generate YouTube thumbnail if not provided
      final videoWithThumbnail = video.thumbnailUrl == null || video.thumbnailUrl!.isEmpty
          ? video.copyWith(thumbnailUrl: video.getYouTubeThumbnail())
          : video;

      final response = await Supabase.instance.client
          .from(_tableName)
          .insert(videoWithThumbnail.toJson())
          .select()
          .single();

      final uploadedVideo = GalleryImage.fromJson(response);
      return GalleryOperationResult.success(image: uploadedVideo);
    } catch (e) {
      return GalleryOperationResult.failure('Failed to upload gallery video: ${e.toString()}');
    }
  }

  @override
  Future<GalleryOperationResult> updateGalleryImage(String imageId, GalleryImage updatedImage) async {
    try {
      final response = await Supabase.instance.client
          .from(_tableName)
          .update({
            ...updatedImage.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', imageId)
          .select()
          .single();

      final image = GalleryImage.fromJson(response);
      return GalleryOperationResult.success(image: image);
    } catch (e) {
      return GalleryOperationResult.failure('Failed to update gallery image: ${e.toString()}');
    }
  }

  @override
  Future<GalleryOperationResult> deleteGalleryImage(String imageId) async {
    try {
      await Supabase.instance.client
          .from(_tableName)
          .delete()
          .eq('id', imageId);

      return GalleryOperationResult.success();
    } catch (e) {
      return GalleryOperationResult.failure('Failed to delete gallery image: ${e.toString()}');
    }
  }

  @override
  Future<int> getTotalGalleryImagesCount({String? category}) async {
    try {
      var query = Supabase.instance.client
          .from(_tableName)
          .select('*')
          .eq('is_active', true);

      if (category != null && category.isNotEmpty) {
        query = query.eq('album_id', category);
      }

      final response = await query;
      return response.length;
    } catch (e) {
      throw DatabaseException('Failed to get gallery images count: ${e.toString()}');
    }
  }

  /// Get gallery categories for filtering (backward compatibility method)
  Future<List<Map<String, String>>> getGalleryCategories() async {
    return await getGalleryAlbumsForFiltering();
  }

  /// Get gallery albums for filtering
  Future<List<Map<String, String>>> getGalleryAlbumsForFiltering() async {
    try {
      // Get unique album IDs from gallery_images
      final usedAlbumsResponse = await Supabase.instance.client
          .from(_tableName)
          .select('album_id')
          .eq('is_active', true)
          .not('album_id', 'is', null);

      if (usedAlbumsResponse.isEmpty) return [];

      final albumIds = usedAlbumsResponse
          .map<String>((row) => row['album_id'] as String)
          .toSet()
          .toList();

      // Get album names from gallery_albums table
      final albumsResponse = await Supabase.instance.client
          .from('gallery_albums')
          .select('id, name_he')
          .inFilter('id', albumIds)
          .eq('is_active', true);

      final albums = albumsResponse
          .map<Map<String, String>>((row) => {
            'id': row['id'] as String,
            'name': row['name_he'] as String,
          })
          .toList();
      
      // Sort by name
      albums.sort((a, b) => a['name']!.compareTo(b['name']!));
      return albums;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<GalleryOperationResult> getGalleryAlbums() async {
    try {
      // Get albums with image counts using manual query
      final albumsResponse = await Supabase.instance.client
          .from(_albumsTableName)
          .select('id, name_he, description_he, created_at, updated_at, is_active, cover_image_url')
          .eq('is_active', true)
          .order('name_he');

      final albums = <GalleryAlbum>[];
      for (final albumData in albumsResponse) {
        // Count images for this album
        final imageCountResponse = await Supabase.instance.client
            .from(_tableName)
            .select('id')
            .eq('album_id', albumData['id'])
            .eq('media_type', 'image')
            .eq('is_active', true);

        // Count videos for this album
        final videoCountResponse = await Supabase.instance.client
            .from(_tableName)
            .select('id')
            .eq('album_id', albumData['id'])
            .eq('media_type', 'video')
            .eq('is_active', true);

        final album = GalleryAlbum(
          id: albumData['id'],
          createdAt: DateTime.parse(albumData['created_at']),
          updatedAt: DateTime.parse(albumData['updated_at'] ?? albumData['created_at']),
          name: albumData['name_he'] ?? '',
          description: albumData['description_he'],
          color: '#E91E63', // Default color since gallery_albums table doesn't have color column
          imageCount: imageCountResponse.length,
          videoCount: videoCountResponse.length,
          isActive: albumData['is_active'] ?? true,
        );
        albums.add(album);
      }

      return GalleryOperationResult.success(albums: albums);
    } catch (e) {
      return GalleryOperationResult.failure('Failed to load gallery albums: ${e.toString()}');
    }
  }
}