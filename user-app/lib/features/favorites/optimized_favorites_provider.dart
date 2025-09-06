import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Optimized favorites state that only rebuilds when necessary
class FavoritesNotifier extends ChangeNotifier {
  final Map<String, bool> _favoriteStates = {};
  final Set<String> _loadingKeys = {};
  bool _isLoading = false;

  Map<String, bool> get favoriteStates => Map.unmodifiable(_favoriteStates);
  bool get isLoading => _isLoading;

  /// Check if a specific favorite is currently loading
  bool isLoadingFavorite(String key) => _loadingKeys.contains(key);

  /// Load favorite state for a specific item without rebuilding the entire state
  Future<void> loadFavoriteState(String type, String itemId) async {
    final key = '${type}_$itemId';
    
    // Don't reload if we already have this state
    if (_favoriteStates.containsKey(key)) return;
    
    try {
      _loadingKeys.add(key);
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _favoriteStates[key] = false;
        return;
      }

      final response = await Supabase.instance.client
          .from('user_favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('item_type', type)
          .eq('item_id', itemId)
          .maybeSingle();

      _favoriteStates[key] = response != null;
      
      // Only notify listeners if this is a new state change
      notifyListeners();
    } catch (e) {
      _favoriteStates[key] = false;
    } finally {
      _loadingKeys.remove(key);
    }
  }

  /// Toggle favorite status with optimistic updates
  Future<void> toggleFavorite(String type, String itemId) async {
    final key = '${type}_$itemId';
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Optimistic update - update UI immediately
    final wasAlreadyFavorite = _favoriteStates[key] ?? false;
    _favoriteStates[key] = !wasAlreadyFavorite;
    notifyListeners();

    try {
      _loadingKeys.add(key);
      
      if (wasAlreadyFavorite) {
        // Remove favorite
        await Supabase.instance.client
            .from('user_favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('item_type', type)
            .eq('item_id', itemId);
      } else {
        // Add favorite
        await Supabase.instance.client
            .from('user_favorites')
            .insert({
              'user_id': user.id,
              'item_type': type,
              'item_id': itemId,
              'created_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      // Revert optimistic update on error
      _favoriteStates[key] = wasAlreadyFavorite;
      notifyListeners();
      
      // Could throw or show error message here
      debugPrint('Failed to toggle favorite: $e');
    } finally {
      _loadingKeys.remove(key);
    }
  }

  /// Batch load multiple favorite states efficiently
  Future<void> loadMultipleFavoriteStates(String type, List<String> itemIds) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Filter out items we already have
    final itemsToLoad = itemIds.where((id) => !_favoriteStates.containsKey('${type}_$id')).toList();
    if (itemsToLoad.isEmpty) return;

    try {
      _isLoading = true;
      notifyListeners();

      final response = await Supabase.instance.client
          .from('user_favorites')
          .select('item_id')
          .eq('user_id', user.id)
          .eq('item_type', type)
          .in_('item_id', itemsToLoad);

      final favoriteIds = response.map((item) => item['item_id'] as String).toSet();

      // Update all states in batch
      for (final itemId in itemsToLoad) {
        _favoriteStates['${type}_$itemId'] = favoriteIds.contains(itemId);
      }

      notifyListeners();
    } catch (e) {
      // Set all as false on error
      for (final itemId in itemsToLoad) {
        _favoriteStates['${type}_$itemId'] = false;
      }
      debugPrint('Failed to load favorite states: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get all favorite items of a specific type
  Future<List<String>> getFavoriteItems(String type) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await Supabase.instance.client
          .from('user_favorites')
          .select('item_id')
          .eq('user_id', user.id)
          .eq('item_type', type)
          .order('created_at', ascending: false);

      return response.map((item) => item['item_id'] as String).toList();
    } catch (e) {
      debugPrint('Failed to get favorite items: $e');
      return [];
    }
  }

  /// Clear all favorite states (useful when user logs out)
  void clearStates() {
    _favoriteStates.clear();
    _loadingKeys.clear();
    _isLoading = false;
    notifyListeners();
  }

  /// Preload favorites for better UX
  Future<void> preloadFavorites(String type) async {
    final favoriteIds = await getFavoriteItems(type);
    for (final id in favoriteIds) {
      _favoriteStates['${type}_$id'] = true;
    }
    notifyListeners();
  }
}

/// Provider for the optimized favorites notifier
final optimizedFavoritesNotifierProvider = ChangeNotifierProvider<FavoritesNotifier>((ref) {
  return FavoritesNotifier();
});

/// Selector provider to only rebuild widgets when specific favorite changes
final specificFavoriteProvider = Provider.family<bool, String>((ref, key) {
  final favorites = ref.watch(optimizedFavoritesNotifierProvider);
  return favorites.favoriteStates[key] ?? false;
});

/// Provider to check if a specific favorite is loading
final favoriteLoadingProvider = Provider.family<bool, String>((ref, key) {
  final favorites = ref.watch(optimizedFavoritesNotifierProvider);
  return favorites.isLoadingFavorite(key);
});