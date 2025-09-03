import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddTutorialDialog extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? tutorialToEdit;
  final VoidCallback onTutorialAdded;

  const AddTutorialDialog({
    super.key,
    required this.categories,
    this.tutorialToEdit,
    required this.onTutorialAdded,
  });

  @override
  State<AddTutorialDialog> createState() => _AddTutorialDialogState();
}

class _AddTutorialDialogState extends State<AddTutorialDialog> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _videoUrlController;
  String? _selectedCategoryId;
  bool _isActive = true;
  bool _isPublished = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // אתחול controllers
    _titleController = TextEditingController(text: widget.tutorialToEdit?['title_he'] ?? '');
    _descriptionController = TextEditingController(text: widget.tutorialToEdit?['description_he'] ?? '');
    _videoUrlController = TextEditingController(text: widget.tutorialToEdit?['video_url'] ?? '');
    
    // אם זו עריכה, טען את הנתונים הקיימים
    if (widget.tutorialToEdit != null) {
      _selectedCategoryId = widget.tutorialToEdit!['category_id'];
      _isActive = widget.tutorialToEdit!['is_active'] ?? true;
      _isPublished = widget.tutorialToEdit!['is_published'] ?? true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // כותרת הדיאלוג
              Row(
                children: [
                  Icon(
                    widget.tutorialToEdit != null ? Icons.edit : Icons.add,
                    color: const Color(0xFFE91E63),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.tutorialToEdit != null ? 'עריכת מדריך' : 'הוספת מדריך חדש',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.white70,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // תוכן הטופס
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // כותרת המדריך
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'כותרת המדריך *',
                          hintText: 'הזן כותרת למדריך...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'יש להזין כותרת למדריך';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // תיאור המדריך
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'תיאור המדריך',
                          hintText: 'הזן תיאור למדריך...',
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // URL של הוידאו
                      TextFormField(
                        controller: _videoUrlController,
                        decoration: const InputDecoration(
                          labelText: 'קישור YouTube *',
                          hintText: 'https://www.youtube.com/watch?v=...',
                          prefixIcon: Icon(Icons.video_library),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'יש להזין קישור וידאו';
                          }
                          if (!value.contains('youtube.com/watch') && !value.contains('youtu.be/')) {
                            return 'קישור YouTube לא תקין';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // בחירת קטגוריה
                      DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'קטגוריית המדריך',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('ללא קטגוריה'),
                          ),
                          ...widget.categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category['id'],
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _parseColor(category['color']),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category['name'] ?? ''),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // הגדרות פרסום
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'הגדרות פרסום',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // מדריך פעיל
                              SwitchListTile(
                                title: const Text('מדריך פעיל'),
                                subtitle: const Text('המדריך יוצג במערכת'),
                                value: _isActive,
                                onChanged: (value) {
                                  setState(() {
                                    _isActive = value;
                                  });
                                },
                                activeColor: const Color(0xFFE91E63),
                              ),
                              
                              // מדריך מפורסם
                              SwitchListTile(
                                title: const Text('מדריך מפורסם'),
                                subtitle: const Text('המדריך יהיה נגיש למשתמשים'),
                                value: _isPublished,
                                onChanged: (value) {
                                  setState(() {
                                    _isPublished = value;
                                  });
                                },
                                activeColor: const Color(0xFFE91E63),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // כפתורי פעולה
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('ביטול'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveTutorial,
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(widget.tutorialToEdit != null ? 'עדכן' : 'הוסף'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTutorial() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tutorialData = {
        'title_he': _titleController.text.trim(),
        'description_he': _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        'video_url': _videoUrlController.text.trim(),
        'category_id': _selectedCategoryId,
        'is_active': _isActive,
        'is_published': _isPublished,
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('Saving tutorial data: $tutorialData'); // Debug log

      if (widget.tutorialToEdit != null) {
        // עדכון מדריך קיים
        print('Updating tutorial with ID: ${widget.tutorialToEdit!['id']}'); // Debug log
        
        final response = await _supabase
            .from('tutorials')
            .update(tutorialData)
            .eq('id', widget.tutorialToEdit!['id'])
            .select(); // Add select to get response
        
        print('Update response: $response'); // Debug log
        _showSuccessMessage('המדריך עודכן בהצלחה!');
      } else {
        // הוספת מדריך חדש
        tutorialData['created_at'] = DateTime.now().toIso8601String();
        
        final response = await _supabase
            .from('tutorials')
            .insert(tutorialData)
            .select(); // Add select to get response
        
        print('Insert response: $response'); // Debug log
        _showSuccessMessage('המדריך נוסף בהצלחה!');
      }

      if (mounted) {
        widget.onTutorialAdded();
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving tutorial: $e'); // Debug log
      _showErrorMessage('שגיאה בשמירת המדריך: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null) return const Color(0xFF00BCD4);
    
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF00BCD4);
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}