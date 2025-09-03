import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateTypesManagementScreen extends StatefulWidget {
  const UpdateTypesManagementScreen({super.key});

  @override
  State<UpdateTypesManagementScreen> createState() => _UpdateTypesManagementScreenState();
}

class _UpdateTypesManagementScreenState extends State<UpdateTypesManagementScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _updateTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUpdateTypes();
  }

  Future<void> _loadUpdateTypes() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _supabase
          .from('update_types')
          .select('*')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _updateTypes = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('שגיאה בטעינת סוגי העדכונים: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ניהול סוגי עדכונים'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showUpdateTypeDialog(),
            icon: const Icon(Icons.add),
            label: const Text('הוסף סוג חדש'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUpdateTypes,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0A0A0A),
      body: _buildUpdateTypesList(),
    );
  }

  Widget _buildUpdateTypesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      );
    }

    if (_updateTypes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'אין סוגי עדכונים',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white54,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'לחץ על "הוסף סוג חדש" כדי להתחיל',
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
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: _updateTypes.length,
        itemBuilder: (context, index) {
          final type = _updateTypes[index];
          return _buildUpdateTypeCard(type);
        },
      ),
    );
  }

  Widget _buildUpdateTypeCard(Map<String, dynamic> type) {
    final color = _getColorFromHex(type['color']);
    final icon = _getIconFromName(type['icon']);
    final isActive = type['is_active'] ?? true;

    return Card(
      color: const Color(0xFF1E1E1E),
      child: InkWell(
        onTap: () => _showUpdateTypeDialog(type: type),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // אייקון וסטטוס
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // שם הסוג
              Text(
                type['name_he'] ?? type['name'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              if (type['name_en'] != null && type['name_en'].isNotEmpty)
                Text(
                  type['name_en'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              
              const Spacer(),
              
              // כפתורי פעולה
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _showUpdateTypeDialog(type: type),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('עריכה'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF00BCD4),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showDeleteDialog(type),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('מחק'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      textStyle: const TextStyle(fontSize: 12),
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

  void _showUpdateTypeDialog({Map<String, dynamic>? type}) {
    final isEditing = type != null;
    final nameHeController = TextEditingController(text: type?['name_he'] ?? '');
    final nameEnController = TextEditingController(text: type?['name_en'] ?? '');
    final nameController = TextEditingController(text: type?['name'] ?? '');
    
    String selectedColor = type?['color'] ?? '#E91E63';
    String selectedIcon = type?['icon'] ?? 'article';
    bool isActive = type?['is_active'] ?? true;

    final colors = [
      '#E91E63', '#9C27B0', '#3F51B5', '#2196F3', '#00BCD4',
      '#009688', '#4CAF50', '#8BC34A', '#CDDC39', '#FFEB3B',
      '#FFC107', '#FF9800', '#FF5722', '#795548', '#9E9E9E'
    ];

    final icons = [
      {'name': 'article', 'icon': Icons.article},
      {'name': 'announcement', 'icon': Icons.announcement},
      {'name': 'event', 'icon': Icons.event},
      {'name': 'newspaper', 'icon': Icons.newspaper},
      {'name': 'priority_high', 'icon': Icons.priority_high},
      {'name': 'star', 'icon': Icons.star},
      {'name': 'info', 'icon': Icons.info},
      {'name': 'campaign', 'icon': Icons.campaign},
      {'name': 'celebration', 'icon': Icons.celebration},
      {'name': 'notifications', 'icon': Icons.notifications},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            isEditing ? 'עריכת סוג עדכון' : 'הוספת סוג עדכון חדש',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // שם בעברית
                  TextField(
                    controller: nameHeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'שם בעברית *',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // שם באנגלית
                  TextField(
                    controller: nameEnController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'שם באנגלית',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // שם מערכת (לזיהוי)
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'שם מערכת (אנגלית) *',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      hintText: 'announcement, event, etc.',
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // בחירת צבע
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'צבע',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: colors.map((color) => GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getColorFromHex(color),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == color 
                                    ? Colors.white 
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: selectedColor == color 
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // בחירת אייקון
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'אייקון',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: icons.map((iconData) => GestureDetector(
                          onTap: () => setState(() => selectedIcon = iconData['name'] as String),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: selectedIcon == iconData['name'] 
                                  ? _getColorFromHex(selectedColor).withOpacity(0.2)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedIcon == iconData['name'] 
                                    ? _getColorFromHex(selectedColor) 
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              iconData['icon'] as IconData,
                              color: selectedIcon == iconData['name'] 
                                  ? _getColorFromHex(selectedColor)
                                  : Colors.white70,
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // סטטוס פעיל
                  SwitchListTile(
                    title: const Text(
                      'פעיל',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: isActive,
                    onChanged: (value) => setState(() => isActive = value),
                    activeColor: const Color(0xFFE91E63),
                  ),
                ],
              ),
            ),
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
              onPressed: () async {
                if (nameHeController.text.trim().isEmpty || nameController.text.trim().isEmpty) {
                  _showErrorSnackBar('יש למלא את השדות החובה');
                  return;
                }

                try {
                  final data = {
                    'name_he': nameHeController.text.trim(),
                    'name_en': nameEnController.text.trim().isEmpty 
                        ? null 
                        : nameEnController.text.trim(),
                    'name': nameController.text.trim(),
                    'color': selectedColor,
                    'icon': selectedIcon,
                    'is_active': isActive,
                  };

                  if (isEditing) {
                    await _supabase
                        .from('update_types')
                        .update(data)
                        .eq('id', type['id']);
                    _showSuccessSnackBar('סוג העדכון עודכן בהצלחה');
                  } else {
                    await _supabase
                        .from('update_types')
                        .insert(data);
                    _showSuccessSnackBar('סוג עדכון חדש נוסף בהצלחה');
                  }

                  if (mounted) {
                    Navigator.of(context).pop();
                    _loadUpdateTypes();
                  }
                } catch (e) {
                  _showErrorSnackBar('שגיאה בשמירת סוג העדכון: $e');
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

  void _showDeleteDialog(Map<String, dynamic> type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'מחיקת סוג עדכון',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את סוג העדכון "${type['name_he']}"?\n\nפעולה זו לא ניתנת לביטול.',
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
            onPressed: () async {
              try {
                await _supabase
                    .from('update_types')
                    .delete()
                    .eq('id', type['id']);

                _showSuccessSnackBar('סוג העדכון נמחק בהצלחה');
                if (mounted) {
                  Navigator.of(context).pop();
                  _loadUpdateTypes();
                }
              } catch (e) {
                _showErrorSnackBar('שגיאה במחיקת סוג העדכון: $e');
              }
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

  // פונקציות עזר
  IconData _getIconFromName(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'announcement':
        return Icons.announcement;
      case 'event':
        return Icons.event;
      case 'newspaper':
        return Icons.newspaper;
      case 'priority_high':
        return Icons.priority_high;
      case 'star':
        return Icons.star;
      case 'info':
        return Icons.info;
      case 'campaign':
        return Icons.campaign;
      case 'celebration':
        return Icons.celebration;
      case 'notifications':
        return Icons.notifications;
      default:
        return Icons.article;
    }
  }

  Color _getColorFromHex(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return const Color(0xFFE91E63);
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFFE91E63);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}