import '../models/gallery_image.dart';
import '../services/supabase_service.dart';
import '../utils/pagination_result.dart';
import '../exceptions/app_exceptions.dart';

/// Result class for gallery operations
class GalleryOperationResult {
  final bool success;
  final String? errorMessage;
  final GalleryImage? image;
  final PaginationResult<GalleryImage>? images;

  const GalleryOperationResult({
    required this.success,
    this.errorMessage,
    this.image,
    this.images,
  });

  factory GalleryOperationResult.success({
    GalleryImage? image,
    PaginationResult<GalleryImage>? images,
  }) {
    return GalleryOperationResult(
      success: true,
      image: image,
      images: images,
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
  Future<GalleryOperationResult> updateGalleryImage(String imageId, GalleryImage updatedImage);
  Future<GalleryOperationResult> deleteGalleryImage(String imageId);
  Future<int> getTotalGalleryImagesCount({String? category});
}

/// Supabase implementation of GalleryRepository with pagination
class SupabaseGalleryRepository implements GalleryRepository {
  static const String _tableName = 'gallery_images';

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
      var query = SupabaseService.client
          .from(_tableName)
          .select('id, title_he, title_en, description_he, description_en, image_url, thumbnail_url, category, is_active, created_at, updated_at');

      // Apply filters
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        query = query.or('title_he.ilike.%$searchQuery%,title_en.ilike.%$searchQuery%');
      }

      // Only show active images
      query = query.eq('is_active', true);

      // Get total count for pagination
      final countQuery = SupabaseService.client
          .from(_tableName)
          .select('id', const FetchOptions(count: CountOption.exact));
      
      if (category != null && category.isNotEmpty) {
        countQuery.eq('category', category);
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        countQuery.or('title_he.ilike.%$searchQuery%,title_en.ilike.%$searchQuery%');
      }
      countQuery.eq('is_active', true);

      final countResponse = await countQuery;
      final totalCount = countResponse.count ?? 0;

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
      final response = await SupabaseService.client
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
      final response = await SupabaseService.client
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
  Future<GalleryOperationResult> updateGalleryImage(String imageId, GalleryImage updatedImage) async {
    try {
      final response = await SupabaseService.client
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
      await SupabaseService.client
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
      var query = SupabaseService.client
          .from(_tableName)
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('is_active', true);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final response = await query;
      return response.count ?? 0;
    } catch (e) {
      throw DatabaseException('Failed to get gallery images count: ${e.toString()}');
    }
  }

  /// Get gallery categories for filtering
  Future<List<String>> getGalleryCategories() async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select('category')
          .eq('is_active', true)
          .not('category', 'is', null);

      final categories = response
          .map<String>((row) => row['category'] as String)
          .toSet()
          .toList();
      
      categories.sort();
      return categories;
    } catch (e) {
      return [];
    }
  }
}