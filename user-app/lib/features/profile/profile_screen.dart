import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/google_auth_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = true;
  bool _isEditing = false;
  File? _selectedImage;
  String? _currentAvatarUrl;
  
  // User stats (mock data for now)
  final Map<String, dynamic> _userStats = {
    'tutorials_watched': 24,
    'favorite_tutorials': 8,
    'gallery_likes': 156,
    'achievements': 5,
    'days_active': 42,
    'level': 'מתקדם',
  };

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // טעינת פרופיל משתמש מהמסד
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('user_id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _firstNameController.text = response['first_name'] ?? '';
          _lastNameController.text = response['last_name'] ?? '';
          _emailController.text = user.email ?? '';
          _phoneController.text = response['phone'] ?? '';
          _bioController.text = response['bio'] ?? '';
          _currentAvatarUrl = response['avatar_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // If profile doesn't exist, create one with basic info
        final user = _supabase.auth.currentUser;
        if (user != null) {
          _emailController.text = user.email ?? '';
        }
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בבחירת תמונה: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      String? avatarUrl = _currentAvatarUrl;
      
      // העלאת תמונה חדשה אם נבחרה
      if (_selectedImage != null) {
        final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageResponse = await _supabase.storage
            .from('avatars')
            .upload(fileName, _selectedImage!);
            
        if (storageResponse.isNotEmpty) {
          avatarUrl = _supabase.storage
              .from('avatars')
              .getPublicUrl(fileName);
        }
      }

      // עדכון פרופיל במסד הנתונים
      await _supabase.from('profiles').upsert({
        'user_id': user.id,
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'phone': _phoneController.text,
        'bio': _bioController.text,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
          _currentAvatarUrl = avatarUrl;
          _selectedImage = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הפרופיל עודכן בהצלחה'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בשמירת הפרופיל: $e')),
        );
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
            _isLoading = true;
          });

          await GoogleAuthService().deleteUserAccount();
          
          if (mounted) {
            // ניווט לדף ההתחברות ומחיקת כל ההיסטוריה
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
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
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'פרופיל אישי',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              child: const Text(
                'ערוך',
                style: TextStyle(color: Color(0xFF00BCD4)),
              ),
            ),
          if (_isEditing) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _selectedImage = null;
                });
                _loadUserProfile(); // Reload original data
              },
              child: const Text(
                'ביטול',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: const Text(
                'שמור',
                style: TextStyle(color: Color(0xFFE91E63)),
              ),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE91E63),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // תמונת פרופיל
                    _buildProfileImage(),
                    
                    const SizedBox(height: 24),
                    
                    // פרטים אישיים
                    _buildPersonalInfo(),
                    
                    const SizedBox(height: 24),
                    
                    // סטטיסטיקות משתמש
                    _buildUserStats(),
                    
                    const SizedBox(height: 24),
                    
                    // הישגים
                    _buildAchievements(),
                    
                    const SizedBox(height: 24),
                    
                    // הגדרות נוספות
                    _buildSettings(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[800],
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!) as ImageProvider
                : _currentAvatarUrl != null
                    ? NetworkImage(_currentAvatarUrl!) as ImageProvider
                    : null,
            child: (_selectedImage == null && _currentAvatarUrl == null)
                ? const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white54,
                  )
                : null,
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE91E63),
                    shape: BoxShape.circle,
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
    );
  }

  Widget _buildPersonalInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'פרטים אישיים',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // שם פרטי ומשפחה
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'שם פרטי',
                  enabled: _isEditing,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'שם משפחה',
                  enabled: _isEditing,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // אימייל (לא ניתן לעריכה)
          _buildTextField(
            controller: _emailController,
            label: 'אימייל',
            enabled: false,
            icon: Icons.lock_outline,
          ),
          
          const SizedBox(height: 12),
          
          // טלפון
          _buildTextField(
            controller: _phoneController,
            label: 'טלפון',
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
          ),
          
          const SizedBox(height: 12),
          
          // ביוגרפיה
          _buildTextField(
            controller: _bioController,
            label: 'קצת עליי',
            enabled: _isEditing,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool enabled,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: enabled ? Colors.white : Colors.white60,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        suffixIcon: icon != null 
            ? Icon(icon, color: Colors.white60, size: 20) 
            : null,
        filled: true,
        fillColor: enabled ? const Color(0xFF2E2E2E) : Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: enabled ? Colors.white30 : Colors.transparent,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE91E63)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
      ),
      validator: (value) {
        if (label == 'שם פרטי' || label == 'שם משפחה') {
          if (value == null || value.isEmpty) {
            return 'שדה חובה';
          }
        }
        return null;
      },
    );
  }

  Widget _buildUserStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'הסטטיסטיקה שלי',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildStatCard(
                'מדריכים שנצפו',
                _userStats['tutorials_watched'].toString(),
                Icons.play_circle_outline,
                const Color(0xFFE91E63),
              ),
              _buildStatCard(
                'מועדפים',
                _userStats['favorite_tutorials'].toString(),
                Icons.favorite_outline,
                const Color(0xFF00BCD4),
              ),
              _buildStatCard(
                'לייקים בגלריה',
                _userStats['gallery_likes'].toString(),
                Icons.thumb_up_outlined,
                const Color(0xFF4CAF50),
              ),
              _buildStatCard(
                'הישגים',
                _userStats['achievements'].toString(),
                Icons.emoji_events_outlined,
                const Color(0xFFFF9800),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'ימים פעילים',
                  _userStats['days_active'].toString(),
                  Icons.calendar_today,
                  const Color(0xFF9C27B0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'רמה',
                  _userStats['level'],
                  Icons.stars,
                  const Color(0xFFFFEB3B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'הישגים אחרונים',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildAchievementItem(
            'צופה מקצועי',
            'צפה ב-20 מדריכים',
            Icons.play_circle_fill,
            const Color(0xFFE91E63),
          ),
          _buildAchievementItem(
            'חובב גלריה',
            'נתן 100 לייקים',
            Icons.thumb_up,
            const Color(0xFF4CAF50),
          ),
          _buildAchievementItem(
            'איש חברתי',
            'שיתף 10 פוסטים',
            Icons.share,
            const Color(0xFF00BCD4),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'הגדרות',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildSettingItem(
            'התראות',
            'נהל הגדרות התראות',
            Icons.notifications_outlined,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('פתח הגדרות התראות')),
              );
            },
          ),
          _buildSettingItem(
            'פרטיות',
            'הגדרות פרטיות וביטחון',
            Icons.privacy_tip_outlined,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('פתח הגדרות פרטיות')),
              );
            },
          ),
          _buildSettingItem(
            'שנה סיסמה',
            'עדכון סיסמה',
            Icons.lock_outline,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('פתח שינוי סיסמה')),
              );
            },
          ),
          _buildSettingItem(
            'צור קשר',
            'שלח פניה לתמיכה',
            Icons.help_outline,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('פתח פניה לתמיכה')),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // מחיקת חשבון - אזור מסוכן
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.8), // Make it more visible temporarily
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red, width: 2), // Make border more visible
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'אזור מסוכן',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'פעולות בלתי הפיכות שעלולות למחוק את כל הנתונים שלך',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text(
                      'מחק חשבון לצמיתות',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF00BCD4)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white60,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_left,
        color: Colors.white60,
      ),
      onTap: onTap,
    );
  }
}