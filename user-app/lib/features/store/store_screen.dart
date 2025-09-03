import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'product_detail_screen.dart';
import '../favorites/favorites_service.dart';
import '../cart/cart_service.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  String? _selectedCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
    
    // טעינת סל הקניות
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartProvider.notifier).loadCart();
    });
  }

  Future<void> _loadStoreData() async {
    try {
      setState(() => _isLoading = true);

      // טעינת קטגוריות מוצרים
      final categoriesResponse = await _supabase
          .from('product_categories')
          .select('*')
          .eq('is_active', true)
          .order('sort_order');

      // טעינת מוצרים
      final productsResponse = await _supabase
          .from('products')
          .select('*')
          .eq('is_active', true)
          .eq('availability', true)
          .order('sort_order');

      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(categoriesResponse);
          _products = List<Map<String, dynamic>>.from(productsResponse);
          _isLoading = false;
        });
        
        // טעינת מצב מועדפים לכל המוצרים
        final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);
        for (final product in _products) {
          favoritesNotifier.loadFavoriteState('product', product['id']);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת החנות: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategoryId == null) return _products;
    return _products.where((product) => 
      product['category_id'] == _selectedCategoryId
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'חנות',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          // כפתור ההזמנות שלי
          IconButton(
            onPressed: () {
              context.push('/my-orders');
            },
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            tooltip: 'ההזמנות שלי',
          ),
          
          // כפתור סל קניות
          Consumer(
            builder: (context, ref, child) {
              final cartItemsCount = ref.watch(cartTotalItemsProvider);
              
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      context.push('/cart');
                    },
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  ),
                  if (cartItemsCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          cartItemsCount > 99 ? '99+' : cartItemsCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE91E63)),
            )
          : RefreshIndicator(
              color: const Color(0xFFE91E63),
              onRefresh: _loadStoreData,
              child: Column(
                children: [
                  // קטגוריות
                  if (_categories.isNotEmpty) _buildCategoriesSection(),
                  
                  // רשימת מוצרים
                  Expanded(child: _buildProductsList()),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCategoryChip(
              name: 'הכל',
              isSelected: _selectedCategoryId == null,
              onTap: () => setState(() => _selectedCategoryId = null),
            );
          }
          
          final category = _categories[index - 1];
          final isSelected = _selectedCategoryId == category['id'];
          
          return _buildCategoryChip(
            name: category['name_he'] ?? '',
            isSelected: isSelected,
            onTap: () => setState(() => _selectedCategoryId = category['id']),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE91E63) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE91E63), width: 1.5),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFE91E63),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    final filteredProducts = _filteredProducts;
    
    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _selectedCategoryId != null 
                  ? 'אין מוצרים בקטגוריה זו'
                  : 'אין מוצרים זמינים',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // תמונת מוצר
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: product['image_url'] != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.network(
                              product['image_url'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.store, size: 40, color: Colors.white54),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.store, size: 40, color: Colors.white54),
                          ),
                  ),
                  
                  // כפתור מועדפים
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final favoritesNotifier = ref.watch(favoritesNotifierProvider.notifier);
                        final favoriteStates = ref.watch(favoritesNotifierProvider);
                        final key = 'product_${product['id']}';
                        final isFavorite = favoriteStates[key] ?? false;
                        
                        return GestureDetector(
                          onTap: () async {
                            await favoritesNotifier.toggleFavorite('product', product['id']);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isFavorite 
                                      ? 'הוסר מהמועדפים' 
                                      : 'נוסף למועדפים'),
                                  backgroundColor: const Color(0xFF4CAF50),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              isFavorite ? Icons.star : Icons.star_outline,
                              color: isFavorite ? const Color(0xFFE91E63) : Colors.white,
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // פרטי מוצר
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name_he'] ?? 'ללא שם',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    Text(
                      '₪${product['price']?.toString() ?? '0'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}