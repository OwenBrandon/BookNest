import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/activity_manager.dart'; // import

class LibrarianHomeScreen extends StatefulWidget {
  const LibrarianHomeScreen({super.key});

  @override
  State<LibrarianHomeScreen> createState() => _LibrarianHomeScreenState();
}

class _LibrarianHomeScreenState extends State<LibrarianHomeScreen> {
  final _supabase = Supabase.instance.client;
  
  // Stats
  int _totalBooks = 0;
  int _activeLoans = 0;
  int _pendingRequests = 0;
  int _totalMembers = 0;
  bool _isLoading = true;
  List<ActivityItem> _activities = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchActivity();
  }

  Future<void> _fetchStats() async {
    try {
      final booksCount = await _supabase.from('books').count(CountOption.exact);
      final activeCount = await _supabase.from('loan_transactions').count(CountOption.exact).eq('status', 'active_loan');
      final pendingCount = await _supabase.from('loan_transactions').count(CountOption.exact).eq('status', 'pending_borrow');
      final memberCount = await _supabase.from('profiles').count(CountOption.exact).neq('role', 'librarian');

      if (mounted) {
        setState(() {
          _totalBooks = booksCount;
          _activeLoans = activeCount;
          _pendingRequests = pendingCount;
          _totalMembers = memberCount;
        });
      }
    } catch (e) {
      debugPrint('Stats error: $e');
    }
  }

  Future<void> _fetchActivity() async {
    try {
      final items = await ActivityManager().fetchRecentActivity();
      if (mounted) {
        setState(() {
          _activities = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard('Total Books', _totalBooks.toString(), Icons.book, Colors.blue),
                _buildStatCard('Active Loans', _activeLoans.toString(), Icons.people, Colors.orange),
                _buildStatCard('Pending Requests', _pendingRequests.toString(), Icons.notification_important, Colors.redAccent),
                _buildStatCard('Total Members', _totalMembers.toString(), Icons.face, Colors.purple), 
              ],
            ),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Activity', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
                IconButton(onPressed: _fetchActivity, icon: const Icon(Icons.refresh, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _activities.isEmpty
                  ? Center(child: Text("No recent activity", style: GoogleFonts.poppins(color: Colors.grey)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                         final item = _activities[index];
                         return Dismissible(
                           key: ObjectKey(item),
                           direction: DismissDirection.endToStart,
                           onDismissed: (direction) {
                             setState(() {
                               _activities.removeAt(index);
                             });
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text("Activity removed"), duration: Duration(seconds: 1)),
                             );
                           },
                           background: Container(
                             margin: const EdgeInsets.only(bottom: 16),
                             padding: const EdgeInsets.only(right: 20),
                             decoration: BoxDecoration(
                               color: Colors.redAccent,
                               borderRadius: BorderRadius.circular(20),
                             ),
                             alignment: Alignment.centerRight,
                             child: const Icon(Icons.delete, color: Colors.white),
                           ),
                           child: _buildActivityTile(item),
                         );
                      },
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            _isLoading ? '...' : value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(ActivityItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(width: 16),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(item.subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Time
          Text(
            _timeAgo(item.timestamp),
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
