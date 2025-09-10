import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ContactMessagesScreen extends StatefulWidget {
  const ContactMessagesScreen({super.key});

  @override
  State<ContactMessagesScreen> createState() => _ContactMessagesScreenState();
}

class _ContactMessagesScreenState extends State<ContactMessagesScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, new, read, in_progress, responded

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Debug: Check if user is authenticated
      final user = _supabase.auth.currentUser;
      print('Current user: ${user?.id}');
      print('User role: ${user?.role}');
      
      var query = _supabase.from('contact_messages').select('*');
      
      if (_selectedFilter != 'all') {
        query = query.eq('status', _selectedFilter);
      }
      
      final response = await query.order('created_at', ascending: false);
      print('Response received: ${response.length} messages');

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('שגיאה בטעינת ההודעות: $e');
      }
    }
  }

  Future<void> _updateMessageStatus(String messageId, String newStatus) async {
    try {
      await _supabase.from('contact_messages').update({
        'status': newStatus,
      }).eq('id', messageId);

      if (mounted) {
        _showSuccessSnackBar('סטטוס ההודעה עודכן בהצלחה');
        _loadMessages(); // Reload to show updated status
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('שגיאה בעדכון סטטוס ההודעה: $e');
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _supabase.from('contact_messages').delete().eq('id', messageId);

      if (mounted) {
        _showSuccessSnackBar('ההודעה נמחקה בהצלחה');
        _loadMessages(); // Reload to show updated list
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('שגיאה במחיקת ההודעה: $e');
      }
    }
  }

  void _confirmDeleteMessage(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת הודעה'),
        content: Text('האם אתה בטוח שברצונך למחוק את ההודעה מאת ${message['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteMessage(message['id']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showMessageDetails(Map<String, dynamic> message) {
    // Mark as read if it's new
    if (message['status'] == 'new') {
      _updateMessageStatus(message['id'], 'read');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message['subject'] ?? 'הודעת יצירת קשר'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('שם:', message['name']),
              _buildDetailRow('אימייל:', message['email']),
              if (message['phone'] != null) 
                _buildDetailRow('טלפון:', message['phone']),
              _buildDetailRow('תאריך:', DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(message['created_at']))),
              const SizedBox(height: 16),
              const Text(
                'הודעה:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(message['message']),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('סגור'),
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              Navigator.of(context).pop();
              if (value == 'delete') {
                _confirmDeleteMessage(message);
              } else {
                _updateMessageStatus(message['id'], value);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'new',
                child: Text('סמן כחדש'),
              ),
              const PopupMenuItem<String>(
                value: 'read',
                child: Text('סמן כנקרא'),
              ),
              const PopupMenuItem<String>(
                value: 'in_progress',
                child: Text('סמן בתהליך'),
              ),
              const PopupMenuItem<String>(
                value: 'responded',
                child: Text('סמן כמטופל'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('מחק הודעה', style: TextStyle(color: Colors.red)),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'פעולות',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.red;
      case 'read':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'responded':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'new':
        return 'חדש';
      case 'read':
        return 'נקרא';
      case 'in_progress':
        return 'בתהליך';
      case 'responded':
        return 'טופל';
      default:
        return status;
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
        title: const Text('הודעות יצירת קשר'),
        backgroundColor: Colors.blue,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
              _loadMessages();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('כל ההודעות'),
              ),
              const PopupMenuItem(
                value: 'new',
                child: Text('הודעות חדשות'),
              ),
              const PopupMenuItem(
                value: 'read',
                child: Text('הודעות שנקראו'),
              ),
              const PopupMenuItem(
                value: 'in_progress',
                child: Text('הודעות בתהליך'),
              ),
              const PopupMenuItem(
                value: 'responded',
                child: Text('הודעות שטופלו'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? const Center(
                  child: Text(
                    'אין הודעות להצגה',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMessages,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          title: Text(
                            message['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message['email']),
                              if (message['subject'] != null) 
                                Text(
                                  message['subject'],
                                  style: const TextStyle(fontStyle: FontStyle.italic),
                                ),
                              Text(
                                message['message'].length > 100
                                    ? '${message['message'].substring(0, 100)}...'
                                    : message['message'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(
                                  DateTime.parse(message['created_at']),
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(message['status']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(message['status']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () => _showMessageDetails(message),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}