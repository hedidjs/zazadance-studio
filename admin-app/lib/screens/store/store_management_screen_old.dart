import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _supabase
          .from('product_categories')
          .select('*')
          .order('sort_order', ascending: true);

      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('שגיאה בטעינת קטגוריות: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, product_categories(name_he)')
          .order('sort_order', ascending: true);

      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _showErrorSnackBar('שגיאה בטעינת מוצרים: $e');
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
          'ניהול חנות',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE91E63),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'קטגוריות'),
            Tab(text: 'מוצרים'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesTab(),
          _buildProductsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tabController.index == 0 
            ? _showAddCategoryDialog() 
            : _showAddProductDialog(),
        backgroundColor: const Color(0xFFE91E63),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

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
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryCard(category);
        },
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 64, color: Colors.white38),
            SizedBox(height: 16),
            Text(
              'אין מוצרים עדיין',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddProductDialog,
              icon: Icon(Icons.add),
              label: Text('הוסף מוצר ראשון'),
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
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                color: const Color(0xFF2A2A2A),
              ),
              child: _isValidImageUrl(category['cover_image_url'])
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      child: Image.network(
                        category['cover_image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderIcon(Icons.category);
                        },
                      ),
                    )
                  : _buildPlaceholderIcon(Icons.category),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category['name_he'] ?? 'ללא שם',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (category['description_he']?.isNotEmpty == true)
                  Text(
                    category['description_he'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category['is_active'] ? 'פעיל' : 'לא פעיל',
                      style: TextStyle(
                        color: category['is_active'] ? Colors.green : Colors.red,
                        fontSize: 11,
                      ),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _showEditCategoryDialog(category),
                          child: const Icon(
                            Icons.edit,
                            color: Color(0xFFE91E63),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showDeleteCategoryDialog(category),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                color: const Color(0xFF2A2A2A),
              ),
              child: _isValidImageUrl(product['image_url'])
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      child: Image.network(
                        product['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderIcon(Icons.inventory);
                        },
                      ),
                    )
                  : _buildPlaceholderIcon(Icons.inventory),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name_he'] ?? 'ללא שם',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₪${product['price']?.toString() ?? '0'}',
                  style: const TextStyle(
                    color: Color(0xFFE91E63),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (product['product_categories'] != null)
                  Text(
                    product['product_categories']['name_he'] ?? '',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product['availability'] ? 'זמין' : 'לא זמין',
                      style: TextStyle(
                        color: product['availability'] ? Colors.green : Colors.red,
                        fontSize: 10,
                      ),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _showEditProductDialog(product),
                          child: const Icon(
                            Icons.edit,
                            color: Color(0xFFE91E63),
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => _showDeleteProductDialog(product),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon(IconData icon) {
    return Center(
      child: Icon(
        icon,
        color: Colors.white38,
        size: 40,
      ),
    );
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http') && !url.contains('example.com');
  }

  void _showAddCategoryDialog() {
    _showCategoryDialog();
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    _showCategoryDialog(category: category);
  }

  void _showAddProductDialog() {
    _showProductDialog();
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    _showProductDialog(product: product);
  }

  void _showCategoryDialog({Map<String, dynamic>? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?['name_he'] ?? '');
    final descriptionController = TextEditingController(text: category?['description_he'] ?? '');
    final imageUrlController = TextEditingController(text: category?['cover_image_url'] ?? '');
    bool isActive = category?['is_active'] ?? true;

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
                    labelText: 'שם הקטגוריה (עברית)',
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
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'כתובת תמונת כיסוי',
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
                Row(
                  children: [
                    Checkbox(
                      value: isActive,
                      onChanged: (value) => setState(() => isActive = value ?? true),
                      activeColor: const Color(0xFFE91E63),
                    ),
                    const Text('קטגוריה פעילה', style: TextStyle(color: Colors.white)),
                  ],
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
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  _showErrorSnackBar('נא למלא שם קטגוריה');
                  return;
                }

                try {
                  if (isEditing) {
                    await _supabase
                        .from('product_categories')
                        .update({
                          'name_he': nameController.text,
                          'description_he': descriptionController.text,
                          'cover_image_url': imageUrlController.text,
                          'is_active': isActive,
                          'updated_at': DateTime.now().toIso8601String(),
                        })
                        .eq('id', category['id']);
                    _showSuccessSnackBar('קטגוריה עודכנה בהצלחה');
                  } else {
                    await _supabase
                        .from('product_categories')
                        .insert({
                          'name_he': nameController.text,
                          'description_he': descriptionController.text,
                          'cover_image_url': imageUrlController.text,
                          'is_active': isActive,
                          'sort_order': _categories.length,
                        });
                    _showSuccessSnackBar('קטגוריה נוספה בהצלחה');
                  }

                  Navigator.of(context).pop();
                  _loadCategories();
                } catch (e) {
                  _showErrorSnackBar('שגיאה בשמירת קטגוריה: $e');
                }
              },
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE91E63)),
              child: Text(isEditing ? 'עדכן' : 'הוסף'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDialog({Map<String, dynamic>? product}) {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?['name_he'] ?? '');
    final descriptionController = TextEditingController(text: product?['description_he'] ?? '');
    final priceController = TextEditingController(text: product?['price']?.toString() ?? '');
    final imageUrlController = TextEditingController(text: product?['image_url'] ?? '');
    final purchaseUrlController = TextEditingController(text: product?['purchase_url'] ?? '');
    String? selectedCategoryId = product?['category_id'];
    bool isAvailable = product?['availability'] ?? true;
    bool isActive = product?['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            isEditing ? 'עריכת מוצר' : 'הוספת מוצר חדש',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'שם המוצר (עברית)',
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
                      labelText: 'תיאור המוצר',
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
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'מחיר (₪)',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE91E63)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'קטגוריה',
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
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category['id'],
                        child: Text(category['name_he']),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedCategoryId = value),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'כתובת תמונת המוצר',
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
                    controller: purchaseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'קישור לרכישה',
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
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Checkbox(
                              value: isAvailable,
                              onChanged: (value) => setState(() => isAvailable = value ?? true),
                              activeColor: const Color(0xFFE91E63),
                            ),
                            const Text('זמין', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Checkbox(
                              value: isActive,
                              onChanged: (value) => setState(() => isActive = value ?? true),
                              activeColor: const Color(0xFFE91E63),
                            ),
                            const Text('פעיל', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
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
              onPressed: () async {
                if (nameController.text.isEmpty || 
                    priceController.text.isEmpty || 
                    selectedCategoryId == null) {
                  _showErrorSnackBar('נא למלא את כל השדות הנדרשים');
                  return;
                }

                try {
                  final price = double.tryParse(priceController.text);
                  if (price == null) {
                    _showErrorSnackBar('מחיר לא תקין');
                    return;
                  }

                  if (isEditing) {
                    await _supabase
                        .from('products')
                        .update({
                          'name_he': nameController.text,
                          'description_he': descriptionController.text,
                          'price': price,
                          'category_id': selectedCategoryId,
                          'image_url': imageUrlController.text,
                          'purchase_url': purchaseUrlController.text,
                          'availability': isAvailable,
                          'is_active': isActive,
                          'updated_at': DateTime.now().toIso8601String(),
                        })
                        .eq('id', product['id']);
                    _showSuccessSnackBar('מוצר עודכן בהצלחה');
                  } else {
                    await _supabase
                        .from('products')
                        .insert({
                          'name_he': nameController.text,
                          'description_he': descriptionController.text,
                          'price': price,
                          'category_id': selectedCategoryId,
                          'image_url': imageUrlController.text,
                          'purchase_url': purchaseUrlController.text,
                          'availability': isAvailable,
                          'is_active': isActive,
                          'sort_order': _products.length,
                        });
                    _showSuccessSnackBar('מוצר נוסף בהצלחה');
                  }

                  Navigator.of(context).pop();
                  _loadProducts();
                } catch (e) {
                  _showErrorSnackBar('שגיאה בשמירת מוצר: $e');
                }
              },
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE91E63)),
              child: Text(isEditing ? 'עדכן' : 'הוסף'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCategoryDialog(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('מחיקת קטגוריה', style: TextStyle(color: Colors.white)),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את הקטגוריה "${category['name_he']}"?',
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
                    .from('product_categories')
                    .delete()
                    .eq('id', category['id']);

                Navigator.of(context).pop();
                _showSuccessSnackBar('קטגוריה נמחקה בהצלחה');
                _loadCategories();
                _loadProducts(); // Refresh products too
              } catch (e) {
                Navigator.of(context).pop();
                _showErrorSnackBar('שגיאה במחיקת קטגוריה: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }

  void _showDeleteProductDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('מחיקת מוצר', style: TextStyle(color: Colors.white)),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את המוצר "${product['name_he']}"?',
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
                    .from('products')
                    .delete()
                    .eq('id', product['id']);

                Navigator.of(context).pop();
                _showSuccessSnackBar('מוצר נמחק בהצלחה');
                _loadProducts();
              } catch (e) {
                Navigator.of(context).pop();
                _showErrorSnackBar('שגיאה במחיקת מוצר: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }
}