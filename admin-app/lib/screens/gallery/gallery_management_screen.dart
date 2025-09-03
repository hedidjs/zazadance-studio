import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'album_images_screen.dart';

class GalleryManagementScreen extends StatefulWidget {
  const GalleryManagementScreen({super.key});

  @override
  State<GalleryManagementScreen> createState() => _GalleryManagementScreenState();
}

class _GalleryManagementScreenState extends State<GalleryManagementScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _supabase
          .from('gallery_albums')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _albums = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('שגיאה בטעינת האלבומים: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ניהול גלריה'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        actions: [
          ElevatedButton.icon(
            onPressed: _showAddAlbumDialog,
            icon: const Icon(Icons.add),
            label: const Text('הוסף אלבום חדש'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlbums,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0A0A0A),
      body: _buildAlbumsList(),
    );
  }

  Widget _buildAlbumsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      );
    }

    if (_albums.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_album_outlined,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'אין אלבומים',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white54,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'לחץ על "הוסף אלבום חדש" כדי להתחיל',
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
      padding: const EdgeInsets.all(24.0),
      child: ListView.builder(
        itemCount: _albums.length,
        itemBuilder: (context, index) {
          final album = _albums[index];
          return _buildAlbumCard(album);
        },
      ),
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> album) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1E1E),
      child: InkWell(
        onTap: () => _navigateToAlbumImages(album),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
          children: [
            // תמונה ראשית של האלבום
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF2A2A2A),
              ),
              child: album['cover_image_url'] != null && _isValidImageUrl(album['cover_image_url'])
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        album['cover_image_url'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              color: const Color(0xFFE91E63),
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage();
                        },
                      ),
                    )
                  : _buildPlaceholderImage(),
            ),
            
            const SizedBox(width: 16),
            
            // פרטי האלבום
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album['name_he'] ?? 'ללא שם',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (album['description_he'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      album['description_he'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.white38,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(album['created_at']),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // כפתור עריכה
            IconButton(
              onPressed: () => _showEditAlbumDialog(album),
              icon: const Icon(Icons.edit),
              color: const Color(0xFFE91E63),
              tooltip: 'ערוך אלבום',
            ),
            
            // כפתור מחיקה
            IconButton(
              onPressed: () => _showDeleteAlbumDialog(album),
              icon: const Icon(Icons.delete),
              color: Colors.red,
              tooltip: 'מחק אלבום',
            ),
          ],
          ),
        ),
      ),
    );
  }

  void _navigateToAlbumImages(Map<String, dynamic> album) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlbumImagesScreen(
          album: album,
        ),
      ),
    ).then((_) {
      // רענון הרשימה כשחוזרים מעמוד ניהול התמונות
      _loadAlbums();
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    // בדיקה שהכתובת לא מכילה example.com (נתונים מדמים)
    if (url.contains('example.com')) return false;
    // בדיקה שהכתובת מתחילה ב-http או https
    if (!url.startsWith('http://') && !url.startsWith('https://')) return false;
    return true;
  }

  Widget _buildPlaceholderImage() {
    // רשימה של צבעי רקע שונים לתמונות placeholder
    final colors = [
      const Color(0xFFE91E63), // ורוד פוקציה
      const Color(0xFF9C27B0), // סגול
      const Color(0xFF673AB7), // אינדיגו עמוק
      const Color(0xFF3F51B5), // אינדיגו
      const Color(0xFF00BCD4), // תכלת זוהר
      const Color(0xFF009688), // תכלת
    ];
    
    final random = DateTime.now().millisecondsSinceEpoch % colors.length;
    final backgroundColor = colors[random];
    
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.7),
          ],
        ),
      ),
      child: const Icon(
        Icons.photo_album,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  void _showAddAlbumDialog() {
    _showAlbumDialog();
  }

  void _showEditAlbumDialog(Map<String, dynamic> album) {
    _showAlbumDialog(album: album);
  }

  void _showAlbumDialog({Map<String, dynamic>? album}) {
    if (!mounted) return;
    
    final isEditing = album != null;
    final nameController = TextEditingController(text: album?['name_he'] ?? '');
    final descriptionController = TextEditingController(text: album?['description_he'] ?? '');
    String? selectedImagePath;
    Uint8List? selectedImageBytes;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            isEditing ? 'עריכת אלבום' : 'הוספת אלבום חדש',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // שם האלבום
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'שם האלבום *',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE91E63)),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // תיאור האלבום
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'תיאור האלבום',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE91E63)),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // תמונה ראשית
                const Text(
                  'תמונה ראשית לאלבום:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // תצוגה וכפתור בחירת תמונה
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white38),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: selectedImageBytes != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.memory(
                                selectedImageBytes!,
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    selectedImagePath = null;
                                    selectedImageBytes = null;
                                  });
                                },
                                icon: const Icon(Icons.close),
                                color: Colors.white,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        )
                      : album?['cover_image_url'] != null && _isValidImageUrl(album!['cover_image_url'])
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(
                                album!['cover_image_url'],
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: const Color(0xFFE91E63),
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(7),
                                      color: const Color(0xFF2A2A2A),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          color: Colors.white54,
                                          size: 40,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'שגיאה בטעינת התמונה',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            )
                          : InkWell(
                              onTap: () async {
                                final result = await FilePicker.platform.pickFiles(
                                  type: FileType.image,
                                  allowMultiple: false,
                                );
                                
                                if (result != null && result.files.single.bytes != null) {
                                  setState(() {
                                    selectedImagePath = result.files.single.name;
                                    selectedImageBytes = result.files.single.bytes;
                                  });
                                }
                              },
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    color: Colors.white54,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'לחץ כדי לבחור תמונה',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                ),
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
                if (nameController.text.trim().isEmpty) {
                  _showErrorSnackBar('יש למלא שם אלבום');
                  return;
                }

                try {
                  String? coverImageUrl;
                  
                  // העלאת תמונה אם נבחרה
                  if (selectedImageBytes != null) {
                    final fileName = 'album_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
                    
                    await _supabase.storage
                        .from('gallery')
                        .uploadBinary(fileName, selectedImageBytes!);
                    
                    coverImageUrl = _supabase.storage
                        .from('gallery')
                        .getPublicUrl(fileName);
                  }

                  final data = {
                    'name_he': nameController.text.trim(),
                    'description_he': descriptionController.text.trim().isEmpty 
                        ? null 
                        : descriptionController.text.trim(),
                    if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
                    'updated_at': DateTime.now().toIso8601String(),
                  };

                  if (isEditing) {
                    print('מעדכן אלבום עם ID: ${album['id']}');
                    print('נתונים: $data');
                    
                    final result = await _supabase
                        .from('gallery_albums')
                        .update(data)
                        .eq('id', album['id'])
                        .select(); // להחזיר את הרשומה המעודכנת
                    
                    print('תוצאת עדכון: $result');
                    
                    if (mounted) {
                      _showSuccessSnackBar('האלבום עודכן בהצלחה');
                    }
                  } else {
                    data['created_at'] = DateTime.now().toIso8601String();
                    
                    print('מוסיף אלבום חדש');
                    print('נתונים: $data');
                    
                    final result = await _supabase
                        .from('gallery_albums')
                        .insert(data)
                        .select(); // להחזיר את הרשומה החדשה
                    
                    print('תוצאת הוספה: $result');
                    
                    if (mounted) {
                      _showSuccessSnackBar('אלבום חדש נוסף בהצלחה');
                    }
                  }

                  if (mounted) {
                    Navigator.of(context).pop();
                    _loadAlbums();
                  }
                } catch (e) {
                  if (mounted) {
                    _showErrorSnackBar('שגיאה בשמירת האלבום: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'עדכן' : 'הוסף'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAlbumDialog(Map<String, dynamic> album) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'מחיקת אלבום',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את האלבום "${album['name_he']}"?\n\nשים לב: כל התמונות באלבום זה יימחקו גם כן.',
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
                print('מחיק אלבום עם ID: ${album['id']}');
                
                final result = await _supabase
                    .from('gallery_albums')
                    .delete()
                    .eq('id', album['id'])
                    .select(); // להחזיר את הרשומה שנמחקה
                
                print('תוצאת מחיקה: $result');
                
                if (mounted) {
                  Navigator.of(context).pop();
                  _showSuccessSnackBar('האלבום נמחק בהצלחה');
                  _loadAlbums();
                }
              } catch (e) {
                print('שגיאה במחיקת אלבום: $e');
                if (mounted) {
                  Navigator.of(context).pop();
                  _showErrorSnackBar('שגיאה במחיקת האלבום: $e');
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