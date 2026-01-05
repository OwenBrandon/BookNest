import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

enum ActivityType {
  newMember,
  newBook,
  newRequest,
  statusChange,
}

class ActivityItem {
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}

class ActivityManager {
  final _supabase = Supabase.instance.client;

  Future<List<ActivityItem>> fetchRecentActivity() async {
    List<ActivityItem> activities = [];

    try {
      // 1. New Members (Last 5)
      // Assuming profiles has created_at or we use updated_at
      try {
        final members = await _supabase
            .from('profiles')
            .select()
            .neq('role', 'librarian') // Only users
            .order('created_at', ascending: false) // Might fail if no created_at
            .limit(5);
        
        for (var m in members) {
           DateTime time = DateTime.tryParse(m['created_at'].toString()) ?? DateTime.now();
           activities.add(ActivityItem(
             type: ActivityType.newMember,
             title: 'New Member Joined',
             subtitle: '${m['full_name']} joined the library',
             timestamp: time,
             icon: Icons.person_add_rounded,
             color: Colors.blue,
           ));
        }
      } catch (_) {
         // Fallback if created_at missing
      }

      // 2. New Books (Last 5)
      try {
         final books = await _supabase.from('books').select().order('created_at', ascending: false).limit(5);
         for (var b in books) {
            DateTime time = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now();
            activities.add(ActivityItem(
              type: ActivityType.newBook,
              title: 'New Book Added',
              subtitle: 'Added "${b['title']}" by ${b['author']}',
              timestamp: time,
              icon: Icons.book_rounded,
              color: Colors.green,
            ));
         }
      } catch (_) {}

      // 3. Recent Requests/Loans (Last 10)
      // We look for recent request_date or Date updates
      try {
         final loans = await _supabase
             .from('loan_transactions')
             .select('*, books(title), profiles(full_name)')
             .order('request_date', ascending: false) // Use request_date for now
             .limit(10);
             
         for (var l in loans) {
            String status = l['status'];
            String bookTitle = l['books']?['title'] ?? 'Unknown Book';
            String userName = l['profiles']?['full_name'] ?? 'Unknown User';
            DateTime time = DateTime.tryParse(l['request_date'].toString()) ?? DateTime.now();
            
            String title = 'Request Update';
            String subtitle = 'Status: $status';
            Color color = Colors.orange;
            IconData icon = Icons.notifications_active;

            if (status == 'pending_borrow') {
               title = 'New Request';
               subtitle = '$userName requested "$bookTitle"';
               color = Colors.orange;
            } else if (status == 'active_loan') {
               title = 'Loan Approved';
               subtitle = '$userName borrowed "$bookTitle"';
               color = Colors.green;
               icon = Icons.check_circle;
               // If we have approved_at we could use it, but using request_date for simplicity or updated_at
            } else if (status == 'returned') {
               title = 'Book Returned';
               subtitle = '$userName returned "$bookTitle"';
               color = Colors.purple;
               icon = Icons.assignment_return;
            } else if (status == 'rejected') {
               title = 'Request Rejected';
               subtitle = 'Rejected request for "$bookTitle"';
               color = Colors.red;
               icon = Icons.cancel;
            }

            activities.add(ActivityItem(
              type: ActivityType.statusChange,
              title: title,
              subtitle: subtitle,
              timestamp: time,
              icon: icon,
              color: color,
            ));
         }
      } catch (_) {}

    } catch (e) {
      debugPrint('Error loading activity: $e');
    }

    // Sort by Date Descending
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return activities.take(10).toList(); // Return top 10
  }
}
