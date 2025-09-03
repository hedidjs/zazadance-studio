import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class GeneralManagementScreen extends StatefulWidget {
  const GeneralManagementScreen({super.key});

  @override
  State<GeneralManagementScreen> createState() => _GeneralManagementScreenState();
}

class _GeneralManagementScreenState extends State<GeneralManagementScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  final _appNameController = TextEditingController();
  final _appDescriptionController = TextEditingController();
  final _appSubtitleController = TextEditingController();
  
  Map<String, dynamic>? _currentConfig;
  bool _isLoading = false;
  bool _isSaving = false;
  
  String? _selectedLogoPath;
  String? _selectedIconPath;
  Uint8List? _selectedLogoBytes;
  Uint8List? _selectedIconBytes;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _appDescriptionController.dispose();
    _appSubtitleController.dispose();
    super.dispose();
  }

  Future<void> _loadConfiguration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _supabase
          .from('app_configuration')
          .select('*')
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _currentConfig = response;
          _appNameController.text = response['app_name'] ?? '';
          _appDescriptionController.text = response['app_description'] ?? '';
          _appSubtitleController.text = response['app_subtitle'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('שגיאה בטעינת ההגדרות: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickLogo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _selectedLogoPath = result.files.single.name;
        _selectedLogoBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _pickIcon() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _selectedIconPath = result.files.single.name;
        _selectedIconBytes = result.files.single.bytes;
      });
    }
  }

  Future<String?> _uploadFile(Uint8List bytes, String bucket, String fileName) async {
    try {
      // העלאה עם overwrite אם הקובץ קיים
      await _supabase.storage
          .from(bucket)
          .uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));
      
      final publicUrl = _supabase.storage
          .from(bucket)
          .getPublicUrl(fileName);
      
      return publicUrl;
    } catch (e) {
      _showErrorSnackBar('שגיאה בהעלאת הקובץ: $e');
      return null;
    }
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final data = {
        'app_name': _appNameController.text,
        'app_description': _appDescriptionController.text,
        'app_subtitle': _appSubtitleController.text,
      };

      // העלאת לוגו אם נבחר
      if (_selectedLogoBytes != null) {
        final logoUrl = await _uploadFile(
          _selectedLogoBytes!, 
          'app-assets', 
          'logo_${DateTime.now().millisecondsSinceEpoch}.png'
        );
        if (logoUrl != null) {
          data['app_logo_url'] = logoUrl;
        }
      }

      // העלאת אייקון אם נבחר
      if (_selectedIconBytes != null) {
        final iconUrl = await _uploadFile(
          _selectedIconBytes!, 
          'app-assets', 
          'icon_${DateTime.now().millisecondsSinceEpoch}.png'
        );
        if (iconUrl != null) {
          data['app_icon_url'] = iconUrl;
        }
      }

      if (_currentConfig != null) {
        // עדכון רשומה קיימת
        await _supabase
            .from('app_configuration')
            .update(data)
            .eq('id', _currentConfig!['id']);
      } else {
        // יצירת רשומה חדשה
        await _supabase
            .from('app_configuration')
            .insert(data);
      }

      if (mounted) {
        _showSuccessSnackBar('ההגדרות נשמרו בהצלחה!');
        _selectedLogoPath = null;
        _selectedIconPath = null;
        _selectedLogoBytes = null;
        _selectedIconBytes = null;
        _loadConfiguration(); // טעינה מחדש של הנתונים
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('שגיאה בשמירת ההגדרות: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE91E63),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // כותרת ראשית
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE91E63),
                        Color(0xFF00BCD4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ניהול כללי',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'הגדרות כלליות של האפליקציה',
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
            
            const SizedBox(height: 32),

            // קארד הגדרות בסיסיות
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF00BCD4),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'פרטי האפליקציה',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // שם האפליקציה
                    _buildTextField(
                      controller: _appNameController,
                      label: 'שם האפליקציה',
                      icon: Icons.apps,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'שם האפליקציה הוא שדה חובה';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // תיאור האפליקציה
                    _buildTextField(
                      controller: _appDescriptionController,
                      label: 'תיאור האפליקציה',
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // כותרת משנה
                    _buildTextField(
                      controller: _appSubtitleController,
                      label: 'כותרת משנה',
                      icon: Icons.title,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // קארד תמונות
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.image_outlined,
                          color: Color(0xFF00BCD4),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'תמונות האפליקציה',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // העלאת לוגו
                    _buildFileUploadCard(
                      title: 'לוגו האפליקציה',
                      description: 'לוגו שיוצג במסכי הכניסה והרשמה',
                      currentUrl: _currentConfig?['app_logo_url'],
                      selectedPath: _selectedLogoPath,
                      onTap: _pickLogo,
                      icon: Icons.account_balance,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // העלאת אייקון
                    _buildFileUploadCard(
                      title: 'אייקון האפליקציה',
                      description: 'אייקון שיוצג במכשיר המשתמש',
                      currentUrl: _currentConfig?['app_icon_url'],
                      selectedPath: _selectedIconPath,
                      onTap: _pickIcon,
                      icon: Icons.apps,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // כפתור שמירה
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveConfiguration,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'שומר...' : 'שמור הגדרות'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFF00BCD4)),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE91E63)),
        ),
      ),
    );
  }

  Widget _buildFileUploadCard({
    required String title,
    required String description,
    required String? currentUrl,
    required String? selectedPath,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // תצוגה מקדימה או אייקון
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: currentUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          currentUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              icon,
                              color: Colors.white,
                              size: 24,
                            );
                          },
                        ),
                      )
                    : Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    
                    if (selectedPath != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'קובץ חדש נבחר',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ] else if (currentUrl != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'קובץ קיים',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const Icon(
                Icons.upload_file,
                color: Color(0xFF00BCD4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}