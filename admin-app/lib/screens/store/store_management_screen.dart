import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

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
  List<Map<String, dynamic>> _sizes = [];
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCategories();
    _loadProducts();
    _loadSizes();
    _loadOrders();
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

  Future<void> _loadSizes() async {
    try {
      final response = await _supabase
          .from('product_sizes')
          .select('*')
          .order('display_order', ascending: true);

      setState(() {
        _sizes = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      _showErrorSnackBar('שגיאה בטעינת מידות: $e');
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
            Tab(text: 'מידות'),
            Tab(text: 'הזמנות'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesTab(),
          _buildProductsTab(),
          _buildSizesTab(),
          _buildOrdersTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 3 ? null : FloatingActionButton(
        onPressed: () {
          switch (_tabController.index) {
            case 0:
              _showAddCategoryDialog();
              break;
            case 1:
              _showAddProductDialog();
              break;
            case 2:
              _showAddSizeDialog();
              break;
          }
        },
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
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 8 : 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          int crossAxisCount;
          double childAspectRatio;
          
          if (screenWidth < 400) {
            crossAxisCount = 1;
            childAspectRatio = 2.5;
          } else if (screenWidth < 600) {
            crossAxisCount = 2;
            childAspectRatio = 1.8;
          } else if (screenWidth < 900) {
            crossAxisCount = 2;
            childAspectRatio = 1.5;
          } else {
            crossAxisCount = 3;
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
              return _buildCategoryCard(category);
            },
          );
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
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: product['product_type'] == 'clothing' 
                        ? const Color(0xFF00BCD4).withOpacity(0.2) 
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product['product_type'] == 'clothing' ? 'בגד' : 'רגיל',
                    style: TextStyle(
                      color: product['product_type'] == 'clothing' 
                          ? const Color(0xFF00BCD4) 
                          : Colors.grey,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
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
    Uint8List? selectedImageBytes;
    String? selectedImageName;
    bool isUploadingImage = false;

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'תמונת כיסוי',
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
              onPressed: isUploadingImage ? null : () async {
                if (nameController.text.isEmpty) {
                  _showErrorSnackBar('נא למלא שם קטגוריה');
                  return;
                }

                setState(() => isUploadingImage = true);

                try {
                  String? finalImageUrl = imageUrlController.text;
                  
                  // Upload image to Supabase if selected
                  if (selectedImageBytes != null && selectedImageName != null) {
                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                    final fileName = 'category_${timestamp}_$selectedImageName';
                    
                    await _supabase.storage
                        .from('gallery')
                        .uploadBinary(
                          'categories/$fileName',
                          selectedImageBytes!,
                          fileOptions: const FileOptions(
                            contentType: 'image/jpeg',
                            upsert: true,
                          ),
                        );
                    
                    finalImageUrl = _supabase.storage
                        .from('gallery')
                        .getPublicUrl('categories/$fileName');
                  }

                  if (isEditing) {
                    await _supabase
                        .from('product_categories')
                        .update({
                          'name_he': nameController.text,
                          'description_he': descriptionController.text,
                          'cover_image_url': finalImageUrl,
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
                          'cover_image_url': finalImageUrl,
                          'is_active': isActive,
                          'sort_order': _categories.length,
                        });
                    _showSuccessSnackBar('קטגוריה נוספה בהצלחה');
                  }

                  Navigator.of(context).pop();
                  _loadCategories();
                } catch (e) {
                  _showErrorSnackBar('שגיאה בשמירת קטגוריה: $e');
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

  void _showProductDialog({Map<String, dynamic>? product}) async {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?['name_he'] ?? '');
    final descriptionController = TextEditingController(text: product?['description_he'] ?? '');
    final priceController = TextEditingController(text: product?['price']?.toString() ?? '');
    final imageUrlController = TextEditingController(text: product?['image_url'] ?? '');
    final purchaseUrlController = TextEditingController(text: product?['purchase_url'] ?? '');
    String? selectedCategoryId = product?['category_id'];
    String productType = product?['product_type'] ?? 'regular';
    Set<String> selectedSizes = <String>{};
    bool isAvailable = product?['availability'] ?? true;
    bool isActive = product?['is_active'] ?? true;
    Uint8List? selectedImageBytes;
    String? selectedImageName;
    bool isUploadingImage = false;

    // טעינת המידות הקיימות של המוצר
    if (isEditing && productType == 'clothing') {
      try {
        final sizesResponse = await _supabase
            .from('product_size_availability')
            .select('size_id')
            .eq('product_id', product!['id']);
        selectedSizes = sizesResponse.map<String>((item) => item['size_id'] as String).toSet();
      } catch (e) {
        print('Error loading existing sizes: $e');
      }
    }

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
                  
                  // סוג מוצר
                  DropdownButtonFormField<String>(
                    value: productType,
                    decoration: const InputDecoration(
                      labelText: 'סוג מוצר',
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
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'regular',
                        child: Text('מוצר רגיל'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'clothing',
                        child: Text('בגד (עם מידות)'),
                      ),
                    ],
                    onChanged: (value) => setState(() {
                      productType = value ?? 'regular';
                      if (productType == 'regular') {
                        selectedSizes.clear();
                      }
                    }),
                  ),
                  const SizedBox(height: 16),
                  
                  // מידות זמינות (רק אם זה בגד)
                  if (productType == 'clothing') ...[
                    const Text(
                      'מידות זמינות',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _sizes.isEmpty
                          ? const Text(
                              'אין מידות זמינות. אנא הוסף מידות בטאב המידות.',
                              style: TextStyle(color: Colors.white54),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _sizes.map((size) {
                                final sizeId = size['id'];
                                final isSelected = selectedSizes.contains(sizeId);
                                return FilterChip(
                                  label: Text(
                                    size['name'],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white70,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedSizes.add(sizeId);
                                      } else {
                                        selectedSizes.remove(sizeId);
                                      }
                                    });
                                  },
                                  selectedColor: const Color(0xFFE91E63),
                                  backgroundColor: const Color(0xFF2A2A2A),
                                  checkmarkColor: Colors.white,
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'תמונת המוצר',
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
              onPressed: isUploadingImage ? null : () async {
                if (nameController.text.isEmpty || 
                    priceController.text.isEmpty || 
                    selectedCategoryId == null) {
                  _showErrorSnackBar('נא למלא את כל השדות הנדרשים');
                  return;
                }

                setState(() => isUploadingImage = true);

                try {
                  final price = double.tryParse(priceController.text);
                  if (price == null) {
                    _showErrorSnackBar('מחיר לא תקין');
                    return;
                  }

                  String? finalImageUrl = imageUrlController.text;
                  
                  // Upload image to Supabase if selected
                  if (selectedImageBytes != null && selectedImageName != null) {
                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                    final fileName = 'product_${timestamp}_$selectedImageName';
                    
                    await _supabase.storage
                        .from('gallery')
                        .uploadBinary(
                          'products/$fileName',
                          selectedImageBytes!,
                          fileOptions: const FileOptions(
                            contentType: 'image/jpeg',
                            upsert: true,
                          ),
                        );
                    
                    finalImageUrl = _supabase.storage
                        .from('gallery')
                        .getPublicUrl('products/$fileName');
                  }

                  String? productId;
                  
                  if (isEditing) {
                    await _supabase
                        .from('products')
                        .update({
                          'name_he': nameController.text,
                          'description_he': descriptionController.text,
                          'price': price,
                          'category_id': selectedCategoryId,
                          'product_type': productType,
                          'image_url': finalImageUrl,
                          'purchase_url': purchaseUrlController.text,
                          'availability': isAvailable,
                          'is_active': isActive,
                          'updated_at': DateTime.now().toIso8601String(),
                        })
                        .eq('id', product['id']);
                    productId = product['id'];
                    _showSuccessSnackBar('מוצר עודכן בהצלחה');
                  } else {
                    final response = await _supabase
                        .from('products')
                        .insert({
                          'name_he': nameController.text,
                          'description_he': descriptionController.text,
                          'price': price,
                          'category_id': selectedCategoryId,
                          'product_type': productType,
                          'image_url': finalImageUrl,
                          'purchase_url': purchaseUrlController.text,
                          'availability': isAvailable,
                          'is_active': isActive,
                          'sort_order': _products.length,
                        })
                        .select()
                        .single();
                    productId = response['id'];
                    _showSuccessSnackBar('מוצר נוסף בהצלחה');
                  }

                  // שמירת המידות עבור בגדים
                  if (productType == 'clothing' && selectedSizes.isNotEmpty) {
                    // מחיקת מידות קיימות
                    if (isEditing) {
                      await _supabase
                          .from('product_size_availability')
                          .delete()
                          .eq('product_id', productId!);
                    }
                    
                    // הוספת המידות החדשות
                    final sizeData = selectedSizes.map((sizeId) => {
                      'product_id': productId,
                      'size_id': sizeId,
                      'stock_quantity': 100, // כמות ברירת מחדל
                      'is_available': true,
                    }).toList();
                    
                    try {
                      await _supabase
                          .from('product_size_availability')
                          .insert(sizeData);
                    } catch (e) {
                      print('Error saving sizes: $e');
                      // לא נכשיל את כל השמירה בגלל בעיה במידות
                    }
                  }

                  Navigator.of(context).pop();
                  _loadProducts();
                } catch (e) {
                  _showErrorSnackBar('שגיאה בשמירת מוצר: $e');
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

  Widget _buildSizesTab() {
    if (_sizes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.straighten, size: 64, color: Colors.white38),
            SizedBox(height: 16),
            Text(
              'אין מידות עדיין',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddSizeDialog,
              icon: Icon(Icons.add),
              label: Text('הוסף מידה ראשונה'),
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
      child: ListView.builder(
        itemCount: _sizes.length,
        itemBuilder: (context, index) {
          final size = _sizes[index];
          return Card(
            color: const Color(0xFF1E1E1E),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    size['name'] ?? '',
                    style: const TextStyle(
                      color: Color(0xFFE91E63),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                'מידה ${size['name']}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              subtitle: Text(
                'סדר תצוגה: ${size['display_order']}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: size['is_active'] ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      size['is_active'] ? 'פעיל' : 'לא פעיל',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showEditSizeDialog(size),
                    icon: const Icon(Icons.edit, color: Color(0xFFE91E63), size: 20),
                  ),
                  IconButton(
                    onPressed: () => _showDeleteSizeDialog(size),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddSizeDialog() {
    _showSizeDialog();
  }

  void _showEditSizeDialog(Map<String, dynamic> size) {
    _showSizeDialog(size: size);
  }

  void _showSizeDialog({Map<String, dynamic>? size}) {
    final isEditing = size != null;
    final nameController = TextEditingController(text: size?['name'] ?? '');
    final displayOrderController = TextEditingController(text: size?['display_order']?.toString() ?? '');
    bool isActive = size?['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            isEditing ? 'עריכת מידה' : 'הוספת מידה חדשה',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'שם המידה (XS, S, M, L וכו\')',
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
                  controller: displayOrderController,
                  decoration: const InputDecoration(
                    labelText: 'סדר תצוגה',
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
                Row(
                  children: [
                    Checkbox(
                      value: isActive,
                      onChanged: (value) => setState(() => isActive = value ?? true),
                      activeColor: const Color(0xFFE91E63),
                    ),
                    const Text('מידה פעילה', style: TextStyle(color: Colors.white)),
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
                if (nameController.text.isEmpty || displayOrderController.text.isEmpty) {
                  _showErrorSnackBar('נא למלא את כל השדות');
                  return;
                }

                try {
                  final displayOrder = int.tryParse(displayOrderController.text);
                  if (displayOrder == null) {
                    _showErrorSnackBar('סדר תצוגה חייב להיות מספר');
                    return;
                  }

                  if (isEditing) {
                    await _supabase
                        .from('product_sizes')
                        .update({
                          'name': nameController.text.toUpperCase(),
                          'display_order': displayOrder,
                          'is_active': isActive,
                          'updated_at': DateTime.now().toIso8601String(),
                        })
                        .eq('id', size['id']);
                    _showSuccessSnackBar('מידה עודכנה בהצלחה');
                  } else {
                    await _supabase
                        .from('product_sizes')
                        .insert({
                          'name': nameController.text.toUpperCase(),
                          'display_order': displayOrder,
                          'is_active': isActive,
                        });
                    _showSuccessSnackBar('מידה נוספה בהצלחה');
                  }

                  Navigator.of(context).pop();
                  _loadSizes();
                } catch (e) {
                  _showErrorSnackBar('שגיאה בשמירת מידה: $e');
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

  void _showDeleteSizeDialog(Map<String, dynamic> size) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('מחיקת מידה', style: TextStyle(color: Colors.white)),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את המידה "${size['name']}"?',
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
                    .from('product_sizes')
                    .delete()
                    .eq('id', size['id']);

                Navigator.of(context).pop();
                _showSuccessSnackBar('מידה נמחקה בהצלחה');
                _loadSizes();
              } catch (e) {
                Navigator.of(context).pop();
                _showErrorSnackBar('שגיאה במחיקת מידה: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }

  // Orders management functions
  final List<Map<String, String>> _statusOptions = [
    {'value': 'all', 'label': 'כל ההזמנות'},
    {'value': 'pending', 'label': 'ממתין לטיפול'},
    {'value': 'confirmed', 'label': 'אושר'},
    {'value': 'preparing', 'label': 'בהכנה'},
    {'value': 'ready', 'label': 'מוכן לאיסוף'},
    {'value': 'delivered', 'label': 'נמסר'},
    {'value': 'cancelled', 'label': 'בוטל'},
  ];

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    try {
      // קבלת הזמנות עם פרטי משתמש מ-auth.users
      final query = _supabase
          .from('orders')
          .select('''
            id, order_number, status, total_amount, notes, created_at, updated_at, user_id,
            order_items(
              id, quantity, unit_price, total_price,
              products(id, name_he, image_url),
              product_sizes(id, name)
            )
          ''');
          
      final response = _selectedStatus == 'all'
          ? await query.order('created_at', ascending: false)
          : await query.eq('status', _selectedStatus).order('created_at', ascending: false);
          
      // הוספת פרטי משתמש לכל הזמנה מטבלת user_profiles
      for (var order in response) {
        try {
          final userResponse = await _supabase
              .from('user_profiles')
              .select('display_name, phone, email, avatar_url')
              .eq('id', order['user_id'])
              .single();
          
          order['user_display_name'] = userResponse['display_name'] ?? 'משתמש לא זמין';
          order['user_phone'] = userResponse['phone'];
          order['user_email'] = userResponse['email'];
          order['user_avatar_url'] = userResponse['avatar_url'];
        } catch (e) {
          order['user_display_name'] = 'משתמש לא זמין';
          order['user_phone'] = null;
          order['user_email'] = null;
          order['user_avatar_url'] = null;
        }
      }
      
      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('שגיאה בטעינת הזמנות: $e');
    }
  }

  Widget _buildOrdersTab() {
    return Column(
      children: [
        // סינון לפי סטטוס
        Container(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'סינון לפי סטטוס',
              border: OutlineInputBorder(),
            ),
            items: _statusOptions.map((status) {
              return DropdownMenuItem<String>(
                value: status['value'],
                child: Text(status['label']!),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedStatus = value;
                });
                _loadOrders();
              }
            },
          ),
        ),
        
        // רשימת הזמנות
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE91E63)),
                )
              : _orders.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.white38),
                          SizedBox(height: 16),
                          Text(
                            'אין הזמנות',
                            style: TextStyle(color: Colors.white70, fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _buildOrderCard(order);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final userAvatarUrl = order['user_avatar_url'];
    final orderItems = order['order_items'] as List<dynamic>;
    
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(
              color: _getStatusColor(order['status']),
              width: 3,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: userAvatarUrl != null && userAvatarUrl.toString().isNotEmpty
                ? Image.network(
                    userAvatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF2A2A2A),
                      child: Text(
                        (order['user_display_name'] ?? 'U').substring(0, 1).toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: const Color(0xFF2A2A2A),
                    child: Center(
                      child: Text(
                        (order['user_display_name'] ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        title: Text(
          'הזמנה #${order['order_number']}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order['user_display_name'] ?? 'משתמש לא זמין',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(order['status']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '₪${(order['total_amount'] ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFE91E63),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // פרטי המשתמש
                _buildUserDetails(order),
                const Divider(color: Colors.white24),
                
                // פרטי ההזמנה
                _buildOrderDetails(order),
                const Divider(color: Colors.white24),
                
                // פריטי הזמנה
                const Text(
                  'פריטי הזמנה:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...orderItems.map((item) => _buildOrderItem(item)),
                
                const SizedBox(height: 16),
                // כפתורי עדכון סטטוס
                _buildStatusButtons(order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetails(Map<String, dynamic> order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'פרטי לקוח:',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'שם: ${order['user_display_name'] ?? 'לא זמין'}',
          style: const TextStyle(color: Colors.white70),
        ),
        if (order['user_phone'] != null)
          Text(
            'טלפון: ${order['user_phone']}',
            style: const TextStyle(color: Colors.white70),
          ),
        if (order['user_email'] != null)
          Text(
            'מייל: ${order['user_email']}',
            style: const TextStyle(color: Colors.white70),
          ),
      ],
    );
  }

  Widget _buildOrderDetails(Map<String, dynamic> order) {
    final createdAt = DateTime.parse(order['created_at']);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'פרטי הזמנה:',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'תאריך: ${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}',
          style: const TextStyle(color: Colors.white70),
        ),
        Text(
          'שעה: ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(color: Colors.white70),
        ),
        if (order['notes'] != null && order['notes'].toString().isNotEmpty)
          Text(
            'הערות: ${order['notes']}',
            style: const TextStyle(color: Colors.white70),
          ),
      ],
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final product = item['products'];
    final size = item['product_sizes'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // תמונת מוצר
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: product['image_url'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image, color: Colors.white54),
                    ),
                  )
                : const Icon(Icons.image, color: Colors.white54),
          ),
          
          const SizedBox(width: 12),
          
          // פרטי מוצר
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name_he'] ?? 'מוצר לא זמין',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                if (size != null)
                  Text(
                    'מידה: ${size['name']}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                Text(
                  'כמות: ${item['quantity']}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          
          // מחיר
          Text(
            '₪${(item['total_price'] ?? 0).toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFFE91E63),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButtons(Map<String, dynamic> order) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _statusOptions
          .where((status) => status['value'] != 'all')
          .map((status) => ElevatedButton(
                onPressed: order['status'] == status['value']
                    ? null
                    : () => _updateOrderStatus(order['id'], status['value']!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: order['status'] == status['value']
                      ? _getStatusColor(status['value']!)
                      : const Color(0xFF2A2A2A),
                  foregroundColor: Colors.white,
                ),
                child: Text(status['label']!),
              ))
          .toList(),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', orderId);

      _showSuccessSnackBar('סטטוס ההזמנה עודכן בהצלחה');
      _loadOrders();
    } catch (e) {
      _showErrorSnackBar('שגיאה בעדכון סטטוס ההזמנה: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'delivered':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    final statusOption = _statusOptions.firstWhere(
      (option) => option['value'] == status,
      orElse: () => {'value': status, 'label': status},
    );
    return statusOption['label']!;
  }
}