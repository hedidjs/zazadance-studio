import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupRealtimeListener();
  }

  void _setupRealtimeListener() {
    _supabase
        .channel('admin_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'admin_notifications',
          callback: (payload) {
            print('New notification received: ${payload.newRecord}');
            _loadNotifications();
          },
        )
        .subscribe();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var query = _supabase.from('admin_notifications').select('*');
      
      if (_selectedFilter == 'unread') {
        query = query.eq('is_read', false);
      } else if (_selectedFilter == 'read') {
        query = query.eq('is_read', true);
      }
      
      final response = await query.order('created_at', ascending: false);
      print('Notifications loaded: ${response.length}');

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('שגיאה בטעינת ההתראות: $e');
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _supabase.from('admin_notifications').update({
        'is_read': true,
      }).eq('id', notificationId);

      if (mounted) {
        _loadNotifications();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      if (mounted) {
        _showErrorSnackBar('שגיאה בסימון ההתראה כנקראה: $e');
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _supabase.from('admin_notifications').update({
        'is_read': true,
      }).eq('is_read', false);

      if (mounted) {
        _showSuccessSnackBar('כל ההתראות סומנו כנקראות');
        _loadNotifications();
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      if (mounted) {
        _showErrorSnackBar('שגיאה בסימון כל ההתראות כנקראות: $e');
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _supabase.from('admin_notifications').delete().eq('id', notificationId);

      if (mounted) {
        _showSuccessSnackBar('ההתראה נמחקה בהצלחה');
        _loadNotifications();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('שגיאה במחיקת ההתראה: $e');
      }
    }
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    // Mark as read if it's unread
    if (!notification['is_read']) {
      _markAsRead(notification['id']);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notification['message'],
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (notification['data'] != null) ...[
                const Text(
                  'פרטים נוספים:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatNotificationData(notification['data']),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'תאריך: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(notification['created_at']))}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('סגור'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteNotification(notification['id']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }

  String _formatNotificationData(dynamic data) {
    if (data == null) return '';
    
    final Map<String, dynamic> dataMap = Map<String, dynamic>.from(data);
    final StringBuffer buffer = StringBuffer();
    
    dataMap.forEach((key, value) {
      if (value != null) {
        String formattedKey = _getHebrewKeyName(key);
        String formattedValue = _formatValue(key, value);
        buffer.writeln('$formattedKey: $formattedValue');
      }
    });
    
    return buffer.toString().trim();
  }

  String _getHebrewKeyName(String key) {
    switch (key) {
      case 'user_id':
        return 'מזהה משתמש';
      case 'user_email':
        return 'כתובת מייל';
      case 'order_id':
        return 'מזהה הזמנה';
      case 'order_number':
        return 'מספר הזמנה';
      case 'total_amount':
        return 'סכום כולל';
      case 'items_count':
        return 'כמות פריטים';
      case 'status':
        return 'סטטוס';
      case 'created_at':
        return 'תאריך יצירה';
      case 'name':
        return 'שם';
      case 'email':
        return 'מייל';
      case 'phone':
        return 'טלפון';
      case 'subject':
        return 'נושא';
      case 'message':
        return 'הודעה';
      case 'message_id':
        return 'מזהה הודעה';
      case 'like_id':
        return 'מזהה לייק';
      case 'content_type':
        return 'סוג תוכן';
      case 'content_id':
        return 'מזהה תוכן';
      case 'deleted_at':
        return 'תאריך מחיקה';
      default:
        return key;
    }
  }

  String _formatValue(String key, dynamic value) {
    if (value == null) return '';
    
    switch (key) {
      case 'total_amount':
        return '₪$value';
      case 'status':
        return _getHebrewStatus(value.toString());
      case 'created_at':
      case 'deleted_at':
        try {
          final date = DateTime.parse(value.toString());
          return DateFormat('dd/MM/yyyy HH:mm').format(date);
        } catch (e) {
          return value.toString();
        }
      default:
        return value.toString();
    }
  }

  String _getHebrewStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'ממתין';
      case 'completed':
        return 'הושלם';
      case 'cancelled':
        return 'בוטל';
      case 'processing':
        return 'בטיפול';
      case 'new':
        return 'חדש';
      case 'read':
        return 'נקרא';
      case 'unread':
        return 'לא נקרא';
      default:
        return status;
    }
  }

  Color _getNotificationTypeColor(String type) {
    switch (type) {
      case 'new_user':
        return Colors.green;
      case 'new_like':
        return Colors.pink;
      case 'new_contact_message':
        return Colors.blue;
      case 'new_order':
        return Colors.orange;
      case 'user_deleted':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationTypeIcon(String type) {
    switch (type) {
      case 'new_user':
        return Icons.person_add;
      case 'new_like':
        return Icons.favorite;
      case 'new_contact_message':
        return Icons.message;
      case 'new_order':
        return Icons.shopping_cart;
      case 'user_deleted':
        return Icons.person_remove;
      default:
        return Icons.notifications;
    }
  }

  String _getNotificationTypeText(String type) {
    switch (type) {
      case 'new_user':
        return 'משתמש חדש';
      case 'new_like':
        return 'לייק חדש';
      case 'new_contact_message':
        return 'הודעת קשר';
      case 'new_order':
        return 'הזמנה חדשה';
      case 'user_deleted':
        return 'משתמש נמחק';
      default:
        return 'התראה';
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('התראות'),
        backgroundColor: Colors.purple,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark_all_read') {
                _markAllAsRead();
              } else {
                setState(() {
                  _selectedFilter = value;
                });
                _loadNotifications();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, color: Colors.green),
                    SizedBox(width: 8),
                    Text('סמן הכל כנקרא'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'all',
                child: Text('כל ההתראות'),
              ),
              const PopupMenuItem(
                value: 'unread',
                child: Text('לא נקראו'),
              ),
              const PopupMenuItem(
                value: 'read',
                child: Text('נקראו'),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'אין התראות להצגה',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isUnread = !notification['is_read'];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isUnread ? 4 : 2,
                        color: isUnread ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getNotificationTypeColor(notification['notification_type']),
                            child: Icon(
                              _getNotificationTypeIcon(notification['notification_type']),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              if (isUnread) ...[
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  notification['title'],
                                  style: TextStyle(
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification['message'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getNotificationTypeColor(notification['notification_type']),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getNotificationTypeText(notification['notification_type']),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat('dd/MM HH:mm').format(
                                      DateTime.parse(notification['created_at']),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => _showNotificationDetails(notification),
                          trailing: isUnread 
                              ? IconButton(
                                  icon: const Icon(Icons.mark_email_read, color: Colors.blue),
                                  onPressed: () => _markAsRead(notification['id']),
                                  tooltip: 'סמן כנקרא',
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _supabase.removeAllChannels();
    super.dispose();
  }
}