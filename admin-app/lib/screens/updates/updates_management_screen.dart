import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

class UpdatesManagementScreen extends StatefulWidget {
  const UpdatesManagementScreen({super.key});

  @override
  State<UpdatesManagementScreen> createState() => _UpdatesManagementScreenState();
}

class _UpdatesManagementScreenState extends State<UpdatesManagementScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _updates = [];
  List<Map<String, dynamic>> _updateTypes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUpdates();
    _loadUpdateTypes();
  }

  Future<void> _loadUpdates() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _supabase
          .from('updates')
          .select('*, update_types(name_he, color)')
          .order('created_at', ascending: false);

      setState(() {
        _updates = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('שגיאה בטעינת עדכונים: $e');
    }
  }

  Future<void> _loadUpdateTypes() async {
    try {
      final response = await _supabase
          .from('update_types')
          .select('*')
          .eq('is_active', true)
          .order('name_he');

      setState(() {
        _updateTypes = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _showErrorSnackBar('שגיאה בטעינת סוגי עדכונים: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'ניהול עדכונים',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE91E63)),
            )
          : _updates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.article, size: 64, color: Colors.white38),
                      const SizedBox(height: 16),
                      const Text(
                        'אין עדכונים עדיין',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddUpdateDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('הוסף עדכון ראשון'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _updates.length,
                  itemBuilder: (context, index) {
                    final update = _updates[index];
                    return _buildUpdateCard(update);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUpdateDialog,
        backgroundColor: const Color(0xFFE91E63),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildUpdateCard(Map<String, dynamic> update) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (update['update_types'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _parseColor(update['update_types']['color']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      update['update_types']['name_he'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: _parseColor(update['update_types']['color']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: update['is_active'] ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    update['is_active'] ? 'פעיל' : 'לא פעיל',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              update['title_he'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (update['author_name'] != null && update['author_name'].toString().isNotEmpty)
              Text(
                'מחבר: ${update['author_name']}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            const SizedBox(height: 8),
            if (update['image_url'] != null && update['image_url'].toString().isNotEmpty)
              Container(
                height: 120,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    update['image_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey,
                      child: const Icon(Icons.image, color: Colors.white),
                    ),
                  ),
                ),
              ),
            Text(
              update['content_he'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'צפיות: ${update['views_count'] ?? 0}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  'לייקים: ${update['likes_count'] ?? 0}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  _formatDate(update['created_at']),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditUpdateDialog(update),
                  icon: const Icon(Icons.edit, color: Color(0xFFE91E63), size: 16),
                  label: const Text('עריכה', style: TextStyle(color: Color(0xFFE91E63))),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showDeleteUpdateDialog(update),
                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                  label: const Text('מחיקה', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUpdateDialog() {
    _showUpdateDialog();
  }

  void _showEditUpdateDialog(Map<String, dynamic> update) {
    _showUpdateDialog(update: update);
  }

  void _showUpdateDialog({Map<String, dynamic>? update}) {
    final isEditing = update != null;
    final titleController = TextEditingController(text: update?['title_he'] ?? '');
    final contentController = TextEditingController(text: update?['content_he'] ?? '');
    final authorController = TextEditingController(text: update?['author_name'] ?? '');
    final imageUrlController = TextEditingController(text: update?['image_url'] ?? '');
    String? selectedUpdateTypeId = update?['update_type_id'];
    bool isActive = update?['is_active'] ?? true;
    Uint8List? selectedImageBytes;
    String? selectedImageName;
    bool isUploadingImage = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            isEditing ? 'עריכת עדכון' : 'הוספת עדכון חדש',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'כותרת העדכון',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE91E63)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'תוכן העדכון',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE91E63)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: authorController,
                    decoration: const InputDecoration(
                      labelText: 'שם מחבר (אופציונלי)',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE91E63)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedUpdateTypeId,
                    decoration: const InputDecoration(
                      labelText: 'סוג עדכון',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE91E63)),
                      ),
                    ),
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    items: _updateTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['id'],
                        child: Text(type['name_he']),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedUpdateTypeId = value),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'תמונה',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final result = await FilePicker.platform.pickFiles(
                                    type: FileType.image,
                                    allowMultiple: false,
                                  );
                                  
                                  if (result != null && result.files.isNotEmpty) {
                                    final file = result.files.first;
                                    setState(() {
                                      selectedImageBytes = file.bytes;
                                      selectedImageName = file.name;
                                      imageUrlController.text = file.name;
                                    });
                                  }
                                } catch (e) {
                                  _showErrorSnackBar('שגיאה בבחירת תמונה: $e');
                                }
                              },
                              icon: const Icon(Icons.upload, size: 18),
                              label: Text(
                                selectedImageName != null 
                                    ? 'תמונה נבחרה: $selectedImageName' 
                                    : 'בחר תמונה',
                                style: const TextStyle(fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A2A2A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'או הכנס קישור תמונה',
                          labelStyle: TextStyle(color: Colors.white54),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFE91E63)),
                          ),
                          hintText: 'https://example.com/image.jpg',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              selectedImageBytes = null;
                              selectedImageName = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isActive,
                        onChanged: (value) => setState(() => isActive = value ?? true),
                        activeColor: const Color(0xFFE91E63),
                      ),
                      const Text('עדכון פעיל', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ביטול', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: isUploadingImage ? null : () async {
                if (titleController.text.isEmpty || contentController.text.isEmpty) {
                  _showErrorSnackBar('נא למלא כותרת ותוכן');
                  return;
                }

                setState(() => isUploadingImage = true);

                try {
                  String? finalImageUrl = imageUrlController.text;
                  
                  // Upload image to Supabase if selected
                  if (selectedImageBytes != null && selectedImageName != null) {
                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                    final fileName = 'update_${timestamp}_$selectedImageName';
                    
                    await _supabase.storage
                        .from('gallery')
                        .uploadBinary(
                          'updates/$fileName',
                          selectedImageBytes!,
                          fileOptions: const FileOptions(
                            contentType: 'image/jpeg',
                            upsert: true,
                          ),
                        );
                    
                    finalImageUrl = _supabase.storage
                        .from('gallery')
                        .getPublicUrl('updates/$fileName');
                  }

                  final updateData = {
                    'title_he': titleController.text,
                    'content_he': contentController.text,
                    'author_name': authorController.text.isEmpty ? null : authorController.text,
                    'update_type_id': selectedUpdateTypeId,
                    'image_url': finalImageUrl?.isEmpty == true ? null : finalImageUrl,
                    'is_active': isActive,
                    'updated_at': DateTime.now().toIso8601String(),
                  };

                  if (isEditing) {
                    await _supabase
                        .from('updates')
                        .update(updateData)
                        .eq('id', update['id']);
                    _showSuccessSnackBar('עדכון עודכן בהצלחה');
                  } else {
                    updateData.addAll({
                      'views_count': 0,
                      'likes_count': 0,
                    });
                    await _supabase
                        .from('updates')
                        .insert(updateData);
                    _showSuccessSnackBar('עדכון נוסף בהצלחה');
                  }

                  Navigator.of(context).pop();
                  _loadUpdates();
                } catch (e) {
                  _showErrorSnackBar('שגיאה בשמירת עדכון: $e');
                } finally {
                  setState(() => isUploadingImage = false);
                }
              },
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE91E63)),
              child: isUploadingImage 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                      ),
                    )
                  : Text(isEditing ? 'עדכן' : 'הוסף'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteUpdateDialog(Map<String, dynamic> update) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('מחיקת עדכון', style: TextStyle(color: Colors.white)),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את העדכון "${update['title_he']}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _supabase
                    .from('updates')
                    .delete()
                    .eq('id', update['id']);

                Navigator.of(context).pop();
                _showSuccessSnackBar('עדכון נמחק בהצלחה');
                _loadUpdates();
              } catch (e) {
                Navigator.of(context).pop();
                _showErrorSnackBar('שגיאה במחיקת עדכון: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return const Color(0xFFE91E63);
    }
    
    try {
      String cleanColor = colorString.replaceAll('#', '');
      if (cleanColor.length == 6) {
        return Color(int.parse('0xFF$cleanColor'));
      }
      return const Color(0xFFE91E63);
    } catch (e) {
      return const Color(0xFFE91E63);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}