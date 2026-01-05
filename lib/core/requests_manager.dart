import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/request_book_card.dart'; // For RequestStatus enum
import 'notifications_manager.dart'; // Import

class RequestsManager {
  static final RequestsManager _instance = RequestsManager._internal();
  factory RequestsManager() => _instance;
  RequestsManager._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ValueNotifier<List<Map<String, dynamic>>> requests = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  // Fetch requests (pending, hold, rejected, cancelled)
  Future<void> fetchRequests() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    isLoading.value = true;
    try {
      final response = await _supabase
          .from('loan_transactions')
          .select('*, books(*)')
          .eq('user_id', user.id)
          .inFilter('status', ['pending_borrow', 'hold', 'rejected', 'cancelled'])
          .order('request_date', ascending: false);

      final List<Map<String, dynamic>> loadedRequests = [];

      for (var loan in response as List) {
        final book = loan['books'];
        if (book != null) {
          loadedRequests.add({
            'id': loan['id'], // Loan/Request ID
            'book_id': book['id'],
            'title': book['title'],
            'author': book['author'],
            'imageUrl': book['image_url'],
            'returnDate': _formatReturnDate(loan['due_date']), // Requested return date
            'status': _mapStatus(loan['status']),
          });
        }
      }
      requests.value = loadedRequests;
    } catch (e) {
      if (kDebugMode) print('Error fetching requests: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Remove request (Delete if pending/hold, or just hide if rejected/cancelled?? 
  // User said "slide left to delete", enabling user to clear history of requests)
  Future<bool> removeRequest(String loanId) async {
    try {
      await _supabase.from('loan_transactions').delete().eq('id', loanId);
      
      // Update local state immediately
      final currentList = List<Map<String, dynamic>>.from(requests.value);
      currentList.removeWhere((item) => item['id'] == loanId);
      requests.value = currentList;
      
      return true;
    } catch (e) {
      if (kDebugMode) print('Error removing request: $e');
      return false;
    }
  }
  
  // Helper to map DB string to Enum
  RequestStatus _mapStatus(String status) {
    switch (status) {
      case 'pending_borrow': return RequestStatus.pending;
      case 'hold': return RequestStatus.hold;
      case 'rejected': return RequestStatus.canceled; // Assuming rejected maps to cancelled UI for now or add rejected to enum?
      case 'cancelled': return RequestStatus.canceled; // Using cancelled for rejected/cancelled
      default: return RequestStatus.pending;
    }
  }

  String _formatReturnDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
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

  Map<String, dynamic>? getRequestForBook(String bookId) {
    try {
      return requests.value.firstWhere(
        (req) => req['book_id'] == bookId && req['status'] != RequestStatus.canceled,
      );
    } catch (_) {
      return null;
    }
  }
  // Librarian: Fetch ALL requests
  final ValueNotifier<List<Map<String, dynamic>>> librarianRequests = ValueNotifier([]);

  Future<void> fetchLibrarianRequests() async {
    isLoading.value = true;
    try {
      // 1. Fetch Loans + Books (No Profiles Join to avoid UUID crash)
      final response = await _supabase
          .from('loan_transactions')
          .select('*, books(*)')
          .order('request_date', ascending: false);

      // 2. Fetch All Profiles (to map names manually)
      final profilesResponse = await _supabase.from('profiles').select();
      final List<dynamic> profiles = profilesResponse as List<dynamic>;

      final List<Map<String, dynamic>> loadedRequests = [];

      for (var loan in response as List) {
        final book = loan['books'];
        final userId = loan['user_id'];
        
        // Find profile manually (Avoid firstWhere null issue)
        Map<String, dynamic>? profile;
        try {
          profile = profiles.firstWhere((p) => p['id'] == userId);
        } catch (e) {
          profile = null;
        }

        if (true) { // Always add, handle null book
          loadedRequests.add({
            'id': loan['id'],
            'book_id': book != null ? book['id'] : 'unknown',
            'book_title': book != null ? book['title'] : 'Deleted Book',
            'book_author': book != null ? book['author'] : '-',
            'book_image': book != null ? book['image_url'] : null,
            'user_name': profile != null ? (profile['full_name'] ?? 'Unknown') : 'Unknown/Deleted User',
            'user_id': userId,
             'status': loan['status'],
            'request_date': loan['request_date'],
            'due_date': loan['due_date'],
            'return_date': loan['return_date'],
          });
          if (kDebugMode) print('DEBUG LOAN: Status=${loan['status']} Book=${book != null ? book['title'] : 'NULL'}');
        }
      }
      if (kDebugMode) print('DEBUG TOTAL: ${loadedRequests.length}');
      librarianRequests.value = loadedRequests;
    } catch (e) {
      if (kDebugMode) print('Error fetching librarian requests: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Librarian: Update Status
  Future<void> updateRequestStatus(String id, String newStatus) async {
    try {
       // Fetch request details first to get user_id and book info for notification
       final requestData = await _supabase
           .from('loan_transactions')
           .select('*, books(*)')
           .eq('id', id)
           .single();
       
       final userId = requestData['user_id'];
       final bookTitle = requestData['books']?['title'] ?? 'Book';

       final updates = {'status': newStatus};
       
       String notifTitle = 'Request Update';
       String notifMessage = 'Your request has been updated.';
       String notifType = 'info';

       if (newStatus == 'active_loan') {
         updates['due_date'] = DateTime.now().add(const Duration(days: 14)).toIso8601String();
         notifTitle = 'Request Approved';
         notifMessage = 'You have borrowed "$bookTitle". Due date is in 14 days.';
         notifType = 'success';
       } else if (newStatus == 'rejected') {
         notifTitle = 'Request Rejected';
         notifMessage = 'Your request for "$bookTitle" was rejected.';
         notifType = 'alert';
       } else if (newStatus == 'returned') {
         updates['return_date'] = DateTime.now().toIso8601String();
         notifTitle = 'Return Confirmed';
         notifMessage = 'You have successfully returned "$bookTitle". Thank you!';
         notifType = 'success';
       }

      await _supabase.from('loan_transactions').update(updates).eq('id', id);
      
      // Send Notification
      await NotificationsManager().sendNotification(
        userId: userId,
        title: notifTitle,
        message: notifMessage,
        type: notifType,
      );

      await fetchLibrarianRequests(); // Refresh
    } catch (e) {
      if (kDebugMode) print('Error updating status: $e');
      rethrow;
    }
  }

  // Librarian: Fetch Loans for Specific User
  Future<List<Map<String, dynamic>>> fetchUserLoans(String userId) async {
    try {
      final response = await _supabase
          .from('loan_transactions')
          .select('*, books(*)')
          .eq('user_id', userId)
          .order('request_date', ascending: false);

      final List<Map<String, dynamic>> list = [];
      for (var loan in response as List) {
        final book = loan['books'];
        if (book != null) {
          list.add({
             'book_title': book['title'],
             'book_image': book['image_url'],
             'status': loan['status'],
             'due_date': loan['due_date'],
             'return_date': loan['return_date'],
          });
        }
      }
      return list;
    } catch (e) {
      if (kDebugMode) print('Error fetching user loans: $e');
      return [];
    }
  }
}
