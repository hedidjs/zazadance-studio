import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  late final GoogleSignIn _googleSignIn;
  final SupabaseClient _supabase = Supabase.instance.client;

  void initialize() {
    _googleSignIn = GoogleSignIn(
      // Client IDs לפלטפורמות שונות
      clientId: kIsWeb
          ? '409450161677-39sdbh03i11gvgljhdvbcf930cfovqeq.apps.googleusercontent.com' // Web
          : null, // For mobile platforms, use the configuration files
      serverClientId: '409450161677-39sdbh03i11gvgljhdvbcf930cfovqeq.apps.googleusercontent.com', // Web client ID for server
    );
  }

  /// התחברות דרך Google והתחברות לSupabase
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // קודם התנתקות כדי לאפשר בחירת חשבון שונה
      await _googleSignIn.signOut();
      
      // התחברות דרך Google עם אפשרות בחירת חשבון
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // המשתמש ביטל את ההתחברות
        return null;
      }

      // קבלת tokens מGoogle
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception('לא ניתן לקבל ID token מGoogle');
      }

      // התחברות לSupabase עם Google credentials
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // יצירת/עדכון פרופיל המשתמש בטבלת users
      if (response.user != null) {
        await _createOrUpdateUserProfile(response.user!, googleUser);
      }

      return response;
    } catch (e) {
      debugPrint('שגיאה בהתחברות Google: $e');
      rethrow;
    }
  }

  /// התנתקות מGoogle ומSupabase
  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _supabase.auth.signOut(),
      ]);
    } catch (e) {
      debugPrint('שגיאה בהתנתקות: $e');
      rethrow;
    }
  }

  /// בדיקה האם המשתמש מחובר דרך Google
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// קבלת המשתמש הנוכחי מGoogle
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// הכנה מראש של Google Sign-In (אופציונלי)
  Future<void> signInSilently() async {
    try {
      await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
    }
  }

  /// יצירת/עדכון פרופיל משתמש בטבלת users
  Future<void> _createOrUpdateUserProfile(User supabaseUser, GoogleSignInAccount googleUser) async {
    try {
      // בדיקה אם המשתמש כבר קיים
      final existingUser = await _supabase
          .from('users')
          .select('id')
          .eq('id', supabaseUser.id)
          .maybeSingle();

      final userProfile = {
        'id': supabaseUser.id,
        'email': googleUser.email,
        'full_name': googleUser.displayName ?? googleUser.email.split('@')[0],
        'display_name': googleUser.displayName ?? googleUser.email.split('@')[0],
        'profile_image_url': googleUser.photoUrl,
        'avatar_url': googleUser.photoUrl,
        'role': 'student',
        'auth_provider': 'google',
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existingUser == null) {
        // משתמש חדש - יצירה
        userProfile['created_at'] = DateTime.now().toIso8601String();
        
        await _supabase.from('users').insert(userProfile);
        debugPrint('נוצר פרופיל חדש למשתמש Google: ${googleUser.displayName}');
      } else {
        // משתמש קיים - עדכון
        await _supabase
            .from('users')
            .update(userProfile)
            .eq('id', supabaseUser.id);
        debugPrint('עודכן פרופיל משתמש Google: ${googleUser.displayName}');
      }
    } catch (e) {
      debugPrint('שגיאה ביצירת/עדכון פרופיל משתמש: $e');
      // לא זורקים שגיאה כדי לא לחסום את ההתחברות
    }
  }
}