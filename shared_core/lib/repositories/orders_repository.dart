import '../models/order.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../exceptions/app_exceptions.dart';

/// Result class for order operations
class OrderOperationResult {
  final bool success;
  final String? errorMessage;
  final Order? order;
  final List<Order>? orders;

  const OrderOperationResult({
    required this.success,
    this.errorMessage,
    this.order,
    this.orders,
  });

  factory OrderOperationResult.success({
    Order? order,
    List<Order>? orders,
  }) {
    return OrderOperationResult(
      success: true,
      order: order,
      orders: orders,
    );
  }

  factory OrderOperationResult.failure(String errorMessage) {
    return OrderOperationResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// Abstract interface for orders data access
abstract class OrdersRepository {
  Future<OrderOperationResult> getOrders({
    int limit = 50,
    int offset = 0,
    OrderStatus? statusFilter,
    String? searchQuery,
  });
  Future<OrderOperationResult> getOrder(String orderId);
  Future<OrderOperationResult> updateOrderStatus(String orderId, OrderStatus newStatus);
  Future<OrderOperationResult> updateOrderNotes(String orderId, String notes);
  Future<int> getTotalOrdersCount({OrderStatus? statusFilter});
}

/// Supabase implementation of OrdersRepository - OPTIMIZED VERSION
class SupabaseOrdersRepository implements OrdersRepository {
  static const String _tableName = 'orders';

  /// Get orders with ALL related data in ONE QUERY (eliminates N+1)
  @override
  Future<OrderOperationResult> getOrders({
    int limit = 50,
    int offset = 0,
    OrderStatus? statusFilter,
    String? searchQuery,
  }) async {
    try {
      // Single optimized query with all JOINs - NO MORE N+1 PROBLEM!
      var query = Supabase.instance.client
          .from(_tableName)
          .select('''
            id, order_number, user_id, status, total_amount, notes, created_at, updated_at,
            user_profiles!inner(display_name, phone, email, avatar_url),
            order_items(
              id, quantity, unit_price, total_price,
              products(id, name_he, name_en, image_url, product_type),
              product_sizes(id, name)
            )
          ''');

      // Apply filters
      if (statusFilter != null) {
        query = query.eq('status', statusFilter.value);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        // Search in order number or customer name
        query = query.or('order_number.ilike.%$searchQuery%,'
                        'user_profiles.display_name.ilike.%$searchQuery%');
      }

      // Apply pagination and ordering
      final response = await query
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      final orders = response
          .map<Order>((orderData) => Order.fromJson(orderData))
          .toList();

      return OrderOperationResult.success(orders: orders);
    } catch (e) {
      return OrderOperationResult.failure('Failed to load orders: ${e.toString()}');
    }
  }

  @override
  Future<OrderOperationResult> getOrder(String orderId) async {
    try {
      final response = await Supabase.instance.client
          .from(_tableName)
          .select('''
            id, order_number, user_id, status, total_amount, notes, created_at, updated_at,
            user_profiles!inner(display_name, phone, email, avatar_url),
            order_items(
              id, quantity, unit_price, total_price,
              products(id, name_he, name_en, image_url, product_type),
              product_sizes(id, name)
            )
          ''')
          .eq('id', orderId)
          .single();

      final order = Order.fromJson(response);
      return OrderOperationResult.success(order: order);
    } catch (e) {
      return OrderOperationResult.failure('Failed to load order: ${e.toString()}');
    }
  }

  @override
  Future<OrderOperationResult> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final response = await Supabase.instance.client
          .from(_tableName)
          .update({
            'status': newStatus.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select('''
            id, order_number, user_id, status, total_amount, notes, created_at, updated_at,
            user_profiles!inner(display_name, phone, email, avatar_url),
            order_items(
              id, quantity, unit_price, total_price,
              products(id, name_he, name_en, image_url, product_type),
              product_sizes(id, name)
            )
          ''');

      if (response.isNotEmpty) {
        final order = Order.fromJson(response.first);
        return OrderOperationResult.success(order: order);
      } else {
        return OrderOperationResult.failure('Order not found');
      }
    } catch (e) {
      return OrderOperationResult.failure('Failed to update order status: ${e.toString()}');
    }
  }

  @override
  Future<OrderOperationResult> updateOrderNotes(String orderId, String notes) async {
    try {
      final response = await Supabase.instance.client
          .from(_tableName)
          .update({
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select('''
            id, order_number, user_id, status, total_amount, notes, created_at, updated_at,
            user_profiles!inner(display_name, phone, email, avatar_url),
            order_items(
              id, quantity, unit_price, total_price,
              products(id, name_he, name_en, image_url, product_type),
              product_sizes(id, name)
            )
          ''');

      if (response.isNotEmpty) {
        final order = Order.fromJson(response.first);
        return OrderOperationResult.success(order: order);
      } else {
        return OrderOperationResult.failure('Order not found');
      }
    } catch (e) {
      return OrderOperationResult.failure('Failed to update order notes: ${e.toString()}');
    }
  }

  @override
  Future<int> getTotalOrdersCount({OrderStatus? statusFilter}) async {
    try {
      var query = Supabase.instance.client
          .from(_tableName)
          .select('id', const FetchOptions(count: CountOption.exact));

      if (statusFilter != null) {
        query = query.eq('status', statusFilter.value);
      }

      final response = await query;
      return response.count ?? 0;
    } catch (e) {
      throw DatabaseException('Failed to get orders count: ${e.toString()}');
    }
  }

  /// Get order statistics (for dashboard)
  Future<Map<String, int>> getOrderStatistics() async {
    try {
      final response = await Supabase.instance.client
          .rpc('get_order_statistics'); // This function should be created in database

      return Map<String, int>.from(response);
    } catch (e) {
      // Fallback to individual queries if RPC function doesn't exist
      final stats = <String, int>{};
      for (final status in OrderStatus.values) {
        stats[status.value] = await getTotalOrdersCount(statusFilter: status);
      }
      return stats;
    }
  }
}