import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class GroupsManagementScreen extends StatefulWidget {
  const GroupsManagementScreen({super.key});

  @override
  State<GroupsManagementScreen> createState() => _GroupsManagementScreenState();
}

class _GroupsManagementScreenState extends State<GroupsManagementScreen> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _supabase
          .from('whatsapp_groups')
          .select('*')
          .order('sort_order', ascending: true);
      
      setState(() {
        _groups = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('שגיאה בטעינת הקבוצות: $e');
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

  Future<void> _toggleGroupStatus(String groupId, bool currentStatus) async {
    try {
      await _supabase
          .from('whatsapp_groups')
          .update({'is_active': !currentStatus})
          .eq('id', groupId);
      
      _showSuccessSnackBar('סטטוס הקבוצה עודכן בהצלחה');
      _loadGroups();
    } catch (e) {
      _showErrorSnackBar('שגיאה בעדכון סטטוס הקבוצה: $e');
    }
  }

  Future<void> _deleteGroup(String groupId, String groupName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'מחק קבוצה',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את הקבוצה "$groupName"?\nפעולה זו בלתי הפיכה.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase
            .from('whatsapp_groups')
            .delete()
            .eq('id', groupId);

        _showSuccessSnackBar('הקבוצה "$groupName" נמחקה בהצלחה');
        _loadGroups();
      } catch (e) {
        _showErrorSnackBar('שגיאה במחיקת הקבוצה: $e');
      }
    }
  }

  void _showAddGroupDialog() {
    _showGroupDialog();
  }

  void _showEditGroupDialog(Map<String, dynamic> group) {
    _showGroupDialog(group: group);
  }

  void _showGroupDialog({Map<String, dynamic>? group}) {
    showDialog(
      context: context,
      builder: (context) => _GroupDialog(
        group: group,
        onGroupSaved: _loadGroups,
        supabase: _supabase,
        picker: _picker,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // כותרת עם כפתור הוספה
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Text(
                  'ניהול קבוצות WhatsApp',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddGroupDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('הוסף קבוצה'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // רשימת הקבוצות
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE91E63)),
                  )
                : _groups.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'אין קבוצות',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'לחץ על "הוסף קבוצה" כדי להתחיל',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          return _buildGroupCard(group);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final isActive = group['is_active'] ?? true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.transparent : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // תמונת הקבוצה
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(30),
            ),
            child: group['image_url'] != null && group['image_url'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(
                      group['image_url'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.group, size: 30, color: Colors.white54),
                    ),
                  )
                : const Icon(Icons.group, size: 30, color: Colors.white54),
          ),
          
          const SizedBox(width: 16),
          
          // פרטי הקבוצה
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group['name'] ?? 'ללא שם',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'פעיל' : 'לא פעיל',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (group['description'] != null && group['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    group['description'],
                    style: TextStyle(
                      color: isActive ? Colors.white70 : Colors.grey,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                if (group['whatsapp_link'] != null) ...[
                  Text(
                    'קישור: ${group['whatsapp_link']}',
                    style: TextStyle(
                      color: isActive ? const Color(0xFF00BCD4) : Colors.grey,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // כפתורי פעולות
          Row(
            children: [
              IconButton(
                onPressed: () => _showEditGroupDialog(group),
                icon: const Icon(Icons.edit, color: Color(0xFF00BCD4), size: 20),
                tooltip: 'ערוך קבוצה',
              ),
              IconButton(
                onPressed: () => _toggleGroupStatus(group['id'], isActive),
                icon: Icon(
                  isActive ? Icons.visibility_off : Icons.visibility,
                  color: Colors.orange,
                  size: 20,
                ),
                tooltip: isActive ? 'הסתר קבוצה' : 'הצג קבוצה',
              ),
              IconButton(
                onPressed: () => _deleteGroup(group['id'], group['name'] ?? 'קבוצה'),
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                tooltip: 'מחק קבוצה',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupDialog extends StatefulWidget {
  final Map<String, dynamic>? group;
  final VoidCallback onGroupSaved;
  final SupabaseClient supabase;
  final ImagePicker picker;

  const _GroupDialog({
    required this.group,
    required this.onGroupSaved,
    required this.supabase,
    required this.picker,
  });

  @override
  State<_GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends State<_GroupDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _linkController;
  late TextEditingController _sortOrderController;
  
  String? _imageUrl;
  bool _isActive = true;
  bool _isLoading = false;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.group?['description'] ?? '');
    _linkController = TextEditingController(text: widget.group?['whatsapp_link'] ?? '');
    _sortOrderController = TextEditingController(text: (widget.group?['sort_order'] ?? 0).toString());
    _imageUrl = widget.group?['image_url'];
    _isActive = widget.group?['is_active'] ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await widget.picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _imageUrl;

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final fileExt = _selectedImage!.path.split('.').last;
      final fileName = 'group_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      await widget.supabase.storage
          .from('gallery')
          .uploadBinary('groups/$fileName', bytes);

      return widget.supabase.storage
          .from('gallery')
          .getPublicUrl('groups/$fileName');
    } catch (e) {
      throw Exception('שגיאה בהעלאת התמונה: $e');
    }
  }

  Future<void> _saveGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('אנא הזן שם לקבוצה')),
      );
      return;
    }

    if (_linkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('אנא הזן קישור WhatsApp')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uploadedImageUrl = await _uploadImage();
      
      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'whatsapp_link': _linkController.text.trim(),
        'sort_order': int.tryParse(_sortOrderController.text) ?? 0,
        'image_url': uploadedImageUrl,
        'is_active': _isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.group == null) {
        // יצירת קבוצה חדשה
        await widget.supabase
            .from('whatsapp_groups')
            .insert(data);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('קבוצה נוספה בהצלחה')),
        );
      } else {
        // עדכון קבוצה קיימת
        await widget.supabase
            .from('whatsapp_groups')
            .update(data)
            .eq('id', widget.group!['id']);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('קבוצה עודכנה בהצלחה')),
        );
      }

      widget.onGroupSaved();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.group == null ? 'הוספת קבוצה חדשה' : 'עריכת קבוצה',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // שם הקבוצה
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'שם הקבוצה *',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            
            // תיאור הקבוצה
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'תיאור הקבוצה',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            
            // קישור WhatsApp
            TextField(
              controller: _linkController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'קישור WhatsApp *',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'https://chat.whatsapp.com/...',
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
            const SizedBox(height: 16),
            
            // סדר תצוגה
            TextField(
              controller: _sortOrderController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'סדר תצוגה',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            
            // תמונה
            Row(
              children: [
                const Text(
                  'תמונת הקבוצה:',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('בחר תמונה'),
                ),
                if (_selectedImage != null || _imageUrl != null) ...[
                  const SizedBox(width: 16),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: kIsWeb
                                ? FutureBuilder<Uint8List?>(
                                    future: _selectedImage!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      return const CircularProgressIndicator();
                                    },
                                  )
                                : Image.file(
                                    File(_selectedImage!.path),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                          )
                        : _imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: Image.network(
                                  _imageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.group, color: Colors.white54),
                                ),
                              )
                            : const Icon(Icons.group, color: Colors.white54),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            
            // סטטוס פעיל
            Row(
              children: [
                Checkbox(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value ?? true),
                ),
                const Text(
                  'קבוצה פעילה',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // כפתורים
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'ביטול',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('שמור'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}