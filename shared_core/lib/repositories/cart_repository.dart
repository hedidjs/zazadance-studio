import '../models/cart_item.dart';
import '../services/supabase_service.dart';
import '../exceptions/app_exceptions.dart';

/// Result class for cart operations
class CartOperationResult {
  final bool success;
  final String? errorMessage;
  final CartItem? cartItem;
  final List<CartItem>? cartItems;

  const CartOperationResult({
    required this.success,
    this.errorMessage,
    this.cartItem,
    this.cartItems,
  });

  factory CartOperationResult.success({
    CartItem? cartItem,
    List<CartItem>? cartItems,
  }) {
    return CartOperationResult(
      success: true,
      cartItem: cartItem,
      cartItems: cartItems,
    );
  }

  factory CartOperationResult.failure(String errorMessage) {
    return CartOperationResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// Abstract interface for cart data access
abstract class CartRepository {
  Future<CartOperationResult> getCartItems(String userId);
  Future<CartOperationResult> addToCart({
    required String userId,
    required String productId,
    String? sizeId,
    int quantity = 1,
  });
  Future<CartOperationResult> updateCartItemQuantity({
    required String cartItemId,
    required int newQuantity,
  });
  Future<CartOperationResult> removeFromCart(String cartItemId);
  Future<CartOperationResult> clearCart(String userId);
  Future<int> getTotalItems(String userId);
  Future<double> getTotalAmount(String userId);
}

/// Supabase implementation of CartRepository
class SupabaseCartRepository implements CartRepository {
  static const String _tableName = 'cart_items';

  @override
  Future<CartOperationResult> getCartItems(String userId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select('''
            id, product_id, size_id, quantity, created_at, updated_at,
            products(id, name_he, name_en, price, image_url, product_type),
            product_sizes(id, name)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final cartItems = response
          .map<CartItem>((item) => CartItem.fromJson(item))
          .toList();

      return CartOperationResult.success(cartItems: cartItems);
    } catch (e) {
      return CartOperationResult.failure('Failed to load cart items: ${e.toString()}');
    }
  }

  @override
  Future<CartOperationResult> addToCart({
    required String userId,
    required String productId,
    String? sizeId,
    int quantity = 1,
  }) async {
    try {
      // Check if item already exists in cart
      final existingItems = await SupabaseService.client
          .from(_tableName)
          .select('id, quantity')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .eq('size_id', sizeId ?? '');

      if (existingItems.isNotEmpty) {
        // Update existing item quantity
        final existingItem = existingItems.first;
        final newQuantity = (existingItem['quantity'] as int) + quantity;
        
        return await updateCartItemQuantity(
          cartItemId: existingItem['id'],
          newQuantity: newQuantity,
        );
      } else {
        // Add new item
        final response = await SupabaseService.client
            .from(_tableName)
            .insert({
              'user_id': userId,
              'product_id': productId,
              'size_id': sizeId,
              'quantity': quantity,
            })
            .select('''
              id, product_id, size_id, quantity, created_at, updated_at,
              products(id, name_he, name_en, price, image_url, product_type),
              product_sizes(id, name)
            ''');

        if (response.isNotEmpty) {
          final cartItem = CartItem.fromJson(response.first);
          return CartOperationResult.success(cartItem: cartItem);
        } else {
          return CartOperationResult.failure('Failed to add item to cart');
        }
      }
    } catch (e) {
      return CartOperationResult.failure('Failed to add to cart: ${e.toString()}');
    }
  }

  @override
  Future<CartOperationResult> updateCartItemQuantity({
    required String cartItemId,
    required int newQuantity,
  }) async {
    try {
      if (newQuantity <= 0) {
        return await removeFromCart(cartItemId);
      }

      final response = await SupabaseService.client
          .from(_tableName)
          .update({'quantity': newQuantity})
          .eq('id', cartItemId)
          .select('''
            id, product_id, size_id, quantity, created_at, updated_at,
            products(id, name_he, name_en, price, image_url, product_type),
            product_sizes(id, name)
          ''');

      if (response.isNotEmpty) {
        final cartItem = CartItem.fromJson(response.first);
        return CartOperationResult.success(cartItem: cartItem);
      } else {
        return CartOperationResult.failure('Cart item not found');
      }
    } catch (e) {
      return CartOperationResult.failure('Failed to update cart item: ${e.toString()}');
    }
  }

  @override
  Future<CartOperationResult> removeFromCart(String cartItemId) async {
    try {
      await SupabaseService.client
          .from(_tableName)
          .delete()
          .eq('id', cartItemId);

      return CartOperationResult.success();
    } catch (e) {
      return CartOperationResult.failure('Failed to remove from cart: ${e.toString()}');
    }
  }

  @override
  Future<CartOperationResult> clearCart(String userId) async {
    try {
      await SupabaseService.client
          .from(_tableName)
          .delete()
          .eq('user_id', userId);

      return CartOperationResult.success();
    } catch (e) {
      return CartOperationResult.failure('Failed to clear cart: ${e.toString()}');
    }
  }

  @override
  Future<int> getTotalItems(String userId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select('quantity')
          .eq('user_id', userId);

      return response.fold<int>(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      );
    } catch (e) {
      throw DatabaseException('Failed to get total items: ${e.toString()}');
    }
  }

  @override
  Future<double> getTotalAmount(String userId) async {
    try {
      final response = await SupabaseService.client
          .from(_tableName)
          .select('''
            quantity,
            products(price)
          ''')
          .eq('user_id', userId);

      return response.fold<double>(
        0.0,
        (sum, item) {
          final quantity = (item['quantity'] as int).toDouble();
          final price = ((item['products'] as Map)['price'] ?? 0).toDouble();
          return sum + (quantity * price);
        },
      );
    } catch (e) {
      throw DatabaseException('Failed to get total amount: ${e.toString()}');
    }
  }
}