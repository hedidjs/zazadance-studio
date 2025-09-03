import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      
      final response = await _supabase
          .from('users')
          .select('id, email, display_name, full_name, role, phone, is_active, created_at, profile_image_url')
          .order('created_at', ascending: false);

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('שגיאה בטעינת המשתמשים: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    
    return _users.where((user) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ניהול משתמשים',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddUserDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUsers,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'חיפוש משתמשים...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Users list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE91E63),
                    ),
                  )
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'לא נמצאו משתמשים',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        color: const Color(0xFFE91E63),
                        child: ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return _buildUserCard(user);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role'] ?? 'student';
    final isActive = user['is_active'] ?? true;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: const Color(0xFF1E1E1E),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(role),
          child: Text(
            _getRoleIcon(role),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user['display_name'] ?? user['email'] ?? 'לא ידוע',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user['email'] ?? '',
              style: const TextStyle(color: Colors.white70),
            ),
            if (user['phone'] != null && user['phone'].toString().isNotEmpty)
              Text(
                user['phone'],
                style: const TextStyle(color: Colors.white54),
              ),
            Row(
              children: [
                _buildRoleChip(role),
                const SizedBox(width: 8),
                _buildStatusChip(isActive),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF00BCD4)),
              onPressed: () => _showEditUserDialog(user),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteUserDialog(user),
            ),
          ],
        ),
        isThreeLine: true,
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'instructor':
        return const Color(0xFF00BCD4);
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
          'האם אתה בטוח שברצונך למחוק את המשתמש ${user['display_name'] ?? user['email']}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'ביטול',
              style: TextStyle(color: Color(0xFF00BCD4)),
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
      // Create user in Supabase Auth
      final response = await _supabase.auth.admin.createUser(AdminUserAttributes(
        email: userData['email']!,
        password: userData['password']!,
        emailConfirm: true,
        userMetadata: {
          'display_name': userData['display_name'],
          'full_name': userData['full_name'],
          'phone': userData['phone'],
        },
      ));

      if (response.user != null) {
        // Add user to users table
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': userData['email'],
          'display_name': userData['display_name'],
          'full_name': userData['full_name'],
          'phone': userData['phone'],
          'role': userData['role'],
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        _showSuccessSnackBar('משתמש נוסף בהצלחה');
        _loadUsers();
      }
    } catch (e) {
      _showErrorSnackBar('שגיאה בהוספת המשתמש: $e');
    }
  }

  Future<void> _updateUser(String userId, Map<String, String> userData) async {
    try {
      await _supabase.from('users').update({
        'display_name': userData['display_name'],
        'full_name': userData['full_name'],
        'phone': userData['phone'],
        'role': userData['role'],
        'is_active': userData['is_active'] == 'true',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      _showSuccessSnackBar('משתמש עודכן בהצלחה');
      _loadUsers();
    } catch (e) {
      _showErrorSnackBar('שגיאה בעדכון המשתמש: $e');
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      // First deactivate user
      await _supabase.from('users').update({
        'is_active': false,
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Note: We don't actually delete from auth.users for audit purposes
      // Instead we mark as inactive and add deleted_at timestamp
      
      _showSuccessSnackBar('משתמש נמחק בהצלחה');
      _loadUsers();
    } catch (e) {
      _showErrorSnackBar('שגיאה במחיקת המשתמש: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedRole = 'student';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _emailController.text = widget.user!['email'] ?? '';
      _displayNameController.text = widget.user!['display_name'] ?? '';
      _fullNameController.text = widget.user!['full_name'] ?? '';
      _phoneController.text = widget.user!['phone'] ?? '';
      _selectedRole = widget.user!['role'] ?? 'student';
      _isActive = widget.user!['is_active'] ?? true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                
                // Email
                TextFormField(
                  controller: _emailController,
                  enabled: !isEdit, // Don't allow email editing
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'אימייל',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.email, color: Colors.white54),
                    filled: true,
                    fillColor: Color(0xFF2A2A2A),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'נא להזין אימייל';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'אימייל לא תקין';
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
                    decoration: const InputDecoration(
                      labelText: 'סיסמה',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.lock, color: Colors.white54),
                      filled: true,
                      fillColor: Color(0xFF2A2A2A),
                      border: OutlineInputBorder(),
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
                
                // Display Name
                TextFormField(
                  controller: _displayNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'שם לתצוגה',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.person, color: Colors.white54),
                    filled: true,
                    fillColor: Color(0xFF2A2A2A),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'נא להזין שם לתצוגה';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'שם מלא',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.badge, color: Colors.white54),
                    filled: true,
                    fillColor: Color(0xFF2A2A2A),
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'טלפון',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.phone, color: Colors.white54),
                    filled: true,
                    fillColor: Color(0xFF2A2A2A),
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Role
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  onChanged: (value) => setState(() => _selectedRole = value!),
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF2A2A2A),
                  decoration: const InputDecoration(
                    labelText: 'תפקיד',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.admin_panel_settings, color: Colors.white54),
                    filled: true,
                    fillColor: Color(0xFF2A2A2A),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('תלמיד')),
                    DropdownMenuItem(value: 'parent', child: Text('הורה')),
                    DropdownMenuItem(value: 'instructor', child: Text('מדריך')),
                    DropdownMenuItem(value: 'admin', child: Text('מנהל')),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Active status (only for editing)
                if (isEdit)
                  SwitchListTile(
                    title: const Text('פעיל', style: TextStyle(color: Colors.white)),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    activeColor: const Color(0xFF00BCD4),
                    tileColor: const Color(0xFF2A2A2A),
                  ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
                          backgroundColor: const Color(0xFFE91E63),
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
      
      final userData = {
        'email': _emailController.text.trim(),
        'display_name': _displayNameController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        'is_active': _isActive.toString(),
      };
      
      if (widget.user == null) { // New user
        userData['password'] = _passwordController.text;
      }
      
      widget.onSave(userData);
      Navigator.of(context).pop();
    }
  }
}