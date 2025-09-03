import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TermsManagementScreen extends ConsumerStatefulWidget {
  const TermsManagementScreen({super.key});

  @override
  ConsumerState<TermsManagementScreen> createState() => _TermsManagementScreenState();
}

class _TermsManagementScreenState extends ConsumerState<TermsManagementScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  
  late TabController _tabController;
  
  Map<String, dynamic>? _termsContent;
  Map<String, dynamic>? _privacyContent;
  Map<String, dynamic>? _disclaimerContent;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllContent() async {
    try {
      setState(() { _isLoading = true; });

      final response = await _supabase
          .from('terms_content')
          .select('*')
          .order('content_type');

      if (mounted) {
        final contents = List<Map<String, dynamic>>.from(response);
        
        setState(() {
          _termsContent = contents.where((c) => c['content_type'] == 'terms').firstOrNull;
          _privacyContent = contents.where((c) => c['content_type'] == 'privacy').firstOrNull;
          _disclaimerContent = contents.where((c) => c['content_type'] == 'disclaimer').firstOrNull;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בטעינת התוכן: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editContent(String contentType, Map<String, dynamic>? content) async {
    await showDialog(
      context: context,
      builder: (context) => _EditContentDialog(
        contentType: contentType,
        content: content,
        onSave: _loadAllContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ניהול תקנון ופרטיות'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.description_outlined), text: 'תנאי שימוש'),
            Tab(icon: Icon(Icons.privacy_tip_outlined), text: 'פרטיות'),
            Tab(icon: Icon(Icons.warning_outlined), text: 'הסבר אחריות'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildContentTab('terms', _termsContent, 'תנאי שימוש'),
                _buildContentTab('privacy', _privacyContent, 'מדיניות פרטיות'),
                _buildContentTab('disclaimer', _disclaimerContent, 'הסבר אחריות'),
              ],
            ),
    );
  }

  Widget _buildContentTab(String contentType, Map<String, dynamic>? content, String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _editContent(contentType, content),
                        icon: Icon(content != null ? Icons.edit : Icons.add),
                        label: Text(content != null ? 'עריכה' : 'הוספה'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (content != null) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: content['is_active'] 
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            content['is_active'] ? 'פעיל' : 'לא פעיל',
                            style: TextStyle(
                              fontSize: 12,
                              color: content['is_active'] 
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'גרסה ${content['version'] ?? '1.0'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        if (content['effective_date'] != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            'בתוקף מ-${_formatDate(content['effective_date'])}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'כותרת:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(content['title_he'] ?? 'לא הוגדר'),
                    const SizedBox(height: 16),
                    const Text(
                      'תוכן:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      height: 200,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          content['content_he'] ?? 'לא הוגדר תוכן',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'עודכן לאחרונה: ${content['updated_at'] != null ? _formatDateTime(content['updated_at']) : 'לא ידוע'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'לא הוגדר תוכן עדיין',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'לחץ על "הוספה" כדי להוסיף תוכן חדש',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} בשעה ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

class _EditContentDialog extends StatefulWidget {
  final String contentType;
  final Map<String, dynamic>? content;
  final VoidCallback onSave;

  const _EditContentDialog({
    required this.contentType,
    this.content,
    required this.onSave,
  });

  @override
  State<_EditContentDialog> createState() => _EditContentDialogState();
}

class _EditContentDialogState extends State<_EditContentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _versionController = TextEditingController();
  final _effectiveDateController = TextEditingController();
  
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.content != null) {
      _titleController.text = widget.content!['title_he'] ?? '';
      _contentController.text = widget.content!['content_he'] ?? '';
      _versionController.text = widget.content!['version'] ?? '';
      _effectiveDateController.text = widget.content!['effective_date'] ?? '';
      _isActive = widget.content!['is_active'] ?? true;
    } else {
      _versionController.text = '1.0';
      _effectiveDateController.text = DateTime.now().toIso8601String().split('T')[0];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _versionController.dispose();
    _effectiveDateController.dispose();
    super.dispose();
  }

  String _getDefaultTitle(String contentType) {
    switch (contentType) {
      case 'terms': return 'תנאי שימוש';
      case 'privacy': return 'מדיניות פרטיות';
      case 'disclaimer': return 'הסבר אחריות';
      default: return 'תוכן';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSaving = true; });

    try {
      final data = {
        'content_type': widget.contentType,
        'title_he': _titleController.text.isEmpty 
            ? _getDefaultTitle(widget.contentType) 
            : _titleController.text,
        'content_he': _contentController.text,
        'version': _versionController.text,
        'effective_date': _effectiveDateController.text,
        'is_active': _isActive,
      };

      if (widget.content != null) {
        await Supabase.instance.client
            .from('terms_content')
            .update(data)
            .eq('id', widget.content!['id']);
      } else {
        await Supabase.instance.client
            .from('terms_content')
            .insert(data);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.content != null ? 'התוכן עודכן בהצלחה' : 'תוכן חדש נוסף בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() { _isSaving = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת התוכן: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.content != null ? 'עריכת' : 'הוספת'} ${_getDefaultTitle(widget.contentType)}'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'כותרת',
                  hintText: _getDefaultTitle(widget.contentType),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'תוכן *'),
                maxLines: 10,
                validator: (value) => value?.isEmpty == true ? 'חובה למלא תוכן' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _versionController,
                      decoration: const InputDecoration(labelText: 'גרסה'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _effectiveDateController,
                      decoration: const InputDecoration(
                        labelText: 'תאריך תוקף',
                        hintText: 'YYYY-MM-DD',
                      ),
                    ),
                  ),
                ],
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
              : Text(widget.content != null ? 'עדכן' : 'הוסף'),
        ),
      ],
    );
  }
}