import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesManager {
  static final FavoritesManager _instance = FavoritesManager._internal();
  factory FavoritesManager() => _instance;
  FavoritesManager._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ValueNotifier<List<Map<String, dynamic>>> favoriteBooks = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  // Fetch favorites from Supabase
  Future<void> fetchFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    isLoading.value = true;
    try {
      final response = await _supabase
          .from('favorites')
          .select('*, books(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> loadedFavorites = [];
      
      for (var fav in response as List) {
        final book = fav['books'];
        if (book != null) {
          loadedFavorites.add({
            'id': book['id'],
            'title': book['title'],
            'author': book['author'],
            'imageUrl': book['image_url'], // Map snake_case from DB
            'availableCopies': book['available_copies'] ?? 0, // Map snake_case
            'fav_id': fav['id'], // Store the favorite record ID for deletion
          });
        }
      }
      
      favoriteBooks.value = loadedFavorites;
    } catch (e) {
      if (kDebugMode) print('Error fetching favorites: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle Favorite (Add/Remove)
  Future<void> toggleFavorite(Map<String, dynamic> book) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final String bookId = book['id'];
    
    // Check if already favorite locally to update UI immediately (optimistic update)
    final bool isCurrentlyFav = isFavorite(book['title'], book['author'], id: bookId);
    
    // Optimistic Update
    final List<Map<String, dynamic>> currentList = List.from(favoriteBooks.value);
    if (isCurrentlyFav) {
      currentList.removeWhere((element) => element['id'] == bookId);
    } else {
      currentList.insert(0, book); // Add to top
    }
    favoriteBooks.value = currentList;

    try {
      if (isCurrentlyFav) {
        // Remove from DB
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('book_id', bookId);
      } else {
        // Add to DB
        await _supabase.from('favorites').insert({
          'user_id': user.id,
          'book_id': bookId,
        });
      }
      // Refresh to ensure sync (optional, but good for consistency)
      // await fetchFavorites(); 
    } catch (e) {
      if (kDebugMode) print('Error toggling favorite: $e');
      // Revert optimistic update on error would be ideal here
      fetchFavorites(); // Re-fetch to true state
    }
  }

  bool isFavorite(String title, String author, {String? id}) {
    return favoriteBooks.value.any((element) {
      if (id != null && element.containsKey('id')) {
        return element['id'] == id;
      }
      // Fallback (though generally we should have IDs now)
      return element['title'] == title && element['author'] == author;
    });
  }
}
