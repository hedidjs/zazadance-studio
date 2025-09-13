import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  ConsumerState<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterRole = 'all';
  

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      
      print('DEBUG: Loading all users using RPC function...');
      
      // Use admin RPC function to bypass RLS and get all users
      final response = await _supabase.rpc('get_all_users_admin');
      
      print('DEBUG: RPC response: $response');
      print('DEBUG: Found ${response.length} total users');

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Error loading users: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('שגיאה בטעינת המשתמשים: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    var filtered = _users;
    
    // Filter by role
    if (_filterRole != 'all') {
      filtered = filtered.where((user) => user['role'] == _filterRole).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final email = user['email']?.toString().toLowerCase() ?? '';
        final displayName = user['display_name']?.toString().toLowerCase() ?? '';
        final fullName = user['full_name']?.toString().toLowerCase() ?? '';
        final phone = user['phone']?.toString() ?? '';
        
        return email.contains(_searchQuery.toLowerCase()) ||
               displayName.contains(_searchQuery.toLowerCase()) ||
               fullName.contains(_searchQuery.toLowerCase()) ||
               phone.contains(_searchQuery);
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          // Header with controls
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1E1E1E),
            child: Column(
              children: [
                // Title and Add button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '👥 ניהול משתמשים',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showAddUserDialog(),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'הוסף משתמש',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _loadUsers,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          tooltip: 'רענן',
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Search and Filter
                Row(
                  children: [
                    // Search bar
                    Expanded(
                      flex: 2,
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'חיפוש משתמשים...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(Icons.search, color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Role filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterRole,
                        onChanged: (value) => setState(() => _filterRole = value!),
                        dropdownColor: const Color(0xFF2A2A2A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('כל התפקידים')),
                          DropdownMenuItem(value: 'admin', child: Text('מנהלים')),
                          DropdownMenuItem(value: 'instructor', child: Text('מדריכים')),
                          DropdownMenuItem(value: 'parent', child: Text('הורים')),
                          DropdownMenuItem(value: 'student', child: Text('תלמידים')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Stats row
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                _buildStatCard('סה"כ משתמשים', _users.length.toString(), Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard('פעילים', _users.where((u) => u['is_active'] == true).length.toString(), Colors.green),
                const SizedBox(width: 16),
                _buildStatCard('לא פעילים', _users.where((u) => u['is_active'] == false).length.toString(), Colors.red),
                const SizedBox(width: 16),
                _buildStatCard('מנהלים', _users.where((u) => u['role'] == 'admin').length.toString(), Colors.purple),
              ],
            ),
          ),
          
          // Users table/list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2196F3)),
                  )
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'לא נמצאו משתמשים',
                          style: TextStyle(color: Colors.white54, fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return _buildUserCard(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role'] ?? 'student';
    final isActive = user['is_active'] ?? true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundColor: _getRoleColor(role),
              child: Text(
                _getRoleIcon(role),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['display_name'] ?? user['email'] ?? 'לא ידוע',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['email'] ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (user['phone'] != null && user['phone'].toString().isNotEmpty)
                    Text(
                      user['phone'],
                      style: const TextStyle(color: Colors.white54),
                    ),
                ],
              ),
            ),
            
            // Role, status, and auth provider chips
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildRoleChip(role),
                const SizedBox(height: 4),
                _buildStatusChip(isActive),
                if (user['auth_provider'] == 'google') ...[
                  const SizedBox(height: 4),
                  _buildAuthProviderChip('google'),
                ],
              ],
            ),
            
            const SizedBox(width: 16),
            
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF2196F3)),
                  onPressed: () => _showEditUserDialog(user),
                  tooltip: 'ערוך משתמש',
                ),
                IconButton(
                  icon: Icon(
                    isActive ? Icons.block : Icons.check_circle,
                    color: isActive ? Colors.orange : Colors.green,
                  ),
                  onPressed: () => _toggleUserStatus(user),
                  tooltip: isActive ? 'השבת משתמש' : 'הפעל משתמש',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteUserDialog(user),
                  tooltip: 'מחק משתמש',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getRoleColor(role)),
      ),
      child: Text(
        _getRoleDisplayName(role),
        style: TextStyle(
          color: _getRoleColor(role),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? Colors.green : Colors.red),
      ),
      child: Text(
        isActive ? 'פעיל' : 'לא פעיל',
        style: TextStyle(
          color: isActive ? Colors.green : Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAuthProviderChip(String provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4285F4).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4285F4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF4285F4),
            ),
            child: const Center(
              child: Text(
                'G',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Google',
            style: TextStyle(
              color: Color(0xFF4285F4),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'instructor':
        return const Color(0xFF2196F3);
      case 'parent':
        return const Color(0xFFE91E63);
      case 'student':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return 'A';
      case 'instructor':
        return 'M';
      case 'parent':
        return 'P';
      case 'student':
        return 'S';
      default:
        return '?';
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'מנהל';
      case 'instructor':
        return 'מדריך';
      case 'parent':
        return 'הורה';
      case 'student':
        return 'תלמיד';
      default:
        return role;
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(
        onSave: _addUser,
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(
        user: user,
        onSave: (userData) => _updateUser(user['id'], userData),
      ),
    );
  }

  void _showDeleteUserDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'מחיקת משתמש',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את המשתמש ${user['display_name'] ?? user['email']}?\n\nפעולה זו אינה ניתנת לביטול!',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'ביטול',
              style: TextStyle(color: Color(0xFF2196F3)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteUser(user['id']);
            },
            child: const Text(
              'מחק',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addUser(Map<String, String> userData) async {
    try {
      print('Adding user with data: $userData');

      final username = userData['username']!;
      final dummyEmail = userData['email']!;

      // בדיקה אם שם המשתמש כבר קיים
      final existingUser = await _supabase
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (existingUser != null) {
        throw Exception('שם המשתמש כבר קיים');
      }

      // בדיקה אם האימייל הדמה כבר קיים ב-auth
      final existingAuth = await _supabase
          .from('users')
          .select('email')
          .eq('email', dummyEmail)
          .maybeSingle();

      if (existingAuth != null) {
        throw Exception('שם המשתמש כבר קיים במערכת');
      }

      // First create a user in Supabase Auth using signUp
      final authResponse = await _supabase.auth.signUp(
        email: dummyEmail,
        password: userData['password'] ?? 'TempPass123!',
        data: {
          'full_name': userData['full_name'],
          'username': username,
        },
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create auth user');
      }

      print('Auth user created: ${authResponse.user!.id}');
      
      // Now create the user record in our users table with the auth user ID
      final userRecord = {
        'id': authResponse.user!.id,
        'username': username,
        'email': dummyEmail,
        'display_name': userData['full_name'] ?? '',
        'full_name': userData['full_name'] ?? '',
        'phone': userData['phone'] ?? '',
        'address': userData['address'] ?? '',
        'user_type': userData['user_type'] ?? 'student',
        'role': userData['role'] ?? 'student',
        'approval_status': userData['approval_status'] ?? 'pending',
        'is_approved': userData['is_approved'] == 'true',
        'is_active': userData['is_active'] == 'true',
      };

      // Add parent_name or student_name based on user type
      if (userData['user_type'] == 'student' && userData['parent_name'] != null) {
        userRecord['parent_name'] = userData['parent_name']!;
      } else if (userData['user_type'] == 'parent' && userData['student_name'] != null) {
        userRecord['student_name'] = userData['student_name']!;
      }

      final response = await _supabase.from('users').insert(userRecord).select();
      
      print('User record created: $response');
      
      _showSuccessSnackBar('משתמש נוסף בהצלחה');
      _loadUsers(); // Refresh the list
    } catch (e) {
      print('Error adding user: $e');
      _showErrorSnackBar('שגיאה בהוספת המשתמש: $e');
    }
  }

  Future<void> _updateUser(String userId, Map<String, String> userData) async {
    try {
      // Now that RLS is disabled, update directly in Supabase first
      final updateData = {
        'display_name': userData['full_name'],
        'full_name': userData['full_name'],
        'phone': userData['phone'],
        'address': userData['address'],
        'user_type': userData['user_type'],
        'role': userData['role'],
        'approval_status': userData['approval_status'],
        'is_approved': userData['is_approved'] == 'true',
        'is_active': userData['is_active'] == 'true',
      };

      // Add parent_name or student_name based on user type, and clear the other
      if (userData['user_type'] == 'student') {
        updateData['parent_name'] = userData['parent_name'] ?? '';
        updateData['student_name'] = null;
      } else if (userData['user_type'] == 'parent') {
        updateData['student_name'] = userData['student_name'] ?? '';
        updateData['parent_name'] = null;
      }

      final response = await _supabase
          .from('users')
          .update(updateData)
          .eq('id', userId)
          .select();

      if (response.isNotEmpty) {
        // Update successful, now update local state
        setState(() {
          final index = _users.indexWhere((user) => user['id'] == userId);
          if (index != -1) {
            _users[index]['display_name'] = userData['full_name'];
            _users[index]['full_name'] = userData['full_name'];
            _users[index]['phone'] = userData['phone'];
            _users[index]['address'] = userData['address'];
            _users[index]['user_type'] = userData['user_type'];
            _users[index]['role'] = userData['role'];
            _users[index]['approval_status'] = userData['approval_status'];
            _users[index]['is_approved'] = userData['is_approved'] == 'true';
            _users[index]['is_active'] = userData['is_active'] == 'true';
            _users[index]['first_name'] = userData['full_name']?.split(' ')[0];
            _users[index]['last_name'] = (userData['full_name']?.split(' ').length ?? 0) > 1 ? userData['full_name']?.split(' ')[1] : '';

            // Update parent_name or student_name and clear the other
            if (userData['user_type'] == 'student') {
              _users[index]['parent_name'] = userData['parent_name'] ?? '';
              _users[index]['student_name'] = null;
            } else if (userData['user_type'] == 'parent') {
              _users[index]['student_name'] = userData['student_name'] ?? '';
              _users[index]['parent_name'] = null;
            }
          }
        });
        _showSuccessSnackBar('משתמש עודכן בהצלחה במסד הנתונים!');
      } else {
        _showErrorSnackBar('שגיאה: לא ניתן לעדכן את המשתמש');
      }
    } catch (e) {
      _showErrorSnackBar('שגיאה בעדכון המשתמש: $e');
    }
  }

  // Attempt to update in Supabase in the background
  void _attemptBackgroundUpdate(String userId, Map<String, String> userData) async {
    try {
      final response = await _supabase
          .from('users')
          .update({
            'display_name': userData['display_name'],
            'phone': userData['phone'],
            'role': userData['role'],
            'is_active': userData['is_active'] == 'true',
          })
          .eq('id', userId)
          .select();
      
      print('Background update response: $response');
      
      if (response.isNotEmpty) {
        print('Background update successful');
      } else {
        print('Background update failed due to RLS policies');
      }
    } catch (e) {
      print('Background update error: $e');
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    try {
      final newStatus = !(user['is_active'] ?? true);
      
      // Use RPC function to bypass RLS
      print('DEBUG: Toggling user ${user['id']} active status to $newStatus');
      
      final response = await _supabase.rpc('toggle_user_active_admin', 
        params: {
          'user_id': user['id'],
          'active_status': newStatus
        }
      );
      
      print('DEBUG: Toggle user active response: $response');

      // Update successful, now update local state
      setState(() {
        final index = _users.indexWhere((u) => u['id'] == user['id']);
        if (index != -1) {
          _users[index]['is_active'] = newStatus;
        }
      });
      _showSuccessSnackBar(newStatus ? 'משתמש הופעל בהצלחה!' : 'משתמש הושבת בהצלחה!');
    } catch (e) {
      _showErrorSnackBar('שגיאה בעדכון סטטוס המשתמש: $e');
    }
  }

  // Attempt to update user status in Supabase in the background
  void _attemptBackgroundStatusUpdate(String userId, bool newStatus) async {
    try {
      final response = await _supabase.rpc('toggle_user_active_admin', 
        params: {
          'user_id': userId,
          'active_status': newStatus
        }
      );
      
      print('Background status update response: $response');
      
      print('Background status update successful: $response');
    } catch (e) {
      print('Background status update error: $e');
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      // Prevent deleting admin user
      final userToDelete = _users.firstWhere((user) => user['id'] == userId);
      if (userToDelete['email'] == 'dev@zazadance.com') {
        _showErrorSnackBar('לא ניתן למחוק את המשתמש הראשי');
        return;
      }

      print('DEBUG: Deleting user ID: $userId');

      // Use RPC function to bypass RLS
      final response = await _supabase.rpc('delete_user_admin', 
        params: {'user_id': userId}
      );
      
      print('DEBUG: Delete user response: $response');

      if (response == true) {
        // Also delete from auth.users if possible
        try {
          await _supabase.auth.admin.deleteUser(userId);
          print('DEBUG: Auth user deleted successfully');
        } catch (authError) {
          print('DEBUG: Auth delete error (might be okay for Google users): $authError');
        }

        // Remove from local state only after successful delete
        setState(() {
          _users.removeWhere((user) => user['id'] == userId);
        });
        _showSuccessSnackBar('משתמש נמחק בהצלחה!');
      } else {
        _showErrorSnackBar('שגיאה במחיקת המשתמש');
      }
      
    } catch (e) {
      print('DEBUG: Delete error: $e');
      _showErrorSnackBar('שגיאה במחיקת המשתמש: $e');
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
}

// Dialog for adding/editing users
class UserFormDialog extends StatefulWidget {
  final Map<String, dynamic>? user;
  final Function(Map<String, String>) onSave;

  const UserFormDialog({
    super.key,
    this.user,
    required this.onSave,
  });

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _relatedNameController = TextEditingController();

  String _selectedRole = 'student';
  String _selectedUserType = 'student';
  String _selectedApprovalStatus = 'pending';
  bool _isActive = true;
  bool _isApproved = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      // Extract username from email (remove @zazadance.com part)
      final email = widget.user!['email'] ?? '';
      _usernameController.text = email.replaceAll('@zazadance.com', '');
      _fullNameController.text = widget.user!['full_name'] ?? '';
      _phoneController.text = widget.user!['phone'] ?? '';
      _addressController.text = widget.user!['address'] ?? '';
      _selectedRole = widget.user!['role'] ?? 'student';
      _selectedUserType = widget.user!['user_type'] ?? 'student';
      _selectedApprovalStatus = widget.user!['approval_status'] ?? 'pending';
      _isActive = widget.user!['is_active'] ?? true;
      _isApproved = widget.user!['is_approved'] ?? false;

      // Set related name based on user type
      if (_selectedUserType == 'student') {
        _relatedNameController.text = widget.user!['parent_name'] ?? '';
      } else if (_selectedUserType == 'parent') {
        _relatedNameController.text = widget.user!['student_name'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _relatedNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdit ? 'עריכת משתמש' : 'הוספת משתמש חדש',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Username
                TextFormField(
                  controller: _usernameController,
                  enabled: !isEdit, // Don't allow username editing
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'שם משתמש',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.person, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'נא להזין שם משתמש';
                    }
                    if (value.length < 3) {
                      return 'שם המשתמש חייב להכיל לפחות 3 תווים';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'שם משתמש יכול להכיל רק אותיות באנגלית, מספרים וקו תחתון';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Password (only for new users)
                if (!isEdit) ...[
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'סיסמה',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'נא להזין סיסמה';
                      }
                      if (value.length < 6) {
                        return 'הסיסמה חייבת להכיל לפחות 6 תווים';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Full Name (same as registration)
                TextFormField(
                  controller: _fullNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'שם מלא',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.person, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'נא להזין שם מלא';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'טלפון',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.phone, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'כתובת',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.location_on, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // User Type
                DropdownButtonFormField<String>(
                  value: _selectedUserType,
                  onChanged: (value) => setState(() {
                    _selectedUserType = value!;
                    _relatedNameController.clear(); // Clear related name when type changes
                  }),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF2A2A2A),
                  decoration: InputDecoration(
                    labelText: 'סוג משתמש',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.group, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('תלמיד')),
                    DropdownMenuItem(value: 'parent', child: Text('הורה')),
                  ],
                ),

                const SizedBox(height: 16),

                // Related Name (Parent/Student name based on user type)
                TextFormField(
                  controller: _relatedNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: _selectedUserType == 'student' ? 'שם ההורה' : 'שם התלמיד',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                
                // Role
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  onChanged: (value) => setState(() => _selectedRole = value!),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF2A2A2A),
                  decoration: InputDecoration(
                    labelText: 'תפקיד',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.admin_panel_settings, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('תלמיד')),
                    DropdownMenuItem(value: 'parent', child: Text('הורה')),
                    DropdownMenuItem(value: 'instructor', child: Text('מדריך')),
                    DropdownMenuItem(value: 'admin', child: Text('מנהל')),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Approval Status
                DropdownButtonFormField<String>(
                  value: _selectedApprovalStatus,
                  onChanged: (value) => setState(() {
                    _selectedApprovalStatus = value!;
                    _isApproved = value == 'approved';
                  }),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF2A2A2A),
                  decoration: InputDecoration(
                    labelText: 'סטטוס אישור',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.verified, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('ממתין לאישור')),
                    DropdownMenuItem(value: 'approved', child: Text('אושר')),
                    DropdownMenuItem(value: 'rejected', child: Text('נדחה')),
                  ],
                ),

                const SizedBox(height: 16),

                // Active status (only for editing)
                if (isEdit)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.toggle_on, color: Colors.white54),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'סטטוס פעיל',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        Switch(
                          value: _isActive,
                          onChanged: (value) => setState(() => _isActive = value),
                          activeColor: const Color(0xFF4CAF50),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                        ),
                        child: const Text(
                          'ביטול',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                isEdit ? 'עדכן' : 'הוסף',
                                style: const TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final username = _usernameController.text.trim().toLowerCase();
      final dummyEmail = '${username}@zazadance.com';

      final userData = <String, String>{
        'username': username,
        'email': dummyEmail,
        'display_name': _fullNameController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'user_type': _selectedUserType,
        'role': _selectedRole,
        'approval_status': _selectedApprovalStatus,
        'is_approved': _isApproved.toString(),
        'is_active': _isActive.toString(),
      };

      // Add parent_name or student_name based on user type
      if (_selectedUserType == 'student') {
        userData['parent_name'] = _relatedNameController.text.trim();
      } else if (_selectedUserType == 'parent') {
        userData['student_name'] = _relatedNameController.text.trim();
      }

      if (widget.user == null) { // New user
        userData['password'] = _passwordController.text;
      }

      widget.onSave(userData);
      Navigator.of(context).pop();
    }
  }
}