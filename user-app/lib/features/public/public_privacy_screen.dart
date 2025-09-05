import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PublicPrivacyScreen extends StatelessWidget {
  const PublicPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('מדיניות פרטיות'),
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
              'מדיניות פרטיות - ZaZa Dance',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'מדיניות הפרטיות תתעדכן בקרוב...',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'אפליקציית ZaZa Dance מתחייבת לשמור על פרטיותכם ולהגן על המידע האישי שלכם.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'לשאלות נוספות, אנא פנו אלינו דרך דף יצירת הקשר.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}