import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserRequestsScreen extends ConsumerStatefulWidget {
  const UserRequestsScreen({super.key});

  @override
  ConsumerState<UserRequestsScreen> createState() => _UserRequestsScreenState();
}

class _UserRequestsScreenState extends ConsumerState<UserRequestsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    print('DEBUG: Starting to load pending requests using RPC function');
    print('DEBUG: Current user: ${_supabase.auth.currentUser?.id}');
    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: Calling get_pending_users_admin RPC function...');
      
      // Use RPC function to bypass RLS
      final response = await _supabase
          .rpc('get_pending_users_admin');
      
      print('DEBUG: RPC response: $response');
      print('DEBUG: Found ${response.length} pending users');
      
      setState(() {
        _pendingRequests = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('DEBUG: Error loading requests: $e');
      
      if (mounted) {
        _showErrorSnackBar('שגיאה בטעינת בקשות: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveUser(String userId, Map<String, dynamic> userData) async {
    try {
      print('DEBUG: Approving user $userId');
      
      // Use RPC function to bypass RLS
      final response = await _supabase.rpc('approve_user_admin', 
        params: {'user_id': userId}
      );
      
      print('DEBUG: Approve user response: $response');

      // הסרת הבקשה מהרשימה
      setState(() {
        _pendingRequests.removeWhere((request) => request['id'] == userId);
      });

      _showSuccessSnackBar('המשתמש ${userData['full_name']} אושר בהצלחה!');
    } catch (e) {
      print('DEBUG: Error approving user: $e');
      _showErrorSnackBar('שגיאה באישור המשתמש: $e');
    }
  }

  Future<void> _rejectUser(String userId, Map<String, dynamic> userData) async {
    try {
      print('DEBUG: Starting to reject user $userId');
      
      // מחיקה מטבלת users
      await _supabase.from('users').delete().eq('id', userId);
      print('DEBUG: Deleted user from users table');
      
      // מחיקה מטבלת auth.users באמצעות admin API
      await _supabase.auth.admin.deleteUser(userId);
      print('DEBUG: Deleted user from auth.users table');

      // הסרת הבקשה מהרשימה
      setState(() {
        _pendingRequests.removeWhere((request) => request['id'] == userId);
      });

      _showSuccessSnackBar('המשתמש ${userData['full_name']} נמחק מהמערכת');
    } catch (e) {
      print('DEBUG: Error rejecting user: $e');
      _showErrorSnackBar('שגיאה במחיקת המשתמש: $e');
    }
  }

  void _showUserDetailsDialog(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // כותרת עם תמונת פרופיל
                  Row(
                    children: [
                      // תמונת פרופיל
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF00BCD4),
                            width: 2,
                          ),
                        ),
                        child: userData['profile_image_url'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: CachedNetworkImage(
                                  imageUrl: userData['profile_image_url'],
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E2E2E),
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white54,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E2E2E),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white54,
                                  size: 30,
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData['full_name'] ?? 'לא צוין',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '@${userData['username'] ?? 'לא צוין'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF00BCD4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // פרטי המשתמש
                  _buildDetailRow('אימייל', userData['email'] ?? 'לא צוין'),
                  _buildDetailRow('טלפון', userData['phone'] ?? 'לא צוין'),
                  _buildDetailRow('כתובת', userData['address'] ?? 'לא צוין'),
                  _buildDetailRow('סוג משתמש', _getUserTypeText(userData['user_type'])),
                  
                  if (userData['user_type'] == 'parent' && userData['student_name'] != null)
                    _buildDetailRow('שם התלמיד', userData['student_name']),
                  
                  if (userData['user_type'] == 'student' && userData['parent_name'] != null)
                    _buildDetailRow('שם ההורה', userData['parent_name']),
                  
                  _buildDetailRow('תאריך בקשה', _formatDate(userData['requested_at'])),
                  
                  const SizedBox(height: 32),
                  
                  // כפתורי פעולה
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _rejectUser(userData['id'], userData);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('דחה'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _approveUser(userData['id'], userData);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('אשר'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getUserTypeText(String? userType) {
    switch (userType) {
      case 'parent':
        return 'הורה';
      case 'student':
        return 'תלמיד';
      default:
        return 'לא צוין';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'לא צוין';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm', 'he').format(date);
    } catch (e) {
      return 'תאריך לא תקין';
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            const Icon(
              Icons.person_add_outlined,
              color: Color(0xFF00BCD4),
            ),
            const SizedBox(width: 8),
            const Text(
              'בקשות הצטרפות משתמשים',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _pendingRequests.isNotEmpty 
                    ? const Color(0xFFE91E63)
                    : Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_pendingRequests.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadPendingRequests,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            tooltip: 'רענן',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPendingRequests,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00BCD4),
                ),
              )
            : _pendingRequests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 64,
                                color: Colors.green,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'אין בקשות ממתינות',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'כל הבקשות טופלו',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingRequests.length,
                    itemBuilder: (context, index) {
                      final request = _pendingRequests[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: const Color(0xFF1E1E1E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _showUserDetailsDialog(request),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // תמונת פרופיל
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: const Color(0xFF00BCD4),
                                      width: 2,
                                    ),
                                  ),
                                  child: request['profile_image_url'] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(23),
                                          child: CachedNetworkImage(
                                            imageUrl: request['profile_image_url'],
                                            width: 46,
                                            height: 46,
                                            fit: BoxFit.cover,
                                            errorWidget: (context, url, error) => Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2E2E2E),
                                                borderRadius: BorderRadius.circular(23),
                                              ),
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.white54,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2E2E2E),
                                            borderRadius: BorderRadius.circular(23),
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.white54,
                                            size: 24,
                                          ),
                                        ),
                                ),
                                
                                const SizedBox(width: 16),
                                
                                // פרטי המשתמש
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        request['full_name'] ?? 'לא צוין',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '@${request['username'] ?? 'לא צוין'}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF00BCD4),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: request['user_type'] == 'parent'
                                                  ? Colors.purple.withOpacity(0.2)
                                                  : Colors.blue.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: request['user_type'] == 'parent'
                                                    ? Colors.purple
                                                    : Colors.blue,
                                              ),
                                            ),
                                            child: Text(
                                              _getUserTypeText(request['user_type']),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: request['user_type'] == 'parent'
                                                    ? Colors.purple
                                                    : Colors.blue,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        request['email'] ?? 'לא צוין',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'נשלח: ${_formatDate(request['requested_at'])}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // כפתורי פעולה
                                Column(
                                  children: [
                                    IconButton(
                                      onPressed: () => _approveUser(request['id'], request),
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                      tooltip: 'אשר',
                                    ),
                                    IconButton(
                                      onPressed: () => _rejectUser(request['id'], request),
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                      ),
                                      tooltip: 'דחה',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}