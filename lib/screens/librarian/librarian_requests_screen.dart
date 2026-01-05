import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/requests_manager.dart';

class LibrarianRequestsScreen extends StatefulWidget {
  const LibrarianRequestsScreen({super.key});

  @override
  State<LibrarianRequestsScreen> createState() => _LibrarianRequestsScreenState();
}

class _LibrarianRequestsScreenState extends State<LibrarianRequestsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allRequests = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    try {
      await RequestsManager().fetchLibrarianRequests();
      final requests = RequestsManager().librarianRequests.value;
      if (mounted) {
        setState(() {
          _allRequests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _filterRequests('pending_borrow');
    final active = _filterRequests('active_loan');
    final returns = _filterRequests('pending_return');
    final holds = _filterRequests('hold');

    // Remove Scaffold. Use Column.
    return DefaultTabController(
      length: 4,
      child: Container(
        color: Colors.grey[100], // Background
        child: Column(
          children: [
             // Custom Header replacing AppBar
             Container(
               padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
               color: Colors.white,
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Requests Center', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
                        IconButton(icon: const Icon(Icons.refresh, color: AppColors.primary), onPressed: _loadData),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppColors.primary,
                      isScrollable: true, // Allow scrolling if needed
                      tabs: [
                        Tab(text: 'Pending'),
                        Tab(text: 'Active'),
                        Tab(text: 'Returns'),
                        Tab(text: 'Holds'),
                      ],
                    ),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_errorMessage, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12))),
                            ],
                          ),
                        ),
                      ),
                 ],
               ),
             ),
             
             // Content
             Expanded(
               child: _isLoading 
                 ? const Center(child: CircularProgressIndicator())
                 : TabBarView(
                     children: [
                       _buildList(pending, 'pending', Colors.orange[50]),
                       _buildList(active, 'active', Colors.green[50]),
                       _buildList(returns, 'returns', Colors.blue[50]),
                       _buildList(holds, 'holds', Colors.purple[50]),
                     ],
                   ),
             ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterRequests(String status) {
    return _allRequests.where((r) {
      final s = r['status']?.toString().toLowerCase() ?? '';
      return s == status;
    }).toList();
  }

  Future<void> _updateStatus(String id, String status) async {
    setState(() => _isLoading = true);
    try {
      await RequestsManager().updateRequestStatus(id, status);
      if (mounted) {
        String msg = status == 'active_loan' ? 'Request Approved' : (status == 'rejected' ? 'Request Rejected' : 'Status Updated');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.primary));
        await _loadData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildList(List<Map<String, dynamic>> items, String type, Color? debugColor) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
               padding: const EdgeInsets.all(24),
               decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
               child: const Icon(Icons.inbox_outlined, size: 50, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text('No $type requests', style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final req = items[index];
        return _buildRequestCard(req, type);
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req, String type) {
    final title = req['book_title'] ?? 'Unknown Book';
    final author = req['book_author'] ?? 'Unknown Author';
    final user = req['user_name'] ?? 'Unknown User';
    final image = req['book_image']; 

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.person, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(user.toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                   decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                   child: Text(_formatDate(req['request_date']), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 16),
            
            // Book Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 60, height: 90,
                      color: Colors.grey[100],
                      child: (image != null && image.toString().isNotEmpty)
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => const Icon(Icons.book, size: 30, color: Colors.grey),
                          )
                        : const Icon(Icons.book, size: 30, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title.toString(), 
                           maxLines: 2, overflow: TextOverflow.ellipsis,
                           style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, height: 1.3)),
                      Text(author.toString(), 
                           style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500])),
                      if (type == 'active') ...[
                           const SizedBox(height: 8),
                           Row(children: [
                             const Icon(Icons.calendar_today, size: 12, color: Colors.redAccent),
                             const SizedBox(width: 4),
                             Text('Due: ${_formatDate(req['due_date'])}', 
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w500)),
                           ]),
                       ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Actions
            Row(
              children: _buildActions(req, type),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    try {
      final date = DateTime.parse(dateValue.toString());
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateValue.toString();
    }
  }

  List<Widget> _buildActions(Map<String, dynamic> req, String type) {
    final id = req['id']?.toString();
    if (id == null) return [];

    switch (type) {
      case 'pending':
        return [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateStatus(id, 'rejected'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.red.withOpacity(0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.red.withOpacity(0.05),
              ),
              child: Text('Reject', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(id, 'active_loan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Approve', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ];
      case 'active':
        return [];
      case 'returns':
        return [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(id, 'returned'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Confirm green
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Confirm Return', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ];
      case 'holds':
        return [
          Expanded(
             child: ElevatedButton(
               onPressed: () => _updateStatus(id, 'active_loan'),
               style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
               child: Text('Approve Hold', style: GoogleFonts.poppins(color: Colors.white)),
             ),
          ),
        ];
      default:
        return [];
    }
  }
}
