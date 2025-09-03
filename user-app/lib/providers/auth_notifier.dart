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