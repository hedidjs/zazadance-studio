import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;

  final Map<String, String> _statusLabels = {
    'pending': 'ממתין לטיפול',
    'confirmed': 'אושר',
    'preparing': 'בהכנה',
    'ready': 'מוכן לאיסוף',
    'delivered': 'נמסר',
    'cancelled': 'בוטל',
  };

  final Map<String, Color> _statusColors = {
    'pending': Colors.orange,
    'confirmed': Colors.blue,
    'preparing': const Color(0xFF9C27B0),
    'ready': Colors.green,
    'delivered': const Color(0xFF4CAF50),
    'cancelled': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _loadMyOrders();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    // האזנה לשינויים בהזמנות שלי
    _supabase
        .channel('orders_${currentUser.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUser.id,
          ),
          callback: (payload) {
            // רענון ההזמנות כשיש שינוי
            _loadMyOrders();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      _supabase.removeChannel(_supabase.channel('orders_${currentUser.id}'));
    }
    super.dispose();
  }

  Future<void> _loadMyOrders() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      final response = await _supabase
          .from('orders')
          .select('''
            id, order_number, status, total_amount, notes, created_at, updated_at,
            order_items(
              id, quantity, unit_price, total_price,
              products(id, name_he, image_url),
              product_sizes(id, name)
            )
          ''')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);
      
      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בטעינת ההזמנות: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'ההזמנות שלי',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE91E63)),
            )
          : RefreshIndicator(
              color: const Color(0xFFE91E63),
              onRefresh: _loadMyOrders,
              child: _orders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(_orders[index]);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'אין לך הזמנות עדיין',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'כל ההזמנות שתבצע יופיעו כאן',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final statusLabel = _statusLabels[status] ?? status;
    final statusColor = _statusColors[status] ?? Colors.grey;
    final orderItems = order['order_items'] as List<dynamic>? ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          // כותרת ההזמנה
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'הזמנה #${order['order_number']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(order['created_at']),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // פריטי ההזמנה
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...orderItems.map<Widget>((item) => _buildOrderItem(item)).toList(),
                
                const Divider(color: Colors.white30),
                
                // סה"כ
                Row(
                  children: [
                    const Text(
                      'סה"כ:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₪${order['total_amount']?.toString() ?? '0'}',
                      style: const TextStyle(
                        color: Color(0xFFE91E63),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                // הערות אם קיימות
                if (order['notes'] != null && order['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'הערות:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order['notes'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final product = item['products'] as Map<String, dynamic>? ?? {};
    final size = item['product_sizes'] as Map<String, dynamic>? ?? {};
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // תמונת מוצר
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: product['image_url'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.store, color: Colors.white54),
                    ),
                  )
                : const Icon(Icons.store, color: Colors.white54),
          ),
          
          const SizedBox(width: 12),
          
          // פרטי מוצר
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name_he'] ?? 'מוצר לא זמין',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (size['name'] != null)
                  Text(
                    'מידה: ${size['name']}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'כמות: ${item['quantity']} × ₪${item['unit_price']}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // סה"כ פריט
          Text(
            '₪${item['total_price']}',
            style: const TextStyle(
              color: Color(0xFFE91E63),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}