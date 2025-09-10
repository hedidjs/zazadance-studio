import 'base_model.dart';

/// Gallery album model (based on gallery_categories table)
class GalleryAlbum extends BaseModel {
  final String name;
  final String? description;
  final String color;
  final int imageCount;
  final int videoCount;
  final bool isActive;

  const GalleryAlbum({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.name,
    this.description,
    required this.color,
    required this.imageCount,
    this.videoCount = 0,
    this.isActive = true,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory GalleryAlbum.fromJson(Map<String, dynamic> json) {
    return GalleryAlbum(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at']),
      name: json['name'] ?? '',
      description: json['description'],
      color: json['color'] ?? '#E91E63',
      imageCount: json['image_count'] ?? 0,
      videoCount: json['video_count'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'name': name,
      'description': description,
      'color': color,
      'image_count': imageCount,
      'video_count': videoCount,
      'is_active': isActive,
    };
  }

  /// Create a copy of this GalleryAlbum with modified fields
  GalleryAlbum copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? description,
    String? color,
    int? imageCount,
    int? videoCount,
    bool? isActive,
  }) {
    return GalleryAlbum(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      imageCount: imageCount ?? this.imageCount,
      videoCount: videoCount ?? this.videoCount,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get the color as a Flutter Color object
  int get colorValue {
    String hexString = color.replaceFirst('#', '');
    return int.parse('FF$hexString', radix: 16);
  }

  /// Get display description with fallback
  String get displayDescription => description ?? 'אלבום תמונות';

  /// Get total count of items (images + videos)
  int get totalCount => imageCount + videoCount;

  /// Get formatted count display
  String get formattedItemCount {
    if (imageCount == 0 && videoCount == 0) {
      return 'ריק';
    }
    
    final parts = <String>[];
    if (imageCount > 0) {
      parts.add('$imageCount תמונות');
    }
    if (videoCount > 0) {
      parts.add('$videoCount סרטונים');
    }
    
    return parts.join(', ');
  }
}