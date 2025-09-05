import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class PublicTermsScreen extends StatefulWidget {
  final int? initialTab;
  
  const PublicTermsScreen({super.key, this.initialTab});

  @override
  State<PublicTermsScreen> createState() => _PublicTermsScreenState();
}

class _PublicTermsScreenState extends State<PublicTermsScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  
  late TabController _tabController;
  
  Map<String, dynamic>? _termsContent;
  Map<String, dynamic>? _privacyContent;
  Map<String, dynamic>? _disclaimerContent;
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final int initialIndex = widget.initialTab ?? 0;
    _tabController = TabController(
      length: 3, 
      vsync: this,
      initialIndex: initialIndex.clamp(0, 2),
    );
    _loadAllContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllContent() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await _supabase
          .from('terms_content')
          .select('*')
          .eq('is_active', true)
          .order('content_type');

      if (mounted) {
        final contents = List<Map<String, dynamic>>.from(response);
        
        setState(() {
          _termsContent = contents.where((c) => c['content_type'] == 'terms').firstOrNull;
          _privacyContent = contents.where((c) => c['content_type'] == 'privacy').firstOrNull;
          _disclaimerContent = contents.where((c) => c['content_type'] == 'disclaimer').firstOrNull;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        // Silent fail for public pages
        print('Error loading content: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('תקנון ופרטיות'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.description_outlined), text: 'תנאי שימוש'),
            Tab(icon: Icon(Icons.privacy_tip_outlined), text: 'פרטיות'),
            Tab(icon: Icon(Icons.warning_outlined), text: 'הסבר אחריות'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildContentView(_termsContent, 'תנאי שימוש'),
                _buildContentView(_privacyContent, 'מדיניות פרטיות'),
                _buildContentView(_disclaimerContent, 'הסבר אחריות'),
              ],
            ),
    );
  }

  Widget _buildContentView(Map<String, dynamic>? content, String title) {
    if (content == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'תוכן לא זמין',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'התוכן עדיין לא הוגדר או אינו זמין כרגע',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content['title_he'] ?? title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (content['effective_date'] != null) ...[
            Text(
              'בתוקף מתאריך: ${_formatDate(content['effective_date'])}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            content['content_he'] ?? 'תוכן לא זמין',
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          if (content['updated_at'] != null)
            Text(
              'עודכן לאחרונה: ${_formatDateTime(content['updated_at'])}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} בשעה ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}