import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UpdatesManagementScreen extends ConsumerStatefulWidget {
  const UpdatesManagementScreen({super.key});

  @override
  ConsumerState<UpdatesManagementScreen> createState() => _UpdatesManagementScreenState();
}

class _UpdatesManagementScreenState extends ConsumerState<UpdatesManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'ניהול עדכונים',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'בקרוב...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}