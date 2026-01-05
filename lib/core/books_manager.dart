import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BooksManager {
  static final BooksManager _instance = BooksManager._internal();
  factory BooksManager() => _instance;
  BooksManager._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Cached books with ValueNotifier for reactivity
  final ValueNotifier<List<Map<String, dynamic>>> allBooks = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  // Fetch all books
  Future<void> fetchBooks() async {
    isLoading.value = true;
    try {
      final List<dynamic> data = await _supabase
          .from('books')
          .select()
          .order('title', ascending: true);

      allBooks.value = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching books: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Helper to search/filter locally (can be moved to backend for larger datasets)
  List<Map<String, dynamic>> filterBooks(String query, String category) {
    return allBooks.value.where((book) {
      final title = (book['title'] ?? '').toString().toLowerCase();
      final author = (book['author'] ?? '').toString().toLowerCase();
      final bookCategory = (book['category'] ?? 'General').toString();
      
      final matchesQuery = title.contains(query.toLowerCase()) || 
                           author.contains(query.toLowerCase());
      
      final matchesCategory = category == 'All' || bookCategory == category;

      return matchesQuery && matchesCategory;
    }).toList();
  }
  // Upload Book Cover
  Future<String?> uploadBookCover(dynamic imageFile) async {
    try {
      // Using 'avatars' bucket with 'book_covers' subfolder for book cover images
      final fileName = 'book_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('avatars').upload(fileName, imageFile);
      return _supabase.storage.from('avatars').getPublicUrl(fileName);
    } catch (e) {
      if (kDebugMode) print('Error uploading cover: $e');
      return null;
    }
  }

  // Add Book
  Future<void> addBook(Map<String, dynamic> bookData) async {
    try {
      await _supabase.from('books').insert(bookData);
      await fetchBooks(); // Refresh list

      // Notify All Users
      // 1. Fetch all user IDs
      final profiles = await _supabase.from('profiles').select('id');
      final List<Map<String, dynamic>> notificationsToAdd = [];

      for (var p in profiles as List) {
        notificationsToAdd.add({
          'user_id': p['id'],
          'title': 'New Book Added',
          'message': 'Check out "${bookData['title']}" by ${bookData['author']}',
          'type': 'star', // Special icon? or info
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 2. Batch Insert
      if (notificationsToAdd.isNotEmpty) {
        await _supabase.from('notifications').insert(notificationsToAdd);
      }

    } catch (e) {
      if (kDebugMode) print('Error adding book: $e');
      rethrow;
    }
  }

  // Update Book
  Future<void> updateBook(String id, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('books').update(updates).eq('id', id);
      await fetchBooks(); // Refresh list
    } catch (e) {
      if (kDebugMode) print('Error updating book: $e');
      rethrow;
    }
  }

  // Delete Book
  Future<void> deleteBook(String id) async {
    try {
      await _supabase.from('books').delete().eq('id', id);
      await fetchBooks(); // Refresh list
    } catch (e) {
      if (kDebugMode) print('Error deleting book: $e');
      rethrow;
    }
  }
}
