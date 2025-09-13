import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../providers/app_config_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _relatedNameController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedUserType;
  XFile? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _relatedNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _profileImage = image;
        });
      }
    } catch (e) {
      _showErrorSnackBar('שגיאה בבחירת תמונה: $e');
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_profileImage == null) return null;
    
    try {
      final fileExtension = _profileImage!.path.split('.').last;
      final fileName = '${userId}_profile.$fileExtension';
      
      final imageBytes = await _profileImage!.readAsBytes();
      await _supabase.storage
          .from('avatars')
          .uploadBinary(fileName, imageBytes);
      
      final imageUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);
      
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    // בדיקת ולידציה נוספת
    if (_selectedUserType == null) {
      _showErrorSnackBar('אנא בחר סוג משתמש');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final username = _usernameController.text.trim().toLowerCase();
      final dummyEmail = '${username}@zazadance.com';

      // בדיקה אם שם המשתמש כבר קיים
      final existingUser = await _supabase
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      if (existingUser != null) {
        _showErrorSnackBar('שם המשתמש כבר קיים');
        return;
      }

      // בדיקה אם האימייל הדמה כבר קיים ב-auth
      final existingAuth = await _supabase
          .from('users')
          .select('email')
          .eq('email', dummyEmail)
          .maybeSingle();

      if (existingAuth != null) {
        _showErrorSnackBar('שם המשתמש כבר קיים במערכת');
        return;
      }
      
      final response = await _supabase.auth.signUp(
        email: dummyEmail,
        password: _passwordController.text,
        data: {
          'full_name': _fullNameController.text.trim(),
          'username': username,
        },
      );

      if (response.user != null) {
        // הודעת הצלחה ראשונה
        print('*** REGISTRATION SUCCESS MESSAGE TEST ***');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('נרשמת בהצלחה! בקשתך נשלחה לאישור האדמין'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );

        // העלאת תמונת פרופיל אם נבחרה (עם טיפול בשגיאות)
        String? profileImageUrl;
        try {
          profileImageUrl = await _uploadProfileImage(response.user!.id);
        } catch (e) {
          print('Error uploading profile image: $e');
          // ממשיכים גם עם שגיאה בתמונה
        }

        // יצירת רשומה בטבלת users עם מערכת האישור
        final userData = {
          'id': response.user!.id,
          'username': username,
          'email': dummyEmail,
          'display_name': _fullNameController.text.trim(),
          'full_name': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'user_type': _selectedUserType!, // parent או student
          'parent_name': _selectedUserType == 'student' ? _relatedNameController.text.trim() : null,
          'student_name': _selectedUserType == 'parent' ? _relatedNameController.text.trim() : null,
          'profile_image_url': profileImageUrl,
          'role': _selectedUserType!, // התחל עם אותו role כמו user_type
          'is_approved': false,
          'approval_status': 'pending',
          'is_active': false,
        };
        print('INSERTING USER DATA: $userData');
        
        final insertResult = await _supabase.from('users').insert(userData);
        print('INSERT RESULT: $insertResult');
        
        if (mounted) {
          await Future.delayed(const Duration(seconds: 2));
          await _supabase.auth.signOut();
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        _showErrorSnackBar(error.message);
      }
    } catch (error) {
      print('REGISTRATION ERROR: $error');
      print('ERROR TYPE: ${error.runtimeType}');
      if (mounted) {
        _showErrorSnackBar('Database error saving new user: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showWelcomeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // מעקל של ידית למעלה
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // לוגו זאזא
              Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(52),
                  child: Image.asset(
                    'assets/images/zaza_logo.png',
                    width: 104,
                    height: 104,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // כותרת ברוכים הבאים
              const Text(
                'ברוכים הבאים לסטודיו זאזא!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // הודעה על הצלחת ההרשמה
              const Text(
                'נרשמת בהצלחה! ברוכים הבאים למשפחה שלנו',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // המלצה לעדכון פרטים
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00BCD4).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF00BCD4),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'מומלץ לעדכן את הפרטים האישיים',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00BCD4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'לחצו על \"עדכן פרטים\" כדי להוסיף מידע נוסף כמו כתובת, תפקיד ופרטי הורים/ילדים',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // כפתורי פעולה
              Column(
                children: [
                  // כפתור לעדכון פרטים
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/profile');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'עדכן פרטים',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // כפתור להמשיך לאפליקציה
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        context.go('/');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'המשך לאפליקציה',
                        style: TextStyle(
                          fontSize: 16,
                        ),
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

  void _showPendingApprovalBottomSheet() {
    print('DEBUG: _showPendingApprovalBottomSheet called');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // מעקל של ידית למעלה
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // אייקון המתנה
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA726).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: const Color(0xFFFFA726),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.hourglass_empty,
                    color: Color(0xFFFFA726),
                    size: 60,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // כותרת
                const Text(
                  'בקשתך נשלחה בהצלחה!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // הודעה
                const Text(
                  'הבקשה שלך נשלחה לאישור מנהל הסטודיו',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // פרטים נוספים
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF00BCD4),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'מה קורה עכשיו?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF00BCD4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• מנהל הסטודיו יקבל הודעה על הבקשה\n• הבקשה תיבדק ותאושר בהקדם האפשרי\n• תקבל הודעה כשהמשתמש יאושר\n• רק אז תוכל להתחבר לאפליקציה',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // כפתור חזרה להתחברות
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'חזור לעמוד ההתחברות',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _getImageBytes() async {
    // XFile תומך ב-readAsBytes() גם ב-Web וגם ב-Mobile
    return await _profileImage!.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // לוגו ZaZa Dance
                  Image.asset(
                    'assets/images/zaza_logo.png',
                    width: 280,
                    fit: BoxFit.contain,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // כותרת
                  const Text(
                    'הצטרפו אלינו',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'צרו חשבון חדש',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // תמונת פרופיל
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E2E2E),
                          borderRadius: BorderRadius.circular(60),
                          border: Border.all(
                            color: const Color(0xFF00BCD4),
                            width: 2,
                          ),
                        ),
                        child: _profileImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(58),
                                child: FutureBuilder<Uint8List>(
                                  future: _getImageBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        width: 116,
                                        height: 116,
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    return const CircularProgressIndicator();
                                  },
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    color: Color(0xFF00BCD4),
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'הוסף תמונה',
                                    style: TextStyle(
                                      color: Color(0xFF00BCD4),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // שדה שם מלא
                  TextFormField(
                    controller: _fullNameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'שם מלא',
                      prefixIcon: const Icon(Icons.person_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'אנא הזן שם מלא';
                      }
                      if (value.trim().length < 2) {
                        return 'השם צריך להכיל לפחות 2 תווים';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // שדה שם משתמש
                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'שם משתמש',
                      prefixIcon: const Icon(Icons.alternate_email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'אנא הזן שם משתמש';
                      }
                      if (value.trim().length < 3) {
                        return 'שם המשתמש צריך להכיל לפחות 3 תווים';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                        return 'שם המשתמש יכול להכיל אותיות, ספרות ו_ בלבד';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // שדה טלפון
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'מספר טלפון',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'אנא הזן מספר טלפון';
                      }
                      if (!RegExp(r'^[0-9]{10}$').hasMatch(value.replaceAll(RegExp(r'[-\s]'), ''))) {
                        return 'אנא הזן מספר טלפון תקין (10 ספרות)';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // שדה כתובת
                  TextFormField(
                    controller: _addressController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'כתובת מגורים',
                      prefixIcon: const Icon(Icons.home_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'אנא הזן כתובת מגורים';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // בחירת סוג משתמש
                  DropdownButtonFormField<String>(
                    value: _selectedUserType,
                    decoration: InputDecoration(
                      labelText: 'סוג משתמש',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                    ),
                    dropdownColor: const Color(0xFF1E1E1E),
                    items: const [
                      DropdownMenuItem(
                        value: 'parent',
                        child: Text('הורה', style: TextStyle(color: Colors.white)),
                      ),
                      DropdownMenuItem(
                        value: 'student',
                        child: Text('תלמיד', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedUserType = value;
                        _relatedNameController.clear();
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'אנא בחר סוג משתמש';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // שדה שם קשור (הורה/תלמיד)
                  if (_selectedUserType != null)
                    TextFormField(
                      controller: _relatedNameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: _selectedUserType == 'parent' 
                            ? 'שם התלמיד' 
                            : 'שם ההורה',
                        prefixIcon: const Icon(Icons.family_restroom_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return _selectedUserType == 'parent'
                              ? 'אנא הזן שם התלמיד'
                              : 'אנא הזן שם ההורה';
                        }
                        return null;
                      },
                    ),
                  
                  if (_selectedUserType != null)
                    const SizedBox(height: 16),
                  
                  const SizedBox(height: 16),
                  
                  // שדה סיסמה
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'סיסמה',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'אנא הזן סיסמה';
                      }
                      if (value.length < 6) {
                        return 'הסיסמה צריכה להכיל לפחות 6 תווים';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // שדה אימות סיסמה
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signUp(),
                    decoration: InputDecoration(
                      labelText: 'אימות סיסמה',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'אנא אמת את הסיסמה';
                      }
                      if (value != _passwordController.text) {
                        return 'הסיסמאות אינן זהות';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // כפתור הרשמה
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'הירשם',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // כפתור חזרה להתחברות
                  TextButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/login');
                      }
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: 'יש לך כבר חשבון? ',
                        style: TextStyle(color: Colors.white70),
                        children: [
                          TextSpan(
                            text: 'התחבר כאן',
                            style: TextStyle(
                              color: Color(0xFF00BCD4),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}