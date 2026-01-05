import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'requests_manager.dart'; // Import RequestsManager

class BorrowedBooksManager {
  static final BorrowedBooksManager _instance = BorrowedBooksManager._internal();
  factory BorrowedBooksManager() => _instance;
  BorrowedBooksManager._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ValueNotifier<List<Map<String, dynamic>>> borrowedBooks = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> historyBooks = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  // Fetch active loans from Supabase
  Future<void> fetchBorrowedBooks() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    isLoading.value = true;
    try {
      final response = await _supabase
          .from('loan_transactions')
          .select('*, books(*)')
          .eq('user_id', user.id)
          .inFilter('status', ['active_loan', 'pending_return']) // Show active and those waiting return approval
          .order('due_date', ascending: true);

      final List<Map<String, dynamic>> loadedBooks = [];
      
      for (var loan in response as List) {
        final book = loan['books'];
        if (book != null) {
          loadedBooks.add({
            'id': book['id'], // Book ID
            'loan_id': loan['id'], // Loan Transaction ID
            'title': book['title'],
            'author': book['author'],
            'imageUrl': book['image_url'],
            'dueDate': _formatDate(loan['due_date']),
            'isReturnPending': loan['status'] == 'pending_return',
          });
        }
      }
      
      borrowedBooks.value = loadedBooks;
      
    } catch (e) {
      if (kDebugMode) print('Error fetching borrowed books: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch history (returned books)
  Future<void> fetchHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    isLoading.value = true;
    try {
      final response = await _supabase
          .from('loan_transactions')
          .select('*, books(*)')
          .eq('user_id', user.id)
          .eq('status', 'returned')
          .order('return_date', ascending: false);

      final List<Map<String, dynamic>> loadedHistory = [];
      
      for (var loan in response as List) {
        final book = loan['books'];
        if (book != null) {
          loadedHistory.add({
            'id': book['id'],
            'title': book['title'],
            'author': book['author'],
            'imageUrl': book['image_url'],
            'returnedDate': _formatDate(loan['return_date']),
            'rating': loan['review_rating'] ?? 0,
          });
        }
      }
      
      historyBooks.value = loadedHistory;
    } catch (e) {
      if (kDebugMode) print('Error fetching history: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Borrow a book (Create active loan)
  Future<bool> borrowBook({
    required String bookId,
    required DateTime returnDate,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await _supabase.from('loan_transactions').insert({
        'user_id': user.id,
        'book_id': bookId,
        'status': 'pending_borrow', // User request, pending approval
        'request_date': DateTime.now().toIso8601String(),
        'due_date': returnDate.toIso8601String(),
      });
      
      // Refresh list
      await fetchBorrowedBooks();
      // Also refresh RequestsManager as this new item is a "pending request"
      await RequestsManager().fetchRequests();
      return true;
    } catch (e) {
      if (kDebugMode) print('Error borrowing book: $e');
      return false;
    }
  }

  // Mark book as pending return
  Future<bool> markAsReturnPending(String bookId) async {
    // Find the loan transaction for this book
    try {
        final loan = borrowedBooks.value.firstWhere((b) => b['id'] == bookId);
        final String loanId = loan['loan_id'];

        await _supabase.from('loan_transactions').update({
          'status': 'pending_return',
          'return_date': DateTime.now().toIso8601String(),
        }).eq('id', loanId);

        await fetchBorrowedBooks();
        return true;
    } catch (e) {
       if (kDebugMode) print('Error checking return: $e');
       return false;
    }
  }

  bool isBookBorrowed(String bookId) {
    return borrowedBooks.value.any((element) => element['id'] == bookId);
  }

  Map<String, dynamic>? getBorrowedBook(String bookId) {
    try {
      return borrowedBooks.value.firstWhere((element) => element['id'] == bookId);
    } catch (e) {
      return null;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day} ${_getMonth(date.month)} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
