import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _supabase = Supabase.instance.client;
  
  Map<String, dynamic>? _contactInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
  }

  Future<void> _loadContactInfo() async {
    try {
      final response = await _supabase
          .from('contact_info')
          .select('*')
          .eq('is_active', true)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _contactInfo = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בטעינת פרטי יצירת הקשר: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'יצירת קשר',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // כותרת
                  const Text(
                    'צרו איתנו קשר',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'נשמח לעמוד לשירותכם בכל עת',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  if (_contactInfo != null) ...[
                    // פרטי קשר
                    _buildContactCard(
                      icon: Icons.phone,
                      title: 'טלפון',
                      content: _contactInfo!['phone'] ?? '',
                      onTap: () => _makePhoneCall(_contactInfo!['whatsapp_number']?.replaceAll('-', '') ?? ''),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildContactCard(
                      icon: Icons.email,
                      title: 'אימייל',
                      content: _contactInfo!['email'] ?? '',
                      onTap: () => _sendEmail(_contactInfo!['email'] ?? ''),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildContactCard(
                      icon: Icons.location_on,
                      title: 'כתובת',
                      content: _contactInfo!['address'] ?? '',
                      subtitle: 'לחצו לפתיחה במפות',
                      onTap: () => _openMap(_contactInfo!['address'] ?? ''),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildContactCard(
                      icon: Icons.access_time,
                      title: 'שעות פעילות',
                      content: _contactInfo!['working_hours'] ?? '',
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // תקשורת נוספת
                    const Text(
                      'תקשורת נוספת',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSocialButton(
                          icon: Icons.chat,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: () => _openWhatsApp(_contactInfo!['whatsapp_number']?.replaceAll('-', '') ?? ''),
                        ),
                        
                        _buildSocialButton(
                          icon: Icons.camera_alt,
                          label: 'Instagram',
                          color: const Color(0xFFE4405F),
                          onTap: () => _openInstagram(_contactInfo!['instagram_username'] ?? ''),
                        ),
                      ],
                    ),
                  ] else ...[
                    // הצגת מידע ברירת מחדל במקרה שאין מידע
                    const Center(
                      child: Text(
                        'טוען פרטי יצירת קשר...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
            
            const SizedBox(height: 32),
            
            // הודעה נוספת
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00BCD4),
                  width: 1,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.star,
                    color: Color(0xFFE91E63),
                    size: 32,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'נשמח לעזור לכם!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'צרו איתנו קשר בכל דרך שנוחה לכם, ואנחנו נחזור אליכם בהקדם',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String content,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
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
                      color: Color(0xFF00BCD4),
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            if (onTap != null)
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'פנייה מאפליקציית סטודיו שרון',
      },
    );
    await launchUrl(launchUri);
  }

  Future<void> _openMap(String address) async {
    final Uri launchUri = Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: '/maps/search/',
      queryParameters: {
        'api': '1',
        'query': address,
      },
    );
    await launchUrl(launchUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '/$phoneNumber',
      queryParameters: {
        'text': 'שלום, אני פונה מאפליקציית סטודיו שרון',
      },
    );
    await launchUrl(launchUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openInstagram([String? username]) async {
    final String instagramUsername = username ?? 'studio_sharon';
    final Uri launchUri = Uri(
      scheme: 'https',
      host: 'www.instagram.com',
      path: '/$instagramUsername',
    );
    await launchUrl(launchUri, mode: LaunchMode.externalApplication);
  }
}