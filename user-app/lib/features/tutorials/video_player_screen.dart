import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> tutorial;

  const VideoPlayerScreen({
    super.key,
    required this.tutorial,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  final _supabase = Supabase.instance.client;
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  bool _isLiked = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _incrementViewCount();
    _loadFavoriteStatus();
    _loadLikeStatus();
  }

  void _initializePlayer() {
    final videoUrl = widget.tutorial['video_url'] as String?;
    if (videoUrl == null) return;

    // חילוץ video ID מ-URL של YouTube
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
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

  Future<void> _incrementViewCount() async {
    try {
      final currentViews = widget.tutorial['views_count'] ?? 0;
      await _supabase
          .from('tutorials')
          .update({'views_count': currentViews + 1})
          .eq('id', widget.tutorial['id']);
    } catch (e) {
      // שגיאה בעדכון הצפיות - לא חשובה מספיק להציג למשתמש
      debugPrint('Error updating view count: $e');
    }
  }

  Future<void> _loadFavoriteStatus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('user_favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('content_type', 'tutorial')
          .eq('content_id', widget.tutorial['id'])
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isSaved = response != null;
        });
      }
    } catch (e) {
      debugPrint('Error loading favorite status: $e');
    }
  }

  Future<void> _loadLikeStatus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('user_likes')
          .select('id')
          .eq('user_id', user.id)
          .eq('content_type', 'tutorial')
          .eq('content_id', widget.tutorial['id'])
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isLiked = response != null;
        });
      }
    } catch (e) {
      debugPrint('Error loading like status: $e');
    }
  }

  Future<void> _toggleLike() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להיכנס כדי לסמן לייק'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (_isLiked) {
        // Remove like
        await _supabase
            .from('user_likes')
            .delete()
            .eq('user_id', user.id)
            .eq('content_type', 'tutorial')
            .eq('content_id', widget.tutorial['id']);

        // Update likes count
        final currentLikes = widget.tutorial['likes_count'] ?? 0;
        await _supabase
            .from('tutorials')
            .update({'likes_count': (currentLikes - 1).clamp(0, double.infinity).toInt()})
            .eq('id', widget.tutorial['id']);
      } else {
        // Add like
        await _supabase.from('user_likes').insert({
          'user_id': user.id,
          'content_type': 'tutorial',
          'content_id': widget.tutorial['id'],
        });

        // Update likes count
        final currentLikes = widget.tutorial['likes_count'] ?? 0;
        await _supabase
            .from('tutorials')
            .update({'likes_count': currentLikes + 1})
            .eq('id', widget.tutorial['id']);
      }

      setState(() {
        _isLiked = !_isLiked;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLiked ? 'לייק נוסף' : 'לייק הוסר'),
            backgroundColor: _isLiked ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בעדכון לייק: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleSave() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('יש להיכנס כדי לשמור מדריכים למועדפים'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (_isSaved) {
        // הסר ממועדפים
        await _supabase
            .from('user_favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('content_type', 'tutorial')
            .eq('content_id', widget.tutorial['id']);
      } else {
        // הוסף למועדפים
        await _supabase.from('user_favorites').insert({
          'user_id': user.id,
          'content_type': 'tutorial',
          'content_id': widget.tutorial['id'],
        });
      }

      setState(() {
        _isSaved = !_isSaved;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSaved ? 'המדריך נשמר למועדפים' : 'המדריך הוסר מהמועדפים'),
            backgroundColor: _isSaved ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת המדריך: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareVideo() async {
    try {
      final title = widget.tutorial['title_he'] ?? 'מדריך ריקוד';
      final videoUrl = widget.tutorial['video_url'] ?? '';
      final description = widget.tutorial['description_he'] ?? '';
      
      final shareText = '$title\n\n$description\n\nצפו במדריך: $videoUrl\n\nמסטודיו שרון לריקוד';
      
      await Share.share(
        shareText,
        subject: title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשיתוף המדריך: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        onEnded: (metaData) {
          // TODO: הצע וידאו הבא או חזרה לרשימה
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              // שיתוף
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _shareVideo,
              ),
            ],
          ),
          body: Column(
            children: [
              // נגן הוידאו
              player,
              
              // פרטי הוידאו ופעולות
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      
                      // כותרת המדריך ופעולות
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // כותרת
                            Text(
                              widget.tutorial['title_he'] ?? 'ללא כותרת',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // נתונים סטטיסטיים
                            Row(
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${(widget.tutorial['views_count'] ?? 0) + 1} צפיות',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.favorite,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.tutorial['likes_count'] ?? 0} לייקים',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // כפתורי פעולה
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                // לייק
                                _buildActionButton(
                                  icon: _isLiked ? Icons.favorite : Icons.favorite_outline,
                                  label: 'לייק',
                                  color: _isLiked ? const Color(0xFFE91E63) : Colors.white70,
                                  onTap: _toggleLike,
                                ),
                                
                                // שמירה
                                _buildActionButton(
                                  icon: _isSaved ? Icons.bookmark : Icons.bookmark_outline,
                                  label: 'שמור',
                                  color: _isSaved ? const Color(0xFF00BCD4) : Colors.white70,
                                  onTap: _toggleSave,
                                ),
                                
                                // שיתוף
                                _buildActionButton(
                                  icon: Icons.share,
                                  label: 'שתף',
                                  color: Colors.white70,
                                  onTap: _shareVideo,
                                ),
                                
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 16),
                      
                      // תיאור המדריך
                      if (widget.tutorial['description_he'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                widget.tutorial['description_he'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // קטגוריה ותגיות
                      if (widget.tutorial['tutorial_categories'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'קטגוריה',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _parseColor(
                                    widget.tutorial['tutorial_categories']['color'],
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _parseColor(
                                      widget.tutorial['tutorial_categories']['color'],
                                    ).withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  widget.tutorial['tutorial_categories']['name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _parseColor(
                                      widget.tutorial['tutorial_categories']['color'],
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 100), // רווח לnavigation תחתון
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null) return const Color(0xFF00BCD4);
    
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF00BCD4);
    }
  }
}