import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class AlbumImagesScreen extends StatefulWidget {
  final Map<String, dynamic> album;

  const AlbumImagesScreen({
    super.key,
    required this.album,
  });

  @override
  State<AlbumImagesScreen> createState() => _AlbumImagesScreenState();
}

class _AlbumImagesScreenState extends State<AlbumImagesScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _images = [];
  Set<String> _selectedImageIds = {};
  bool _isLoading = true;
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _supabase
          .from('gallery_images')
          .select('*')
          .eq('album_id', widget.album['id'])
          .eq('is_active', true)
          .order('created_at', ascending: false);


      setState(() {
        _images = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('שגיאה בטעינת התמונות: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('מדיה - ${widget.album['name_he']}'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        actions: [
          if (_isSelectionMode) ...[
            // כפתור מחיקה מרובה
            ElevatedButton.icon(
              onPressed: _selectedImageIds.isEmpty ? null : _showDeleteMultipleDialog,
              icon: const Icon(Icons.delete),
              label: Text('מחק (${_selectedImageIds.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            // כפתור בחר הכל
            TextButton(
              onPressed: _selectAll,
              child: const Text('בחר הכל', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
            // כפתור ביטול
            IconButton(
              onPressed: _exitSelectionMode,
              icon: const Icon(Icons.close),
              tooltip: 'ביטול',
            ),
          ] else ...[
            // כפתור מצב בחירה
            if (_images.isNotEmpty)
              IconButton(
                onPressed: _enterSelectionMode,
                icon: const Icon(Icons.checklist),
                tooltip: 'מחיקה מרובה',
              ),
            const SizedBox(width: 8),
            // Dropdown menu for adding media
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'image':
                    _showAddImageDialog();
                    break;
                  case 'video':
                    _showAddVideoDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'image',
                  child: Row(
                    children: [
                      Icon(Icons.add_photo_alternate, color: Colors.white),
                      SizedBox(width: 8),
                      Text('הוסף תמונות', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'video',
                  child: Row(
                    children: [
                      Icon(Icons.videocam, color: Colors.white),
                      SizedBox(width: 8),
                      Text('הוסף סרטון YouTube', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 8),
                    Text('הוסף מדיה', style: TextStyle(color: Colors.white)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: Colors.white),
                  ],
                ),
              ),
              color: const Color(0xFF2A2A2A),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadImages,
            ),
          ],
        ],
      ),
      backgroundColor: const Color(0xFF0A0A0A),
      body: _buildImagesList(),
    );
  }

  Widget _buildImagesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      );
    }

    if (_images.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'אין פריטים באלבום זה',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white54,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'לחץ על "הוסף מדיה" כדי להתחיל',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: _images.length,
        itemBuilder: (context, index) {
          final image = _images[index];
          return _buildImageCard(image, index);
        },
      ),
    );
  }

  Widget _buildImageCard(Map<String, dynamic> image, int index) {
    final imageId = image['id'];
    final isSelected = _selectedImageIds.contains(imageId);
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Stack(
        children: [
          // תמונה ברקע
          GestureDetector(
            onTap: _isSelectionMode ? () => _toggleImageSelection(imageId) : null,
            child: Container(
              width: double.infinity,
              height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: const Color(0xFF2A2A2A),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  // Display thumbnail/image
                  _isValidImageUrl(image['thumbnail_url'] ?? image['media_url'])
                      ? Image.network(
                          image['thumbnail_url'] ?? image['media_url'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage(image);
                          },
                        )
                      : _buildPlaceholderImage(image),
                  
                  // Video play button overlay
                  if (image['media_type'] == 'video')
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ),
          ),
          
          // checkbox במצב בחירה
          if (_isSelectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleImageSelection(imageId),
                  activeColor: const Color(0xFFE91E63),
                ),
              ),
            ),
          
          // אוברליי תחתון עם כפתורי פעולה
          if (!_isSelectionMode)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // תאריך
                  Text(
                    _formatDate(image['created_at']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                  
                  // כפתורי פעולה
                  Row(
                    children: [
                      // כפתור הגדר כתמונה ראשית
                      InkWell(
                        onTap: () => _setCoverImage(image),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Color(0xFF00BCD4),
                            size: 14,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 6),
                      
                      // כפתור מחיקה
                      InkWell(
                        onTap: () => _showDeleteImageDialog(image),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage([Map<String, dynamic>? item]) {
    final isVideo = item?['media_type'] == 'video';
    return Center(
      child: Icon(
        isVideo ? Icons.videocam : Icons.image,
        color: Colors.white38,
        size: 40,
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url.contains('example.com')) return false;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return false;
    return true;
  }

  void _showAddImageDialog() {
    _showImageDialog();
  }

  // פונקציות מצב בחירה
  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedImageIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedImageIds.clear();
    });
  }

  void _toggleImageSelection(String imageId) {
    setState(() {
      if (_selectedImageIds.contains(imageId)) {
        _selectedImageIds.remove(imageId);
      } else {
        _selectedImageIds.add(imageId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedImageIds = _images.map((img) => img['id'] as String).toSet();
    });
  }

  // פונקציה להגדרת תמונה ראשית
  Future<void> _setCoverImage(Map<String, dynamic> image) async {
    try {
      await _supabase
          .from('gallery_albums')
          .update({
            'cover_image_url': image['media_url'],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.album['id']);

      _showSuccessSnackBar('התמונה הוגדרה כתמונה ראשית של האלבום');
    } catch (e) {
      _showErrorSnackBar('שגיאה בהגדרת התמונה הראשית: $e');
    }
  }

  // מחיקה מרובה
  void _showDeleteMultipleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'מחיקת תמונות',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'האם אתה בטוח שברצונך למחוק ${_selectedImageIds.length} תמונות?\n\nפעולה זו לא ניתנת לביטול.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'ביטול',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteSelectedImages();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedImages() async {
    try {
      // מחיקה מהמאגר
      for (final imageId in _selectedImageIds) {
        await _supabase
            .from('gallery_images')
            .update({'is_active': false})
            .eq('id', imageId);
      }

      _showSuccessSnackBar('${_selectedImageIds.length} תמונות נמחקו בהצלחה');
      _exitSelectionMode();
      _loadImages();
    } catch (e) {
      _showErrorSnackBar('שגיאה במחיקת התמונות: $e');
    }
  }

  void _showImageDialog({Map<String, dynamic>? image}) {
    if (!mounted) return;

    final isEditing = image != null;
    List<Uint8List> selectedImages = [];
    List<String> selectedImageNames = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            isEditing ? 'עריכת תמונה' : 'הוספת תמונות חדשות',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isEditing) ...[
                  // בחירת תמונות (רק בהוספה חדשה)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        allowMultiple: true,
                      );

                      if (result != null) {
                        setState(() {
                          selectedImages = result.files
                              .where((file) => file.bytes != null)
                              .map((file) => file.bytes!)
                              .toList();
                          selectedImageNames = result.files
                              .map((file) => file.name)
                              .toList();
                        });
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text(selectedImages.isEmpty 
                        ? 'בחר תמונות' 
                        : 'נבחרו ${selectedImages.length} תמונות'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // תצוגת התמונות שנבחרו
                  if (selectedImages.isNotEmpty) ...[
                    const Text(
                      'תמונות שנבחרו:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    selectedImages[index],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        selectedImages.removeAt(index);
                                        selectedImageNames.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],

                // הסרנו את שדות הכותרת והתיאור
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text(
                'ביטול',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (isEditing) {
                  // במצב עריכה, פשוט נסגור את הדיאלוג (אין מה לערוך יותר)
                  Navigator.of(context).pop();
                  return;
                } else {
                  if (selectedImages.isEmpty) {
                    _showErrorSnackBar('יש לבחור לפחות תמונה אחת');
                    return;
                  }
                  await _uploadImages(selectedImages);
                }
                
                if (mounted) {
                  Navigator.of(context).pop();
                  _loadImages();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'עדכן' : 'העלה'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImages(List<Uint8List> images) async {
    try {
      final albumName = widget.album['name_he'] ?? 'אלבום';
      
      for (int i = 0; i < images.length; i++) {
        final imageBytes = images[i];
        final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

        // העלאת התמונה לשרת
        await _supabase.storage
            .from('gallery')
            .uploadBinary(fileName, imageBytes);

        // קבלת URL של התמונה
        final imageUrl = _supabase.storage
            .from('gallery')
            .getPublicUrl(fileName);

        // יצירת כותרת אוטומטית
        final autoTitle = images.length == 1 
            ? albumName 
            : '$albumName ${i + 1}';

        // הוספה לבסיס הנתונים
        await _supabase.from('gallery_images').insert({
          'title_he': autoTitle,
          'description_he': null,
          'media_url': imageUrl,
          'thumbnail_url': imageUrl, // נשתמש באותה תמונה לתצוגה מקדימה
          'album_id': widget.album['id'],
          'is_active': true,
          'is_published': true,
          'media_type': 'image',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      _showSuccessSnackBar('${images.length} תמונות הועלו בהצלחה');
    } catch (e) {
      _showErrorSnackBar('שגיאה בהעלאת התמונות: $e');
    }
  }

  void _showAddVideoDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String? thumbnailUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'הוספת סרטון YouTube',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // כותרת
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'כותרת הסרטון',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE91E63)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // URL של YouTube
                TextField(
                  controller: urlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'קישור YouTube',
                    hintText: 'https://www.youtube.com/watch?v=...',
                    hintStyle: TextStyle(color: Colors.white30),
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE91E63)),
                    ),
                  ),
                  onChanged: (value) {
                    // Generate thumbnail automatically
                    final thumbnail = _getYouTubeThumbnail(value);
                    setState(() {
                      thumbnailUrl = thumbnail;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // תיאור
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'תיאור (אופציונלי)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE91E63)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // תצוגת התמונה הזעירה של YouTube
                if (thumbnailUrl != null)
                  Container(
                    width: 120,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[800],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.videocam,
                              color: Colors.white54,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'ביטול',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) {
                  _showErrorSnackBar('יש להזין כותרת לסרטון');
                  return;
                }
                if (urlController.text.trim().isEmpty) {
                  _showErrorSnackBar('יש להזין קישור YouTube');
                  return;
                }
                
                await _uploadVideo(
                  titleController.text.trim(),
                  urlController.text.trim(),
                  descriptionController.text.trim(),
                  thumbnailUrl,
                );
                
                if (mounted) {
                  Navigator.of(context).pop();
                  _loadImages();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
              ),
              child: const Text('הוסף סרטון'),
            ),
          ],
        ),
      ),
    );
  }

  String? _getYouTubeThumbnail(String videoUrl) {
    if (videoUrl.isEmpty) return null;
    
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

  Future<void> _uploadVideo(String title, String videoUrl, String description, String? thumbnailUrl) async {
    try {
      await _supabase.from('gallery_images').insert({
        'title_he': title,
        'description_he': description.isEmpty ? null : description,
        'media_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
        'album_id': widget.album['id'],
        'is_active': true,
        'is_published': true,
        'media_type': 'video',
        'created_at': DateTime.now().toIso8601String(),
      });

      _showSuccessSnackBar('הסרטון נוסף בהצלחה');
    } catch (e) {
      _showErrorSnackBar('שגיאה בהוספת הסרטון: $e');
    }
  }

  void _showDeleteImageDialog(Map<String, dynamic> image) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'מחיקת תמונה',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את התמונה "${image['title_he']}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text(
              'ביטול',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                print('מנסה למחוק תמונה עם ID: ${image['id']}');
                
                final response = await _supabase
                    .from('gallery_images')
                    .delete()
                    .eq('id', image['id'])
                    .select();
                
                print('תשובת המחיקה: $response');

                if (mounted) {
                  Navigator.of(context).pop();
                  _showSuccessSnackBar('התמונה נמחקה בהצלחה');
                  _loadImages();
                }
              } catch (e) {
                print('שגיאה במחיקת תמונה: $e');
                if (mounted) {
                  Navigator.of(context).pop();
                  _showErrorSnackBar('שגיאה במחיקת התמונה: $e');
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}