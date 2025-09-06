import 'base_model.dart';

/// Gallery image model
class GalleryImage extends BaseModel {
  final String titleHe;
  final String? titleEn;
  final String? descriptionHe;
  final String? descriptionEn;
  final String imageUrl;
  final String? thumbnailUrl;
  final String? category;
  final bool isActive;

  const GalleryImage({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.titleHe,
    this.titleEn,
    this.descriptionHe,
    this.descriptionEn,
    required this.imageUrl,
    this.thumbnailUrl,
    this.category,
    this.isActive = true,
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
      imageUrl: json['image_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      category: json['category'],
      isActive: json['is_active'] ?? true,
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
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'category': category,
      'is_active': isActive,
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
    String? imageUrl,
    String? thumbnailUrl,
    String? category,
    bool? isActive,
  }) {
    return GalleryImage(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      titleHe: titleHe ?? this.titleHe,
      titleEn: titleEn ?? this.titleEn,
      descriptionHe: descriptionHe ?? this.descriptionHe,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
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

  /// Get the appropriate image URL (thumbnail if available, otherwise full image)
  String getDisplayImageUrl({bool preferThumbnail = true}) {
    if (preferThumbnail && thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return thumbnailUrl!;
    }
    return imageUrl;
  }

  /// Check if this image has a thumbnail
  bool get hasThumbnail => thumbnailUrl != null && thumbnailUrl!.isNotEmpty;

  /// Get formatted category name
  String get displayCategory => category ?? 'כללי';
}