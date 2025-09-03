import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  final _supabase = Supabase.instance.client;

  // בדיקה האם פריט הוא מועדף
  Future<bool> isFavorite(String contentType, String contentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('user_favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('content_type', contentType)
          .eq('content_id', contentId)
          .single();

      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // הוספה למועדפים
  Future<bool> addToFavorites(String contentType, String contentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.from('user_favorites').insert({
        'user_id': user.id,
        'content_type': contentType,
        'content_id': contentId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // הסרה מהמועדפים
  Future<bool> removeFromFavorites(String contentType, String contentId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('content_type', contentType)
          .eq('content_id', contentId);

      return true;
    } catch (e) {
      return false;
    }
  }

  // החלפת מצב מועדף
  Future<bool> toggleFavorite(String contentType, String contentId) async {
    final isFav = await isFavorite(contentType, contentId);
    
    if (isFav) {
      return await removeFromFavorites(contentType, contentId);
    } else {
      return await addToFavorites(contentType, contentId);
    }
  }

  // קבלת כל המועדפים של המשתמש
  Future<List<Map<String, dynamic>>> getUserFavorites(String contentType) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('user_favorites')
          .select('*')
          .eq('user_id', user.id)
          .eq('content_type', contentType)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}

// Provider לשירות המועדפים
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService();
});

// Provider למצב מועדף של פריט ספציפי
final favoriteStateProvider = FutureProvider.family<bool, Map<String, String>>((ref, params) async {
  final service = ref.read(favoritesServiceProvider);
  return await service.isFavorite(params['contentType']!, params['contentId']!);
});

// StateNotifier לניהול מצב מועדפים
class FavoritesNotifier extends StateNotifier<Map<String, bool>> {
  final FavoritesService _service;

  FavoritesNotifier(this._service) : super({});

  // עדכון מצב מועדף
  Future<void> toggleFavorite(String contentType, String contentId) async {
    final key = '${contentType}_$contentId';
    final currentState = state[key] ?? false;
    
    // עדכון אופטימיסטי
    state = {...state, key: !currentState};
    
    // ביצוע הפעולה
    final success = await _service.toggleFavorite(contentType, contentId);
    
    // אם נכשל, החזר למצב הקודם
    if (!success) {
      state = {...state, key: currentState};
    }
  }

  // טעינת מצב מועדף
  Future<void> loadFavoriteState(String contentType, String contentId) async {
    final key = '${contentType}_$contentId';
    final isFavorite = await _service.isFavorite(contentType, contentId);
    state = {...state, key: isFavorite};
  }
}

final favoritesNotifierProvider = StateNotifierProvider<FavoritesNotifier, Map<String, bool>>((ref) {
  final service = ref.read(favoritesServiceProvider);
  return FavoritesNotifier(service);
});