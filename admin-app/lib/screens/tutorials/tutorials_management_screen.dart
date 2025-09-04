import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:data_table_2/data_table_2.dart';
import 'add_tutorial_dialog.dart';

class TutorialsManagementScreen extends ConsumerStatefulWidget {
  const TutorialsManagementScreen({super.key});

  @override
  ConsumerState<TutorialsManagementScreen> createState() => _TutorialsManagementScreenState();
}

class _TutorialsManagementScreenState extends ConsumerState<TutorialsManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _tutorials = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // טעינת קטגוריות
      final categoriesResponse = await _supabase
          .from('tutorial_categories')
          .select('*')
          .order('name');

      // טעינת מדריכים עם קטגוריות
      final tutorialsResponse = await _supabase
          .from('tutorials')
          .select('''
            *,
            tutorial_categories!category_id(id, name, color)
          ''')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(categoriesResponse);
          _tutorials = List<Map<String, dynamic>>.from(tutorialsResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('שגיאה בטעינת הנתונים: $e');
      }
    }
  }

  List<Map<String, dynamic>> get _filteredTutorials {
    if (_searchQuery.isEmpty) return _tutorials;
    
    return _tutorials.where((tutorial) {
      final titleHe = tutorial['title_he']?.toString().toLowerCase() ?? '';
      final descriptionHe = tutorial['description_he']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return titleHe.contains(query) || descriptionHe.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE91E63),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'מדריכים'),
            Tab(text: 'קטגוריות'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTutorialsTab(),
          _buildCategoriesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tabController.index == 0 
            ? _showAddTutorialDialog() 
            : _showAddCategoryDialog(),
        backgroundColor: const Color(0xFFE91E63),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTutorialsTab() {
    return Column(
      children: [
        // כותרת וכפתורים
        _buildTutorialsHeader(),
        
        const SizedBox(height: 24),
        
        // טבלת מדריכים
        Expanded(
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)))
              : _buildTutorialsTable(),
        ),
      ],
    );
  }

  Widget _buildTutorialsHeader() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Padding(
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      child: Column(
        children: [
          Row(
            children: [
              // חיפוש
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'חיפוש מדריכים...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              
              SizedBox(width: isMobile ? 8 : 16),
              
              // כפתור רענון
              IconButton.outlined(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                tooltip: 'רענון',
              ),
            ],
          ),
          if (isMobile) const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTutorialsTable() {
    final filteredTutorials = _filteredTutorials;
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    if (filteredTutorials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: isMobile ? 48 : 64,
              color: Colors.white54,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'אין מדריכים להצגה',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    if (isMobile) {
      return _buildTutorialsListView(filteredTutorials);
    } else {
      return _buildTutorialsDataTable(filteredTutorials);
    }
  }

  Widget _buildTutorialsDataTable(List<Map<String, dynamic>> tutorials) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 900,
          columns: const [
            DataColumn2(
              label: Text('כותרת', style: TextStyle(fontWeight: FontWeight.bold)),
              size: ColumnSize.L,
            ),
            DataColumn2(
              label: Text('קטגוריה', style: TextStyle(fontWeight: FontWeight.bold)),
              size: ColumnSize.M,
            ),
            DataColumn2(
              label: Text('צפיות', style: TextStyle(fontWeight: FontWeight.bold)),
              size: ColumnSize.S,
            ),
            DataColumn2(
              label: Text('לייקים', style: TextStyle(fontWeight: FontWeight.bold)),
              size: ColumnSize.S,
            ),
            DataColumn2(
              label: Text('סטטוס', style: TextStyle(fontWeight: FontWeight.bold)),
              size: ColumnSize.M,
            ),
            DataColumn2(
              label: Text('פעולות', style: TextStyle(fontWeight: FontWeight.bold)),
              size: ColumnSize.M,
            ),
          ],
          rows: tutorials.map((tutorial) {
            return DataRow2(
              cells: [
                // כותרת
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tutorial['title_he'] ?? 'ללא כותרת',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tutorial['description_he'] != null)
                        Text(
                          tutorial['description_he'],
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
                
                // קטגוריה
                DataCell(
                  tutorial['tutorial_categories'] != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _parseColor(tutorial['tutorial_categories']['color']).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tutorial['tutorial_categories']['name'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: _parseColor(tutorial['tutorial_categories']['color']),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : const Text('ללא קטגוריה', style: TextStyle(color: Colors.white54)),
                ),
                
                // צפיות
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '${tutorial['views_count'] ?? 0}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                
                // לייקים
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        '${tutorial['likes_count'] ?? 0}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                
                // סטטוס
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (tutorial['is_active'] == true && tutorial['is_published'] == true)
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (tutorial['is_active'] == true && tutorial['is_published'] == true) 
                          ? 'פעיל' 
                          : 'לא פעיל',
                      style: TextStyle(
                        fontSize: 12,
                        color: (tutorial['is_active'] == true && tutorial['is_published'] == true)
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                // פעולות
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // עריכה
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _editTutorial(tutorial),
                        tooltip: 'עריכה',
                        color: const Color(0xFF00BCD4),
                      ),
                      
                      // מחיקה
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => _deleteTutorial(tutorial),
                        tooltip: 'מחיקה',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTutorialsListView(List<Map<String, dynamic>> tutorials) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: tutorials.length,
      itemBuilder: (context, index) {
        final tutorial = tutorials[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // כותרת ותיאור
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tutorial['title_he'] ?? 'ללא כותרת',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tutorial['description_he'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        tutorial['description_he'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // מידע נוסף
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    // קטגוריה
                    if (tutorial['tutorial_categories'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _parseColor(tutorial['tutorial_categories']['color']).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tutorial['tutorial_categories']['name'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: _parseColor(tutorial['tutorial_categories']['color']),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    
                    // צפיות
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility, size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          '${tutorial['views_count'] ?? 0}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    
                    // לייקים
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, size: 16, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          '${tutorial['likes_count'] ?? 0}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    
                    // סטטוס
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (tutorial['is_active'] == true && tutorial['is_published'] == true)
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (tutorial['is_active'] == true && tutorial['is_published'] == true) 
                            ? 'פעיל' 
                            : 'לא פעיל',
                        style: TextStyle(
                          fontSize: 10,
                          color: (tutorial['is_active'] == true && tutorial['is_published'] == true)
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // כפתורי פעולה
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _editTutorial(tutorial),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('עריכה'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF00BCD4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _deleteTutorial(tutorial),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('מחיקה'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddTutorialDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTutorialDialog(
        categories: _categories,
        onTutorialAdded: () {
          _loadData();
        },
      ),
    );
  }

  void _editTutorial(Map<String, dynamic> tutorial) {
    showDialog(
      context: context,
      builder: (context) => AddTutorialDialog(
        categories: _categories,
        tutorialToEdit: tutorial,
        onTutorialAdded: () {
          _loadData();
        },
      ),
    );
  }

  void _deleteTutorial(Map<String, dynamic> tutorial) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת מדריך'),
        content: Text('האם אתה בטוח שברצונך למחוק את המדריך "${tutorial['title_he']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _supabase
                    .from('tutorials')
                    .delete()
                    .eq('id', tutorial['id']);
                
                if (mounted) {
                  Navigator.pop(context);
                  _showSuccessSnackBar('המדריך נמחק בהצלחה');
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showErrorSnackBar('שגיאה במחיקת המדריך: $e');
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

  Color _parseColor(String? colorStr) {
    if (colorStr == null) return const Color(0xFF00BCD4);
    
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF00BCD4);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Categories Tab
  Widget _buildCategoriesTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      );
    }

    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 64, color: Colors.white38),
            SizedBox(height: 16),
            Text(
              'אין קטגוריות עדיין',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddCategoryDialog,
              icon: Icon(Icons.add),
              label: Text('הוסף קטגוריה ראשונה'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE91E63),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          int crossAxisCount;
          double childAspectRatio;
          
          if (screenWidth < 400) {
            crossAxisCount = 1;
            childAspectRatio = 2.0;
          } else if (screenWidth < 600) {
            crossAxisCount = 2;
            childAspectRatio = 1.5;
          } else if (screenWidth < 900) {
            crossAxisCount = 3;
            childAspectRatio = 1.3;
          } else {
            crossAxisCount = 4;
            childAspectRatio = 1.2;
          }
          
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: screenWidth < 600 ? 8 : 16,
              mainAxisSpacing: screenWidth < 600 ? 8 : 16,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _buildCategoryCard(category, screenWidth < 600);
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, bool isMobile) {
    final color = _parseColor(category['color']);
    
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isMobile ? 20 : 24,
                  height: isMobile ? 20 : 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Text(
                    category['name'] ?? 'ללא שם',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: isMobile ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isMobile ? 8 : 12),
            
            if (category['description']?.isNotEmpty == true)
              Expanded(
                child: Text(
                  category['description'],
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isMobile ? 12 : 14,
                  ),
                  maxLines: isMobile ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            
            if (!isMobile || category['description']?.isEmpty == true) const Spacer(),
            
            SizedBox(height: isMobile ? 8 : 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${_getTutorialsCountForCategory(category['id'])} מדריכים',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: isMobile ? 10 : 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _showEditCategoryDialog(category),
                      child: Icon(
                        Icons.edit,
                        color: const Color(0xFFE91E63),
                        size: isMobile ? 16 : 18,
                      ),
                    ),
                    SizedBox(width: isMobile ? 6 : 8),
                    InkWell(
                      onTap: () => _showDeleteCategoryDialog(category),
                      child: Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: isMobile ? 16 : 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _getTutorialsCountForCategory(String categoryId) {
    return _tutorials.where((tutorial) => 
      tutorial['category_id'] == categoryId
    ).length;
  }

  void _showAddCategoryDialog() {
    _showCategoryDialog();
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    _showCategoryDialog(category: category);
  }

  void _showCategoryDialog({Map<String, dynamic>? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?['name'] ?? '');
    final descriptionController = TextEditingController(text: category?['description'] ?? '');
    final colorController = TextEditingController(text: category?['color'] ?? '#E91E63');
    bool isUploadingCategory = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            isEditing ? 'עריכת קטגוריה' : 'הוספת קטגוריה חדשה',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'שם הקטגוריה',
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
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'תיאור הקטגוריה',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE91E63)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'צבע הקטגוריה:',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(width: 16),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _parseColor(colorController.text),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(
                    labelText: 'קוד צבע (HEX)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE91E63)),
                    ),
                    hintText: '#E91E63',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    '#E91E63', '#2196F3', '#4CAF50', '#FF9800', 
                    '#9C27B0', '#F44336', '#00BCD4', '#FFC107'
                  ].map((colorHex) {
                    return GestureDetector(
                      onTap: () {
                        colorController.text = colorHex;
                        setState(() {});
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _parseColor(colorHex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorController.text == colorHex 
                                ? Colors.white 
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ביטול', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: isUploadingCategory ? null : () async {
                if (nameController.text.isEmpty) {
                  _showErrorSnackBar('נא למלא שם קטגוריה');
                  return;
                }

                setState(() => isUploadingCategory = true);

                try {
                  if (isEditing) {
                    await _supabase
                        .from('tutorial_categories')
                        .update({
                          'name': nameController.text,
                          'description': descriptionController.text,
                          'color': colorController.text,
                          'updated_at': DateTime.now().toIso8601String(),
                        })
                        .eq('id', category['id']);
                    _showSuccessSnackBar('קטגוריה עודכנה בהצלחה');
                  } else {
                    await _supabase
                        .from('tutorial_categories')
                        .insert({
                          'name': nameController.text,
                          'description': descriptionController.text,
                          'color': colorController.text,
                        });
                    _showSuccessSnackBar('קטגוריה נוספה בהצלחה');
                  }

                  Navigator.of(context).pop();
                  _loadData();
                } catch (e) {
                  _showErrorSnackBar('שגיאה בשמירת קטגוריה: $e');
                } finally {
                  setState(() => isUploadingCategory = false);
                }
              },
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE91E63)),
              child: isUploadingCategory 
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

  void _showDeleteCategoryDialog(Map<String, dynamic> category) {
    final tutorialsCount = _getTutorialsCountForCategory(category['id']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('מחיקת קטגוריה', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'האם אתה בטוח שברצונך למחוק את הקטגוריה "${category['name']}"?',
              style: const TextStyle(color: Colors.white70),
            ),
            if (tutorialsCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'אזהרה!',
                            style: const TextStyle(
                              color: Colors.red, 
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'יש $tutorialsCount מדריכים בקטגוריה זו.\n'
                      'מחיקת הקטגוריה תמחק גם את כל המדריכים שבה!',
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
                    .from('tutorial_categories')
                    .delete()
                    .eq('id', category['id']);

                Navigator.of(context).pop();
                if (tutorialsCount > 0) {
                  _showSuccessSnackBar('קטגוריה ו-$tutorialsCount מדריכים נמחקו בהצלחה');
                } else {
                  _showSuccessSnackBar('קטגוריה נמחקה בהצלחה');
                }
                _loadData();
              } catch (e) {
                Navigator.of(context).pop();
                _showErrorSnackBar('שגיאה במחיקת קטגוריה: $e');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              backgroundColor: Colors.red.withOpacity(0.1),
            ),
            child: Text(tutorialsCount > 0 ? 'מחק הכל' : 'מחק'),
          ),
        ],
      ),
    );
  }
}