import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AboutManagementScreen extends ConsumerStatefulWidget {
  const AboutManagementScreen({super.key});

  @override
  ConsumerState<AboutManagementScreen> createState() => _AboutManagementScreenState();
}

class _AboutManagementScreenState extends ConsumerState<AboutManagementScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _aboutSections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAboutSections();
  }

  Future<void> _loadAboutSections() async {
    try {
      setState(() { _isLoading = true; });

      final response = await _supabase
          .from('about_content')
          .select('*')
          .order('sort_order');

      if (mounted) {
        setState(() {
          _aboutSections = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בטעינת נתונים: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addSection() async {
    await showDialog(
      context: context,
      builder: (context) => _AddEditSectionDialog(onSave: _loadAboutSections),
    );
  }

  Future<void> _editSection(Map<String, dynamic> section) async {
    await showDialog(
      context: context,
      builder: (context) => _AddEditSectionDialog(
        section: section,
        onSave: _loadAboutSections,
      ),
    );
  }

  Future<void> _deleteSection(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('אישור מחיקה'),
        content: const Text('האם אתה בטוח שברצונך למחוק את הסעיף הזה?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.from('about_content').delete().eq('id', id);
        _loadAboutSections();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('שגיאה במחיקת הסעיף: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ניהול תוכן אודות הסטודיו'),
        actions: [
          IconButton(
            onPressed: _addSection,
            icon: const Icon(Icons.add),
            tooltip: 'הוסף סעיף חדש',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _aboutSections.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'אין סעיפים להצגה',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: _aboutSections.length,
                    itemBuilder: (context, index) {
                      final section = _aboutSections[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      section['title_he'] ?? 'ללא כותרת',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: section['is_active'] 
                                              ? Colors.green.withOpacity(0.2)
                                              : Colors.red.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          section['is_active'] ? 'פעיל' : 'לא פעיל',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: section['is_active'] 
                                                ? Colors.green 
                                                : Colors.red,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _editSection(section),
                                        icon: const Icon(Icons.edit),
                                        tooltip: 'עריכה',
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteSection(section['id']),
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'מחיקה',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (section['content_he'] != null)
                                Text(
                                  section['content_he'],
                                  style: const TextStyle(color: Colors.white70),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'סדר: ${section['sort_order']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  if (section['image_url'] != null) ...[
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.image,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    const Text(
                                      ' יש תמונה',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _AddEditSectionDialog extends StatefulWidget {
  final Map<String, dynamic>? section;
  final VoidCallback onSave;

  const _AddEditSectionDialog({this.section, required this.onSave});

  @override
  State<_AddEditSectionDialog> createState() => _AddEditSectionDialogState();
}

class _AddEditSectionDialogState extends State<_AddEditSectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _sortOrderController = TextEditingController();
  
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.section != null) {
      _titleController.text = widget.section!['title_he'] ?? '';
      _contentController.text = widget.section!['content_he'] ?? '';
      _imageUrlController.text = widget.section!['image_url'] ?? '';
      _sortOrderController.text = (widget.section!['sort_order'] ?? 0).toString();
      _isActive = widget.section!['is_active'] ?? true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSaving = true; });

    try {
      final data = {
        'title_he': _titleController.text,
        'content_he': _contentController.text,
        'image_url': _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        'sort_order': int.tryParse(_sortOrderController.text) ?? 0,
        'is_active': _isActive,
      };

      if (widget.section != null) {
        await Supabase.instance.client
            .from('about_content')
            .update(data)
            .eq('id', widget.section!['id']);
      } else {
        await Supabase.instance.client
            .from('about_content')
            .insert(data);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.section != null ? 'הסעיף עודכן בהצלחה' : 'סעיף חדש נוסף בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() { _isSaving = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת הסעיף: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.section != null ? 'עריכת סעיף' : 'הוספת סעיף חדש'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'כותרת *'),
                validator: (value) => value?.isEmpty == true ? 'חובה למלא כותרת' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'תוכן *'),
                maxLines: 4,
                validator: (value) => value?.isEmpty == true ? 'חובה למלא תוכן' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'קישור לתמונה (אופציונלי)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sortOrderController,
                decoration: const InputDecoration(labelText: 'סדר תצוגה'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isNotEmpty == true) {
                    if (int.tryParse(value!) == null) return 'הכנס מספר תקין';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isActive,
                    onChanged: (value) => setState(() { _isActive = value ?? true; }),
                  ),
                  const Text('פעיל'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.section != null ? 'עדכן' : 'הוסף'),
        ),
      ],
    );
  }
}