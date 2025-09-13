import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthChangeNotifier extends ChangeNotifier {
  User? _user = Supabase.instance.client.auth.currentUser;
  
  User? get user => _user;
  
  AuthChangeNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }
}

final authChangeNotifierProvider = ChangeNotifierProvider<AuthChangeNotifier>((ref) {
  return AuthChangeNotifier();
});

final authProvider = Provider<User?>((ref) {
  return ref.watch(authChangeNotifierProvider).user;
});

// Provider שבודק אם המשתמש מאושר
final isUserApprovedProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authProvider);
  
  if (user == null) {
    return false;
  }
  
  try {
    final response = await Supabase.instance.client
        .from('users')
        .select('is_approved')
        .eq('id', user.id)
        .maybeSingle();
    
    return response?['is_approved'] ?? false;
  } catch (e) {
    print('Error checking user approval: $e');
    return false;
  }
});