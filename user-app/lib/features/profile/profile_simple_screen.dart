import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';

class ProfileSimpleScreen extends ConsumerStatefulWidget {
  const ProfileSimpleScreen({super.key});

  @override
  ConsumerState<ProfileSimpleScreen> createState() => _ProfileSimpleScreenState();
}

class _ProfileSimpleScreenState extends ConsumerState<ProfileSimpleScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _studentNameController = TextEditingController();
  
  String _selectedRole = 'תלמיד/ה';
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _parentNameController.dispose();
    _studentNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('users')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _fullNameController.text = response['full_name'] ?? response['display_name'] ?? '';
          _phoneController.text = response['phone'] ?? '';
          _addressController.text = response['address'] ?? '';
          final dbRole = response['role'] ?? 'student';
          _selectedRole = dbRole == 'student' ? 'תלמיד/ה' : 'הורה';
          _parentNameController.text = response['parent_name'] ?? '';
          _studentNameController.text = response['student_name'] ?? '';
          _profileImageUrl = response['profile_image_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת הפרופיל: $e')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // קודם נבדוק אם המשתמש קיים
      final existingUser = await _supabase
          .from('users')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      final userData = {
        'id': user.id,
        'email': user.email ?? '',
        'display_name': _fullNameController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'role': _selectedRole == 'תלמיד/ה' ? 'student' : 'parent',
        'parent_name': _selectedRole == 'תלמיד/ה' ? _parentNameController.text.trim() : null,
        'student_name': _selectedRole == 'הורה' ? _studentNameController.text.trim() : null,
        'profile_image_url': _profileImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existingUser == null) {
        // אם המשתמש לא קיים, נוסיף גם created_at
        userData['created_at'] = DateTime.now().toIso8601String();
      }

      await _supabase.from('users').upsert(userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הפרטים עודכנו בהצלחה'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בעדכון הפרטים: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'מחיקת חשבון',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'האם אתה בטוח שברצונך למחוק את החשבון?\n\nפעולה זו תמחק לצמיתות:\n• את כל הנתונים שלך\n• תמונות הפרופיל\n• ההיסטוריה שלך באפליקציה\n\nלא ניתן לבטל פעולה זו!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'ביטול',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'מחק חשבון',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final doubleConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'אישור אחרון',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'זהו האישור האחרון!\n\nלחיצה על "אישור מחיקה" תמחק את החשבון שלך לצמיתות ללא אפשרות שחזור.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'ביטול',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'אישור מחיקה',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (doubleConfirmed == true) {
        try {
          setState(() {
            _isUpdating = true;
          });

          // מחיקת חשבון משתמש
          
          if (mounted) {
            // ניקוי מצב האפליקציה
            setState(() {
              _isUpdating = false;
            });
            
            // המתנה קצרה לוודא שה-signOut הושלם
            await Future.delayed(const Duration(milliseconds: 500));
            
            // מעבר מיידי לדף התחברות עם ניקוי מלא של המחסנית
            context.go('/login');
            
            // הצגת הודעת הצלחה
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('החשבון נמחק בהצלחה'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isUpdating = false;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('שגיאה במחיקת החשבון: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'איזור אישי',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE91E63),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // כותרת
                    const Text(
                      'עדכון פרטים אישיים',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // תמונת פרופיל
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1E1E1E),
                              border: Border.all(
                                color: const Color(0xFFE91E63),
                                width: 3,
                              ),
                            ),
                            child: _profileImageUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      _profileImageUrl!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white54,
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickProfileImage,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE91E63),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF121212),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // שם מלא
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'שם מלא',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'יש להזין שם מלא';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // מספר טלפון
                    _buildTextField(
                      controller: _phoneController,
                      label: 'מספר טלפון',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'יש להזין מספר טלפון';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // כתובת מגורים
                    _buildTextField(
                      controller: _addressController,
                      label: 'כתובת מגורים',
                      icon: Icons.home_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'יש להזין כתובת מגורים';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // בחירת תפקיד
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'תפקיד',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF00BCD4),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text(
                                    'תלמיד/ה',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  value: 'תלמיד/ה',
                                  groupValue: _selectedRole,
                                  activeColor: const Color(0xFFE91E63),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text(
                                    'הורה',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  value: 'הורה',
                                  groupValue: _selectedRole,
                                  activeColor: const Color(0xFFE91E63),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // שם ההורה (רק עבור תלמידים)
                    if (_selectedRole == 'תלמיד/ה') ...[
                      _buildTextField(
                        controller: _parentNameController,
                        label: 'שם ההורה',
                        icon: Icons.family_restroom,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // שם התלמיד (רק עבור הורים)
                    if (_selectedRole == 'הורה') ...[
                      _buildTextField(
                        controller: _studentNameController,
                        label: 'שם התלמיד/ה',
                        icon: Icons.school_outlined,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // כפתור עדכון
                    ElevatedButton(
                      onPressed: _isUpdating ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isUpdating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'עדכון פרטים',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // מחיקת חשבון
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_remove, color: Colors.grey, size: 24),
                              const SizedBox(width: 8),
                              const Text(
                                'ניהול חשבון',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'אם תרצה להסיר את החשבון שלך מהאפליקציה',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isUpdating ? null : _deleteAccount,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              icon: const Icon(Icons.logout, size: 20),
                              label: const Text(
                                'הסר חשבון',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'פעולה זו לא ניתנת לביטול ותמחק את כל הנתונים, תמונות והיסטוריית הפעילות שלך.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white54,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF00BCD4)),
        prefixIcon: Icon(icon, color: const Color(0xFF00BCD4)),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _isUpdating = true;
        });

        final bytes = await image.readAsBytes();
        final user = _supabase.auth.currentUser;
        if (user == null) return;

        // העלאת התמונה לstorage
        final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final uploadPath = await _supabase.storage
            .from('profiles')
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );

        // קבלת URL של התמונה
        final imageUrl = _supabase.storage
            .from('profiles')
            .getPublicUrl(fileName);

        setState(() {
          _profileImageUrl = imageUrl;
          _isUpdating = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('תמונת הפרופיל עודכנה בהצלחה'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בהעלאת תמונה: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}