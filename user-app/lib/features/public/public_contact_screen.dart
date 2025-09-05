import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PublicContactScreen extends StatelessWidget {
  const PublicContactScreen({super.key});

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
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'יצירת קשר - ZaZa Dance',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.person, color: Colors.pink),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'שרון צרפתי',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('מנהלת הסטודיו'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.pink),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '0527274321',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('טלפון נייד'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, color: Colors.pink),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'sharon.art6263@gmail.com',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('אימייל'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: Colors.pink),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'השקד 68, בית עזרא',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('הסטודיו שלנו'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            Text(
              'זמני פעילות',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('ימים א-ה: 16:00-21:00'),
            Text('יום ו: 09:00-13:00'),
            Text('שבת: סגור'),
            SizedBox(height: 32),
            Text(
              'ניתן לפנות אלינו בכל שאלה לגבי השיעורים, ההרשמות או כל נושא אחר.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}