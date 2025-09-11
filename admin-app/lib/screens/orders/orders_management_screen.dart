import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({super.key});

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String _selectedStatus = 'all';

  final List<Map<String, String>> _statusOptions = [
    {'value': 'all', 'label': 'כל ההזמנות'},
    {'value': 'pending', 'label': 'ממתין לטיפול'},
    {'value': 'confirmed', 'label': 'אושר'},
    {'value': 'preparing', 'label': 'בהכנה'},
    {'value': 'ready', 'label': 'מוכן לאיסוף'},
    {'value': 'delivered', 'label': 'נמסר'},
    {'value': 'cancelled', 'label': 'בוטל'},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    try {
      print('Loading orders... selectedStatus: $_selectedStatus'); // debug
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
          print('Error getting user data: $e');
          order['user_display_name'] = 'משתמש לא זמין';
          order['user_phone'] = null;
          order['user_email'] = null;
          order['user_avatar_url'] = null;
        }
      }
      
      print('Orders response: $response'); // debug
      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
      print('Orders loaded: ${_orders.length} items'); // debug
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading orders: $e'); // הוספת לוג לdebug
      _showErrorSnackBar('שגיאה בטעינת הזמנות: $e');
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
      body: Column(
        children: [
          // מסננים
          _buildFiltersSection(),
          
          // רשימת הזמנות
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE91E63)),
                  )
                : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(
          bottom: BorderSide(color: Colors.white10),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'סינון לפי סטטוס:',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedStatus,
            dropdownColor: const Color(0xFF2A2A2A),
            style: const TextStyle(color: Colors.white),
            items: _statusOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option['value'],
                child: Text(option['label']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedStatus = value ?? 'all');
              _loadOrders();
            },
          ),
          const Spacer(),
          Text(
            'סה"כ: ${_orders.length} הזמנות',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.white38,
            ),
            SizedBox(height: 16),
            Text(
              'אין הזמנות זמינות',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFE91E63),
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderItems = List<Map<String, dynamic>>.from(order['order_items'] ?? []);
    final totalItems = orderItems.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
    final userDisplayName = order['user_display_name'] ?? 'משתמש לא זמין';
    final userPhone = order['user_phone'];
    final userEmail = order['user_email'];
    final userAvatarUrl = order['user_avatar_url'];
    
    // Debug print to verify the buttons are being created
    print('Building order card with buttons for order: ${order['order_number']}');
    
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
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
                    width: 44,
                    height: 44,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 44,
                      height: 44,
                      color: _getStatusColor(order['status']).withOpacity(0.2),
                      child: Center(
                        child: Text(
                          userDisplayName.isNotEmpty ? userDisplayName[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: _getStatusColor(order['status']),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    color: _getStatusColor(order['status']).withOpacity(0.2),
                    child: Center(
                      child: Text(
                        userDisplayName.isNotEmpty ? userDisplayName[0].toUpperCase() : 'U',
                        style: TextStyle(
                          color: _getStatusColor(order['status']),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        title: Text(
          'הזמנה #${order['order_number']}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // שם המשתמש וטלפון
            Text(
              userDisplayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (userPhone != null && userPhone.toString().isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.phone,
                    color: Color(0xFF00BCD4),
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    userPhone.toString(),
                    style: const TextStyle(
                      color: Color(0xFF00BCD4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['status']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(order['status']),
                    style: TextStyle(
                      color: _getStatusColor(order['status']),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₪${order['total_amount']?.toString() ?? '0'}',
                  style: const TextStyle(
                    color: Color(0xFFE91E63),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$totalItems פריטים • ${_formatDate(order['created_at'])}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF00BCD4), size: 24),
              onPressed: () {
                print('Edit button pressed for order: ${order['order_number']}');
                _editOrder(order);
              },
              tooltip: 'ערוך הזמנה',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 24),
              onPressed: () {
                print('Delete button pressed for order: ${order['order_number']}');
                _deleteOrder(order['id'], order['order_number']);
              },
              tooltip: 'מחק הזמנה',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
            PopupMenuButton<String>(
              color: const Color(0xFF2A2A2A),
              onSelected: (value) => _updateOrderStatus(order['id'], value),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              itemBuilder: (context) => _statusOptions
                  .where((status) => status['value'] != 'all' && status['value'] != order['status'])
                  .map((status) => PopupMenuItem<String>(
                        value: status['value'],
                        child: Text(
                          'שנה ל${status['label']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'פריטים בהזמנה:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...orderItems.map((item) => _buildOrderItem(item)),
                if (order['notes']?.toString().isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'הערות:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order['notes'],
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
    final product = item['products'];
    final size = item['product_sizes'];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // תמונת מוצר
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: product?['image_url'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image,
                        color: Colors.white54,
                      ),
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
                  product?['name_he'] ?? 'מוצר לא זמין',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (size != null) ...[
                      Text(
                        'מידה: ${size['name']}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      'כמות: ${item['quantity']}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // מחיר
          Text(
            '₪${item['total_price']?.toString() ?? '0'}',
            style: const TextStyle(
              color: Color(0xFFE91E63),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      _showSuccessSnackBar('סטטוס ההזמנה עודכן בהצלחה');
      _loadOrders();
    } catch (e) {
      _showErrorSnackBar('שגיאה בעדכון סטטוס: $e');
    }
  }

  Future<void> _deleteOrder(String orderId, String orderNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'מחק הזמנה',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את הזמנה #$orderNumber?\nפעולה זו בלתי הפיכה.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // מחיקת פריטי ההזמנה תחילה
        await _supabase
            .from('order_items')
            .delete()
            .eq('order_id', orderId);

        // מחיקת ההזמנה
        await _supabase
            .from('orders')
            .delete()
            .eq('id', orderId);

        _showSuccessSnackBar('הזמנה #$orderNumber נמחקה בהצלחה');
        _loadOrders();
      } catch (e) {
        _showErrorSnackBar('שגיאה במחיקת הזמנה: $e');
      }
    }
  }

  void _editOrder(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => _EditOrderDialog(
        order: order,
        onOrderUpdated: _loadOrders,
        supabase: _supabase,
      ),
    );
  }

  Color _getStatusColor(String? status) {
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

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'ממתין';
      case 'confirmed':
        return 'אושר';
      case 'preparing':
        return 'בהכנה';
      case 'ready':
        return 'מוכן';
      case 'delivered':
        return 'נמסר';
      case 'cancelled':
        return 'בוטל';
      default:
        return 'לא ידוע';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

class _EditOrderDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onOrderUpdated;
  final SupabaseClient supabase;

  const _EditOrderDialog({
    required this.order,
    required this.onOrderUpdated,
    required this.supabase,
  });

  @override
  State<_EditOrderDialog> createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends State<_EditOrderDialog> {
  late List<Map<String, dynamic>> _orderItems;
  late TextEditingController _notesController;
  bool _isLoading = false;
  bool _hasChanges = false;
  List<Map<String, dynamic>> _availableProducts = [];

  @override
  void initState() {
    super.initState();
    _orderItems = List<Map<String, dynamic>>.from(widget.order['order_items'] ?? []);
    _notesController = TextEditingController(text: widget.order['notes'] ?? '');
    _loadAvailableProducts();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableProducts() async {
    try {
      final response = await widget.supabase
          .from('products')
          .select('id, name_he, price, image_url, product_type')
          .eq('is_active', true)
          .order('name_he');

      setState(() {
        _availableProducts = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  double get _totalAmount {
    return _orderItems.fold<double>(0.0, (sum, item) {
      final quantity = item['quantity'] ?? 0;
      final unitPrice = (item['unit_price'] ?? 0.0) as double;
      return sum + (quantity * unitPrice);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'עריכת הזמנה #${widget.order['order_number']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'פריטים בהזמנה:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _addNewItem,
                        icon: const Icon(Icons.add),
                        label: const Text('הוסף פריט'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: _orderItems.length,
                      itemBuilder: (context, index) {
                        return _buildOrderItemEditor(index);
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'הערות',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF00BCD4)),
                      ),
                    ),
                    onChanged: (value) => _markAsChanged(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'סה"כ:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₪${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFE91E63),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'ביטול',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasChanges && !_isLoading ? _saveChanges : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
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
                        : const Text('שמור שינויים'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemEditor(int index) {
    final item = _orderItems[index];
    final product = item['products'];
    final size = item['product_sizes'];
    
    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: product?['image_url'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image,
                          color: Colors.white54,
                        ),
                      ),
                    )
                  : const Icon(Icons.image, color: Colors.white54),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?['name_he'] ?? 'מוצר לא זמין',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (size != null)
                    Text(
                      'מידה: ${size['name']}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ),
            ),
            
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _updateQuantity(index, item['quantity'] - 1),
                  icon: const Icon(Icons.remove, color: Colors.white70, size: 16),
                ),
                Container(
                  width: 40,
                  child: Text(
                    '${item['quantity']}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () => _updateQuantity(index, item['quantity'] + 1),
                  icon: const Icon(Icons.add, color: Colors.white70, size: 16),
                ),
              ],
            ),
            
            const SizedBox(width: 12),
            
            Text(
              '₪${item['total_price']?.toString() ?? '0'}',
              style: const TextStyle(
                color: Color(0xFFE91E63),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            IconButton(
              onPressed: () => _removeItem(index),
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              tooltip: 'הסר פריט',
            ),
          ],
        ),
      ),
    );
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeItem(index);
      return;
    }
    
    setState(() {
      _orderItems[index]['quantity'] = newQuantity;
      _orderItems[index]['total_price'] = 
          newQuantity * (_orderItems[index]['unit_price'] as double);
      _markAsChanged();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
      _markAsChanged();
    });
  }

  void _addNewItem() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        availableProducts: _availableProducts,
        onItemAdded: (item) {
          setState(() {
            _orderItems.add(item);
            _markAsChanged();
          });
        },
        supabase: widget.supabase,
      ),
    );
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    
    try {
      // עדכון פרטי ההזמנה
      await widget.supabase
          .from('orders')
          .update({
            'notes': _notesController.text,
            'total_amount': _totalAmount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.order['id']);

      // מחיקת פריטי ההזמנה הקיימים
      await widget.supabase
          .from('order_items')
          .delete()
          .eq('order_id', widget.order['id']);

      // הוספת פריטי ההזמנה המעודכנים
      if (_orderItems.isNotEmpty) {
        final itemsToInsert = _orderItems.map((item) => {
          'order_id': widget.order['id'],
          'product_id': item['products']['id'],
          'size_id': item['product_sizes']?['id'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'total_price': item['total_price'],
        }).toList();

        await widget.supabase
            .from('order_items')
            .insert(itemsToInsert);
      }

      widget.onOrderUpdated();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('השינויים נשמרו בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת השינויים: $e'),
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

class _AddItemDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availableProducts;
  final Function(Map<String, dynamic>) onItemAdded;
  final SupabaseClient supabase;

  const _AddItemDialog({
    required this.availableProducts,
    required this.onItemAdded,
    required this.supabase,
  });

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  Map<String, dynamic>? _selectedProduct;
  Map<String, dynamic>? _selectedSize;
  int _quantity = 1;
  List<Map<String, dynamic>> _availableSizes = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text(
        'הוסף פריט להזמנה',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedProduct,
              decoration: const InputDecoration(
                labelText: 'בחר מוצר',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              items: widget.availableProducts.map((product) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: product,
                  child: Text(product['name_he']),
                );
              }).toList(),
              onChanged: (product) {
                setState(() {
                  _selectedProduct = product;
                  _selectedSize = null;
                });
                if (product != null && product['product_type'] == 'clothing') {
                  _loadSizesForProduct(product['id']);
                } else {
                  setState(() {
                    _availableSizes = [];
                  });
                }
              },
            ),
            
            if (_availableSizes.isNotEmpty) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedSize,
                decoration: const InputDecoration(
                  labelText: 'בחר מידה',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                items: _availableSizes.map((size) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: size,
                    child: Text(size['name']),
                  );
                }).toList(),
                onChanged: (size) {
                  setState(() {
                    _selectedSize = size;
                  });
                },
              ),
            ],
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Text(
                  'כמות:',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove, color: Colors.white70),
                ),
                Container(
                  width: 50,
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _canAddItem() ? _addItem : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BCD4),
            foregroundColor: Colors.white,
          ),
          child: const Text('הוסף'),
        ),
      ],
    );
  }

  Future<void> _loadSizesForProduct(String productId) async {
    try {
      final response = await widget.supabase
          .from('product_size_availability')
          .select('product_sizes(id, name)')
          .eq('product_id', productId);

      setState(() {
        _availableSizes = response
            .map((item) => item['product_sizes'] as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      print('Error loading sizes: $e');
    }
  }

  bool _canAddItem() {
    if (_selectedProduct == null) return false;
    if (_selectedProduct!['product_type'] == 'clothing' && _selectedSize == null) return false;
    return true;
  }

  void _addItem() {
    final unitPrice = (_selectedProduct!['price'] as num).toDouble();
    final totalPrice = unitPrice * _quantity;

    final newItem = {
      'products': _selectedProduct!,
      'product_sizes': _selectedSize,
      'quantity': _quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };

    widget.onItemAdded(newItem);
    Navigator.pop(context);
  }
}