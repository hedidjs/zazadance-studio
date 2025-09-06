import 'base_model.dart';

class AppConfig extends BaseModel {
  final String appName;
  final String logoUrl;
  final String primaryColor;
  final String secondaryColor;
  final Map<String, dynamic> socialMedia;
  final Map<String, dynamic> contactInfo;
  final Map<String, dynamic> businessHours;
  final bool isActive;

  const AppConfig({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.appName,
    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.socialMedia,
    required this.contactInfo,
    required this.businessHours,
    this.isActive = true,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at']),
      appName: json['app_name'] ?? 'ZaZa Dance',
      logoUrl: json['logo_url'] ?? '',
      primaryColor: json['primary_color'] ?? '#E91E63',
      secondaryColor: json['secondary_color'] ?? '#00BCD4',
      socialMedia: json['social_media'] ?? {},
      contactInfo: json['contact_info'] ?? {},
      businessHours: json['business_hours'] ?? {},
      isActive: json['is_active'] ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'app_name': appName,
      'logo_url': logoUrl,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'social_media': socialMedia,
      'contact_info': contactInfo,
      'business_hours': businessHours,
      'is_active': isActive,
    };
  }

  /// Create a copy of this AppConfig with modified fields
  AppConfig copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? appName,
    String? logoUrl,
    String? primaryColor,
    String? secondaryColor,
    Map<String, dynamic>? socialMedia,
    Map<String, dynamic>? contactInfo,
    Map<String, dynamic>? businessHours,
    bool? isActive,
  }) {
    return AppConfig(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      appName: appName ?? this.appName,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      socialMedia: socialMedia ?? this.socialMedia,
      contactInfo: contactInfo ?? this.contactInfo,
      businessHours: businessHours ?? this.businessHours,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Default app configuration
  factory AppConfig.defaultConfig() {
    final now = BaseModel.now();
    return AppConfig(
      id: BaseModel.generateId(),
      createdAt: now,
      updatedAt: now,
      appName: 'ZaZa Dance',
      logoUrl: '',
      primaryColor: '#E91E63',
      secondaryColor: '#00BCD4',
      socialMedia: {},
      contactInfo: {},
      businessHours: {},
      isActive: true,
    );
  }

  /// Get Instagram URL if available
  String? get instagramUrl => socialMedia['instagram'];

  /// Get Facebook URL if available
  String? get facebookUrl => socialMedia['facebook'];

  /// Get WhatsApp number if available
  String? get whatsappNumber => contactInfo['whatsapp'];

  /// Get phone number if available
  String? get phoneNumber => contactInfo['phone'];

  /// Get email if available
  String? get email => contactInfo['email'];
}