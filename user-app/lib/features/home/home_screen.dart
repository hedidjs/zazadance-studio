import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/models/gallery_image.dart';
import '../../providers/theme_provider.dart';
import '../gallery/photo_view_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _recentUpdates = [];
  List<Map<String, dynamic>> _recentTutorials = [];
  List<Map<String, dynamic>> _recentGallery = [];
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _welcomeMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    try {
      // טעינת פרטי המשתמש
      final user = _supabase.auth.currentUser;
      Map<String, dynamic>? userProfile;
      if (user != null) {
        try {
          userProfile = await _supabase
              .from('users')
              .select('full_name, profile_image_url')
              .eq('id', user.id)
              .single();
        } catch (e) {
          // אם אין פרופיל, נשתמש באימייל
          userProfile = {
            'full_name': user.email?.split('@')[0] ?? 'משתמש',
            'profile_image_url': null,
          };
        }
      }

      // טעינת עדכונים אחרונים
      final updatesResponse = await _supabase
          .from('updates')
          .select('id, title_he, content_he, created_at, image_url')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(3);

      // טעינת מדריכים אחרונים  
      final tutorialsResponse = await _supabase
          .from('tutorials')
          .select('id, title_he, description_he, thumbnail_url, video_url')
          .eq('is_active', true)
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(3);

      // טעינת תמונות אחרונות מהגלריה
      final galleryResponse = await _supabase
          .from('gallery_images')
          .select('id, title_he, media_url, thumbnail_url')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(6);

      // טעינת הודעת ברכה
      Map<String, dynamic>? welcomeMessage;
      try {
        final welcomeResponse = await _supabase
            .from('welcome_messages')
            .select('*')
            .eq('is_active', true)
            .order('created_at', ascending: false)
            .limit(1);
        
        if (welcomeResponse.isNotEmpty) {
          welcomeMessage = welcomeResponse.first;
        }
      } catch (e) {
        // Fallback if table doesn't exist yet
        welcomeMessage = {
          'message_he': 'ברוכים הבאים לסטודיו זאזא דאנס',
          'message_en': 'Welcome to ZaZa Dance Studio',
          'background_color': '#2D1B69',
          'text_color': '#FFFFFF',
          'border_radius': 16,
          'has_border': true,
          'border_color': '#E91E63',
          'border_width': 2,
          'padding_horizontal': 20,
          'padding_vertical': 16,
          'margin_horizontal': 16,
          'margin_vertical': 8,
          'font_size': 18,
          'font_weight': 'bold',
          'text_align': 'center',
        };
      }

      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          _recentUpdates = List<Map<String, dynamic>>.from(updatesResponse);
          _recentTutorials = List<Map<String, dynamic>>.from(tutorialsResponse);
          _recentGallery = List<Map<String, dynamic>>.from(galleryResponse);
          _welcomeMessage = welcomeMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת הנתונים: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeProvider);
    
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: themeData.primaryColor,
        ),
      );
    }

    return Container(
      decoration: themeData.getBackgroundDecoration(),
      child: RefreshIndicator(
        color: themeData.primaryColor,
        onRefresh: _loadHomeData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ברכה אישית
              _buildWelcomeSection(),
              
              const SizedBox(height: 24),
              
              // הודעת ברוכים הבאים
              if (_welcomeMessage != null) _buildWelcomeMessageSection(),
              
              if (_welcomeMessage != null) const SizedBox(height: 24),
              
              // עדכונים אחרונים
              _buildUpdatesSection(),
              
              const SizedBox(height: 24),
              
              // מדריכים אחרונים
              _buildTutorialsSection(),
              
              const SizedBox(height: 24),
              
              // גלריה אחרונה
              _buildGallerySection(),
              
              const SizedBox(height: 24),
              
              const SizedBox(height: 100), // מקום לbottom navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final themeData = ref.watch(themeProvider);
    final greeting = _getTimeGreeting();
    final userName = _userProfile?['full_name'] ?? 'משתמש';
    final profileImageUrl = _userProfile?['profile_image_url'];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeData.primaryColor,
            themeData.secondaryColor,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // תמונת פרופיל
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: profileImageUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: profileImageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[400],
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
          ),
          
          const SizedBox(width: 16),
          
          // טקסט ברכה
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting $userName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessageSection() {
    if (_welcomeMessage == null) return const SizedBox.shrink();
    
    final message = _welcomeMessage!;
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: (message['margin_horizontal'] ?? 16).toDouble(),
        vertical: (message['margin_vertical'] ?? 8).toDouble(),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: (message['padding_horizontal'] ?? 20).toDouble(),
        vertical: (message['padding_vertical'] ?? 16).toDouble(),
      ),
      decoration: BoxDecoration(
        color: Color(int.parse(message['background_color']?.replaceFirst('#', '0xFF') ?? '0xFF2D1B69')),
        borderRadius: BorderRadius.circular((message['border_radius'] ?? 16).toDouble()),
        border: message['has_border'] == true
            ? Border.all(
                color: Color(int.parse(message['border_color']?.replaceFirst('#', '0xFF') ?? '0xFFE91E63')),
                width: (message['border_width'] ?? 2).toDouble(),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        message['message_he'] ?? 'ברוכים הבאים לסטודיו זאזא דאנס',
        textAlign: _getTextAlign(message['text_align']),
        style: TextStyle(
          color: Color(int.parse(message['text_color']?.replaceFirst('#', '0xFF') ?? '0xFFFFFFFF')),
          fontSize: (message['font_size'] ?? 18).toDouble(),
          fontWeight: _getFontWeight(message['font_weight']),
        ),
      ),
    );
  }

  TextAlign _getTextAlign(String? alignment) {
    switch (alignment) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
        return TextAlign.center;
      default:
        return TextAlign.center;
    }
  }

  FontWeight _getFontWeight(String? weight) {
    switch (weight) {
      case 'bold':
        return FontWeight.bold;
      case 'normal':
        return FontWeight.normal;
      case 'w500':
        return FontWeight.w500;
      case 'w600':
        return FontWeight.w600;
      case 'w700':
        return FontWeight.w700;
      default:
        return FontWeight.bold;
    }
  }

  Widget _buildUpdatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📢 עדכונים אחרונים',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/updates'),
              child: const Text(
                'צפייה בהכל',
                style: TextStyle(
                  color: Color(0xFF00BCD4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentUpdates.isEmpty)
          const Center(
            child: Text(
              'אין עדכונים חדשים',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Column(
            children: _recentUpdates.map((update) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00BCD4).withOpacity(0.3),
                  ),
                ),
                child: InkWell(
                  onTap: () => context.go('/updates'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        update['title_he'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getExcerpt(update['content_he'] ?? ''),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(update['created_at']),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTutorialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🎥 מדריכים אחרונים',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/tutorials'),
              child: const Text(
                'צפייה בהכל',
                style: TextStyle(
                  color: Color(0xFF00BCD4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentTutorials.isEmpty)
          const Center(
            child: Text(
              'אין מדריכים זמינים',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recentTutorials.length,
              itemBuilder: (context, index) {
                final tutorial = _recentTutorials[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => context.go('/tutorials'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Thumbnail וידאו
                        Container(
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: () {
                                  final thumbnailUrl = tutorial['thumbnail_url'] ?? 
                                      _getYoutubeThumbnail(tutorial['video_url']);
                                  
                                  return thumbnailUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: thumbnailUrl,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: Colors.grey[800],
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: Color(0xFFE91E63),
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: Colors.grey[800],
                                            child: const Center(
                                              child: Icon(
                                                Icons.video_library,
                                                color: Colors.grey,
                                                size: 30,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey[800],
                                          child: const Center(
                                            child: Icon(
                                              Icons.video_library,
                                              color: Colors.grey,
                                              size: 30,
                                            ),
                                          ),
                                        );
                                }(),
                              ),
                              const Center(
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Color(0xFFE91E63),
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // פרטי המדריך
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tutorial['title_he'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tutorial['description_he'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📸 גלריה אחרונה',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/gallery'),
              child: const Text(
                'צפייה בהכל',
                style: TextStyle(
                  color: Color(0xFF00BCD4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentGallery.isEmpty)
          const Center(
            child: Text(
              'אין תמונות זמינות',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _recentGallery.length,
            itemBuilder: (context, index) {
              final image = _recentGallery[index];
              return InkWell(
                onTap: () {
                  // Create GalleryImage object from available data
                  final galleryImage = GalleryImage(
                    id: image['id'] ?? '',
                    createdAt: DateTime.now(), // Placeholder since we don't have this data
                    updatedAt: DateTime.now(), // Placeholder since we don't have this data
                    titleHe: image['title_he'] ?? '',
                    imageUrl: image['media_url'] ?? '',
                    thumbnailUrl: image['thumbnail_url'],
                  );
                  
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PhotoViewScreen(
                        imageUrl: galleryImage.imageUrl,
                        title: galleryImage.titleHe,
                        image: galleryImage,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[800],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (image['thumbnail_url'] ?? image['media_url']) != null
                        ? CachedNetworkImage(
                            imageUrl: image['thumbnail_url'] ?? image['media_url'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFE91E63),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(
                                Icons.image,
                                color: Colors.grey,
                                size: 30,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 30,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return 'בוקר טוב';
    } else if (hour >= 12 && hour < 16) {
      return 'צהריים טובים';
    } else if (hour >= 16 && hour < 20) {
      return 'ערב טוב';
    } else {
      return 'לילה טוב';
    }
  }

  String _getExcerpt(String content) {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  String? _getYoutubeThumbnail(String? videoUrl) {
    if (videoUrl == null) return null;
    
    // Extract YouTube video ID from various URL formats
    final patterns = [
      RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\n?#]+)'),
      RegExp(r'youtube\.com\/v\/([^&\n?#]+)'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(videoUrl);
      if (match != null) {
        final videoId = match.group(1);
        return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
      }
    }
    
    return null;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'היום';
      } else if (difference.inDays == 1) {
        return 'אתמול';
      } else if (difference.inDays < 7) {
        return 'לפני ${difference.inDays} ימים';
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
    }
  }
}