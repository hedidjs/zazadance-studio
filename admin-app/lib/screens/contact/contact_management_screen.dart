import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContactManagementScreen extends StatefulWidget {
  const ContactManagementScreen({super.key});

  @override
  State<ContactManagementScreen> createState() => _ContactManagementScreenState();
}

class _ContactManagementScreenState extends State<ContactManagementScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _workingHoursController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _instagramController = TextEditingController();
  
  Map<String, dynamic>? _currentContact;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _workingHoursController.dispose();
    _whatsappController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  Future<void> _loadContactInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _supabase
          .from('contact_info')
          .select('*')
          .eq('is_active', true)
          .maybeSingle();

      if (mounted && response != null) {
        setState(() {
          _currentContact = response;
          _phoneController.text = response['phone'] ?? '';
          _emailController.text = response['email'] ?? '';
          _addressController.text = response['address'] ?? '';
          _workingHoursController.text = response['working_hours'] ?? '';
          _whatsappController.text = response['whatsapp_number'] ?? '';
          _instagramController.text = response['instagram_username'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('שגיאה בטעינת פרטי יצירת הקשר: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveContactInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final data = {
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'working_hours': _workingHoursController.text.trim(),
        'whatsapp_number': _whatsappController.text.trim(),
        'instagram_username': _instagramController.text.trim(),
        'is_active': true,
      };

      if (_currentContact != null) {
        // Update existing contact
        await _supabase
            .from('contact_info')
            .update(data)
            .eq('id', _currentContact!['id']);
      } else {
        // Insert new contact (deactivate old ones first)
        await _supabase
            .from('contact_info')
            .update({'is_active': false})
            .eq('is_active', true);

        await _supabase
            .from('contact_info')
            .insert(data);
      }

      if (mounted) {
        _showSuccessSnackBar('פרטי יצירת הקשר נשמרו בהצלחה!');
        _loadContactInfo(); // Reload to get updated data
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('שגיאה בשמירת פרטי יצירת הקשר: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
        title: const Text('ניהול פרטי יצירת קשר'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'מספר טלפון',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'אנא הזן מספר טלפון';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'כתובת אימייל',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'אנא הזן כתובת אימייל';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'אנא הזן כתובת אימייל תקינה';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'כתובת',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'אנא הזן כתובת';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Working Hours
                      TextFormField(
                        controller: _workingHoursController,
                        decoration: const InputDecoration(
                          labelText: 'שעות פעילות',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'אנא הזן שעות פעילות';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // WhatsApp Number
                      TextFormField(
                        controller: _whatsappController,
                        decoration: const InputDecoration(
                          labelText: 'מספר וואטסאפ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'אנא הזן מספר וואטסאפ';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Instagram Username
                      TextFormField(
                        controller: _instagramController,
                        decoration: const InputDecoration(
                          labelText: 'שם משתמש אינסטגרם',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'אנא הזן שם משתמש אינסטגרם';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveContactInfo,
                          child: _isSaving
                              ? const CircularProgressIndicator()
                              : const Text('שמור פרטי יצירת קשר'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}