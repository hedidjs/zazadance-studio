import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../favorites/favorites_service.dart';
import '../cart/cart_service.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _availableSizes = [];
  String? _selectedSizeId;
  int _quantity = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableSizes();
    // טעינת מצב מועדפים
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);
      favoritesNotifier.loadFavoriteState('product', widget.product['id']);
    });
  }

  Future<void> _loadAvailableSizes() async {
    if (widget.product['product_type'] != 'clothing') return;
    
    try {
      final response = await _supabase
          .from('product_size_availability')
          .select('''
            id, stock_quantity, is_available,
            product_sizes(id, name, display_order)
          ''')
          .eq('product_id', widget.product['id'])
          .eq('is_available', true)
          .order('product_sizes(display_order)', ascending: true);

      if (mounted) {
        setState(() {
          _availableSizes = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print('Error loading sizes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // App Bar עם תמונת מוצר
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: const Color(0xFF1E1E1E),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // כפתור מועדפים
              Consumer(
                builder: (context, ref, child) {
                  final favoritesNotifier = ref.watch(favoritesNotifierProvider.notifier);
                  final favoriteStates = ref.watch(favoritesNotifierProvider);
                  final key = 'product_${widget.product['id']}';
                  final isFavorite = favoriteStates[key] ?? false;
                  
                  return IconButton(
                    onPressed: () async {
                      await favoritesNotifier.toggleFavorite('product', widget.product['id']);
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
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_outline,
                      color: isFavorite ? const Color(0xFFE91E63) : Colors.white,
                    ),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFF2A2A2A),
                child: widget.product['image_url'] != null
                    ? Image.network(
                        widget.product['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(Icons.store, size: 80, color: Colors.white54),
                            ),
                      )
                    : const Center(
                        child: Icon(Icons.store, size: 80, color: Colors.white54),
                      ),
              ),
            ),
          ),
          
          // תוכן המוצר
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // שם המוצר
                  Text(
                    widget.product['name_he'] ?? 'ללא שם',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // מחיר
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₪${widget.product['price']?.toString() ?? '0'}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // תיאור המוצר
                  if (widget.product['description_he']?.isNotEmpty == true) ...[
                    const Text(
                      'תיאור המוצר',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.product['description_he'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  
                  // בחירת מידות (אם זה בגד)
                  if (widget.product['product_type'] == 'clothing') ...[
                    const Text(
                      'בחירת מידה',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSizeSelector(),
                    const SizedBox(height: 24),
                  ],
                  
                  // בחירת כמות
                  const Text(
                    'כמות',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuantitySelector(),
                  const SizedBox(height: 32),
                  
                  // כפתורים - הוסף לסל ורכישה ישירה
                  Row(
                    children: [
                      // הוסף לסל
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _addToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BCD4),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
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
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_cart_outlined, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'הוסף לסל',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // קנה עכשיו
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => _buyNow(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE91E63),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'קנה עכשיו',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // הודעה על אופן ההזמנה
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00BCD4), width: 1),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF00BCD4), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ההזמנה תישלח למנהלת הסטודיו לטיפול',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // הכפתור הישן - נשמור אותו למקרה של מוצרים עם קישור חיצוני
                  if (widget.product['purchase_url']?.isNotEmpty == true) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _buyNow(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_bag, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'קנה עכשיו - ₪${widget.product['price']?.toString() ?? '0'}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // הודעה על קישור חיצוני
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE91E63), width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFE91E63), size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'הקנייה תתבצע באתר חיצוני',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ),
                          const Icon(Icons.open_in_new, color: Color(0xFFE91E63), size: 18),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelector() {
    if (_availableSizes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'אין מידות זמינות כרגע',
          style: TextStyle(color: Colors.white54),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableSizes.map((sizeData) {
        final size = sizeData['product_sizes'];
        final sizeId = size['id'];
        final sizeName = size['name'];
        final isSelected = _selectedSizeId == sizeId;
        final stockQuantity = sizeData['stock_quantity'] ?? 0;
        final isAvailable = stockQuantity > 0;

        return GestureDetector(
          onTap: isAvailable ? () {
            setState(() {
              _selectedSizeId = sizeId;
            });
          } : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFFE91E63)
                  : (isAvailable ? const Color(0xFF1E1E1E) : const Color(0xFF2A2A2A)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFFE91E63)
                    : (isAvailable ? Colors.white30 : Colors.white10),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sizeName,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white 
                        : (isAvailable ? Colors.white : Colors.white30),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAvailable ? 'במלאי: $stockQuantity' : 'אזל מהמלאי',
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white70 
                        : (isAvailable ? Colors.white54 : Colors.red),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text(
            'כמות:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          // כפתור מינוס
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _quantity > 1 ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white30),
            ),
            child: IconButton(
              onPressed: _quantity > 1 ? () {
                setState(() => _quantity--);
              } : null,
              icon: const Icon(Icons.remove, size: 18),
              color: _quantity > 1 ? Colors.white : Colors.white30,
            ),
          ),
          const SizedBox(width: 16),
          // כמות
          Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white30),
            ),
            child: Center(
              child: Text(
                '$_quantity',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // כפתור פלוס
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white30),
            ),
            child: IconButton(
              onPressed: () {
                setState(() => _quantity++);
              },
              icon: const Icon(Icons.add, size: 18),
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // מחיר כולל
          Text(
            'סה"כ: ₪${((widget.product['price'] ?? 0) * _quantity).toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFFE91E63),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart() async {
    // בדיקת תקינות
    if (widget.product['product_type'] == 'clothing' && _selectedSizeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא בחר מידה'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cartNotifier = ref.read(cartProvider.notifier);
      final success = await cartNotifier.addToCart(
        productId: widget.product['id'],
        sizeId: _selectedSizeId,
        quantity: _quantity,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product['name_he']} נוסף לסל'),
            backgroundColor: const Color(0xFF4CAF50),
            action: SnackBarAction(
              label: 'צפה בסל',
              textColor: Colors.white,
              onPressed: () {
                context.push('/cart');
              },
            ),
          ),
        );
        
        // איפוס כמות
        setState(() => _quantity = 1);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה בהוספה לסל'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _buyNow(BuildContext context) async {
    // אם יש קישור חיצוני, נשתמש בו
    final purchaseUrl = widget.product['purchase_url'];
    if (purchaseUrl != null && purchaseUrl.toString().isNotEmpty) {
      try {
        final Uri url = Uri.parse(purchaseUrl.toString());
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $purchaseUrl';
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בפתיחת קישור: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // אחרת, נוסיף לסל ונעבור להזמנה מיידית
    // בדיקת תקינות
    if (widget.product['product_type'] == 'clothing' && _selectedSizeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא בחר מידה לפני רכישה'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cartNotifier = ref.read(cartProvider.notifier);
      
      // נוסיף לסל
      final success = await cartNotifier.addToCart(
        productId: widget.product['id'],
        sizeId: _selectedSizeId,
        quantity: _quantity,
      );

      if (success && mounted) {
        // ננווט לדף הסל עם אפשרות הזמנה מיידית
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('נוסף לסל - עבור להזמנה'),
            backgroundColor: const Color(0xFF4CAF50),
            action: SnackBarAction(
              label: 'הזמן עכשיו',
              textColor: Colors.white,
              onPressed: () {
                context.push('/cart');
              },
            ),
          ),
        );
        
        setState(() => _quantity = 1);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('שגיאה בהוספה לסל'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}