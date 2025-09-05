import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class PublicContactScreenDb extends StatefulWidget {
  const PublicContactScreenDb({super.key});

  @override
  State<PublicContactScreenDb> createState() => _PublicContactScreenDbState();
}

class _PublicContactScreenDbState extends State<PublicContactScreenDb> {
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
      setState(() {
        _isLoading = true;
      });

      // Try to get contact info from database, fallback to hardcoded values
      final response = await _supabase
          .from('studio_info')
          .select('*')
          .eq('is_active', true)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _contactInfo = response ?? {
            'studio_name': 'ZaZa Dance',
            'owner_name': 'שרון צרפתי',
            'owner_title': 'מנהלת הסטודיו',
            'phone': '0527274321',
            'email': 'sharon.art6263@gmail.com',
            'address': 'השקד 68, בית עזרא',
            'hours_sunday_thursday': 'ימים א-ה: 16:00-21:00',
            'hours_friday': 'יום ו: 09:00-13:00',
            'hours_saturday': 'שבת: סגור',
            'description': 'ניתן לפנות אלינו בכל שאלה לגבי השיעורים, ההרשמות או כל נושא אחר.'
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { 
          // Fallback to hardcoded contact info
          _contactInfo = {
            'studio_name': 'ZaZa Dance',
            'owner_name': 'שרון צרפתי',
            'owner_title': 'מנהלת הסטודיו',
            'phone': '0527274321',
            'email': 'sharon.art6263@gmail.com',
            'address': 'השקד 68, בית עזרא',
            'hours_sunday_thursday': 'ימים א-ה: 16:00-21:00',
            'hours_friday': 'יום ו: 09:00-13:00',
            'hours_saturday': 'שבת: סגור',
            'description': 'ניתן לפנות אלינו בכל שאלה לגבי השיעורים, ההרשמות או כל נושא אחר.'
          };
          _isLoading = false;
        });
        print('Error loading contact info: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('יצירת קשר'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'יצירת קשר - ${_contactInfo?['studio_name'] ?? 'ZaZa Dance'}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.pink),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _contactInfo?['owner_name'] ?? 'שרון צרפתי',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(_contactInfo?['owner_title'] ?? 'מנהלת הסטודיו'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.pink),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _contactInfo?['phone'] ?? '0527274321',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('טלפון נייד'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.email, color: Colors.pink),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _contactInfo?['email'] ?? 'sharon.art6263@gmail.com',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('אימייל'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Colors.pink),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _contactInfo?['address'] ?? 'השקד 68, בית עזרא',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('הסטודיו שלנו'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'זמני פעילות',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_contactInfo?['hours_sunday_thursday'] ?? 'ימים א-ה: 16:00-21:00'),
                  Text(_contactInfo?['hours_friday'] ?? 'יום ו: 09:00-13:00'),
                  Text(_contactInfo?['hours_saturday'] ?? 'שבת: סגור'),
                  const SizedBox(height: 32),
                  Text(
                    _contactInfo?['description'] ?? 'ניתן לפנות אלינו בכל שאלה לגבי השיעורים, ההרשמות או כל נושא אחר.',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
    );
  }
}