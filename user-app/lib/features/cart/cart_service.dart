import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartItem {
  final String id;
  final String productId;
  final String? sizeId;
  final int quantity;
  final Map<String, dynamic> product;
  final Map<String, dynamic>? size;

  CartItem({
    required this.id,
    required this.productId,
    this.sizeId,
    required this.quantity,
    required this.product,
    this.size,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['product_id'],
      sizeId: json['size_id'],
      quantity: json['quantity'] ?? 1,
      product: json['products'] ?? {},
      size: json['product_sizes'],
    );
  }

  double get totalPrice {
    final price = (product['price'] ?? 0).toDouble();
    return price * quantity;
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  final SupabaseClient _supabase;
  
  CartNotifier(this._supabase) : super([]);

  Future<void> loadCart() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('cart_items')
          .select('''
            id, product_id, size_id, quantity,
            products(id, name_he, price, image_url, product_type),
            product_sizes(id, name)
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      state = response.map<CartItem>((item) => CartItem.fromJson(item)).toList();
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  Future<bool> addToCart({
    required String productId,
    String? sizeId,
    int quantity = 1,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // בדוק אם הפריט כבר קיים בסל
      final existingItemIndex = state.indexWhere((item) => 
          item.productId == productId && item.sizeId == sizeId);

      if (existingItemIndex != -1) {
        // עדכן כמות של פריט קיים
        await _updateCartItemQuantity(
          state[existingItemIndex].id, 
          state[existingItemIndex].quantity + quantity
        );
      } else {
        // הוסף פריט חדש
        await _supabase.from('cart_items').insert({
          'user_id': user.id,
          'product_id': productId,
          'size_id': sizeId,
          'quantity': quantity,
        });
      }

      await loadCart();
      return true;
    } catch (e) {
      print('Error adding to cart: $e');
      return false;
    }
  }

  Future<bool> updateCartItemQuantity(String itemId, int newQuantity) async {
    if (newQuantity <= 0) {
      return removeFromCart(itemId);
    }

    return _updateCartItemQuantity(itemId, newQuantity);
  }

  Future<bool> _updateCartItemQuantity(String itemId, int newQuantity) async {
    try {
      await _supabase
          .from('cart_items')
          .update({'quantity': newQuantity})
          .eq('id', itemId);

      await loadCart();
      return true;
    } catch (e) {
      print('Error updating cart item: $e');
      return false;
    }
  }

  Future<bool> removeFromCart(String itemId) async {
    try {
      await _supabase
          .from('cart_items')
          .delete()
          .eq('id', itemId);

      await loadCart();
      return true;
    } catch (e) {
      print('Error removing from cart: $e');
      return false;
    }
  }

  Future<bool> clearCart() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('cart_items')
          .delete()
          .eq('user_id', user.id);

      state = [];
      return true;
    } catch (e) {
      print('Error clearing cart: $e');
      return false;
    }
  }

  int get totalItems {
    return state.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  double get totalAmount {
    return state.fold<double>(0, (sum, item) => sum + item.totalPrice);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier(Supabase.instance.client);
});

final cartTotalItemsProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold<int>(0, (sum, item) => sum + item.quantity);
});

final cartTotalAmountProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold<double>(0, (sum, item) => sum + item.totalPrice);
});