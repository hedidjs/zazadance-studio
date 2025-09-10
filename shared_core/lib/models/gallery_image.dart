import 'base_model.dart';

/// Gallery item model (supports both images and videos)
class GalleryImage extends BaseModel {
  final String titleHe;
  final String? titleEn;
  final String? descriptionHe;
  final String? descriptionEn;
  final String mediaUrl; // Can be image URL or YouTube video URL
  final String? thumbnailUrl;
  final String? albumId;
  final bool isActive;
  final String mediaType; // 'image' or 'video'

  const GalleryImage({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.titleHe,
    this.titleEn,
    this.descriptionHe,
    this.descriptionEn,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.albumId,
    this.isActive = true,
    this.mediaType = 'image',
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory GalleryImage.fromJson(Map<String, dynamic> json) {
    return GalleryImage(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at']),
      titleHe: json['title_he'] ?? '',
      titleEn: json['title_en'],
      descriptionHe: json['description_he'],
      descriptionEn: json['description_en'],
      mediaUrl: json['media_url'] ?? json['image_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      albumId: json['album_id'] ?? json['category_id'] ?? json['category'],
      isActive: json['is_active'] ?? true,
      mediaType: json['media_type'] ?? 'image',
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'title_he': titleHe,
      'title_en': titleEn,
      'description_he': descriptionHe,
      'description_en': descriptionEn,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'album_id': albumId,
      'is_active': isActive,
      'media_type': mediaType,
    };
  }

  /// Create a copy of this GalleryImage with modified fields
  GalleryImage copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? titleHe,
    String? titleEn,
    String? descriptionHe,
    String? descriptionEn,
    String? mediaUrl,
    String? thumbnailUrl,
    String? albumId,
    bool? isActive,
    String? mediaType,
  }) {
    return GalleryImage(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      titleHe: titleHe ?? this.titleHe,
      titleEn: titleEn ?? this.titleEn,
      descriptionHe: descriptionHe ?? this.descriptionHe,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      albumId: albumId ?? this.albumId,
      isActive: isActive ?? this.isActive,
      mediaType: mediaType ?? this.mediaType,
    );
  }

  /// Get display title based on language preference
  String getDisplayTitle({bool preferEnglish = false}) {
    if (preferEnglish && titleEn != null && titleEn!.isNotEmpty) {
      return titleEn!;
    }
    return titleHe;
  }

  /// Get display description based on language preference
  String? getDisplayDescription({bool preferEnglish = false}) {
    if (preferEnglish && descriptionEn != null && descriptionEn!.isNotEmpty) {
      return descriptionEn;
    }
    return descriptionHe;
  }

  /// Get the appropriate display URL (for images: thumbnail if available, for videos: YouTube thumbnail)
  String getDisplayImageUrl({bool preferThumbnail = true}) {
    if (mediaType == 'video') {
      // For YouTube videos, generate thumbnail URL if not provided
      if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
        return thumbnailUrl!;
      }
      return getYouTubeThumbnail() ?? mediaUrl;
    }
    
    if (preferThumbnail && thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return thumbnailUrl!;
    }
    return mediaUrl;
  }

  /// Check if this item has a thumbnail
  bool get hasThumbnail => thumbnailUrl != null && thumbnailUrl!.isNotEmpty;

  /// Check if this is a video item
  bool get isVideo => mediaType == 'video';

  /// Check if this is an image item
  bool get isImage => mediaType == 'image';

  /// Get YouTube thumbnail URL from video URL
  String? getYouTubeThumbnail() {
    if (!isVideo) return null;
    
    // Extract YouTube video ID from various URL formats
    final patterns = [
      RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\n?#]+)'),
      RegExp(r'youtube\.com\/v\/([^&\n?#]+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(mediaUrl);
      if (match != null) {
        final videoId = match.group(1);
        return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
      }
    }
    return null;
  }

  /// Get formatted album ID
  String get displayAlbumId => albumId ?? 'כללי';

  /// For backward compatibility - get image URL
  String get imageUrl => mediaUrl;
}