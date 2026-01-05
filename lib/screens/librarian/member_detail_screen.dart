import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/requests_manager.dart';

class MemberDetailScreen extends StatefulWidget {
  final Map<String, dynamic> member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  List<Map<String, dynamic>> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final data = await RequestsManager().fetchUserLoans(widget.member['id']);
    if (mounted) {
      setState(() {
        _loans = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Member Details', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: (widget.member['avatar_url'] != null && widget.member['avatar_url'].toString().isNotEmpty)
                        ? NetworkImage(widget.member['avatar_url'])
                        : null,
                    backgroundColor: Colors.grey[200],
                    child: (widget.member['avatar_url'] == null || widget.member['avatar_url'].toString().isEmpty)
                        ? const Icon(Icons.person, size: 50, color: Colors.grey) 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.member['full_name'] ?? 'Unknown Name',
                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.member['phone_number'] ?? 'No phone number',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.member['location'] ?? 'No location',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('Total Loans', '${_loans.length}'),
                _buildStat('Active', '${_loans.where((l) => l['status'] == 'active_loan').length}'),
                _buildStat('Returned', '${_loans.where((l) => l['status'] == 'returned').length}'),
              ],
            ),
             const SizedBox(height: 32),
             
             Align(
               alignment: Alignment.centerLeft,
               child: Text(
                 'Loan History',
                 style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
               ),
             ),
             const SizedBox(height: 16),
             
             if (_isLoading)
               const Center(child: CircularProgressIndicator())
             else if (_loans.isEmpty)
               Center(child: Text('No history found', style: GoogleFonts.poppins(color: Colors.grey)))
             else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _loans.length,
                itemBuilder: (context, index) {
                  final loan = _loans[index];
                  return _buildLoanCard(loan);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    final status = loan['status']?.toString().toLowerCase() ?? 'unknown';
    Color statusColor = Colors.grey;
    String statusText = status;
    Color chipBg = Colors.grey[100]!;

    if (status == 'active_loan') {
      statusColor = Colors.orange;
      statusText = 'Active';
      chipBg = Colors.orange[50]!;
    } else if (status == 'returned') {
      statusColor = AppColors.primary;
      statusText = 'Returned';
      chipBg = const Color(0xFFF3E5F5); // Purple 50
    } else if (status == 'pending_borrow') {
      statusColor = Colors.blue;
      statusText = 'Pending';
      chipBg = Colors.blue[50]!;
    }

    final image = loan['book_image'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 60, height: 90,
                color: Colors.grey[100],
                child: (image != null && image.toString().isNotEmpty)
                   ? Image.network(image, fit: BoxFit.cover,
                       errorBuilder: (_,__,___) => const Icon(Icons.book, color: Colors.grey))
                   : const Icon(Icons.book, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loan['book_title'] ?? 'Unknown Book',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  if (status == 'active_loan')
                    Text('Due: ${_formatDate(loan['due_date'])}', 
                         style: GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w500))
                  else if (status == 'returned')
                    Text('Returned: ${_formatDate(loan['return_date'] ?? loan['due_date'])}', // Fallback
                         style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey))
                  else
                    Text('Requested: ${_formatDate(loan['request_date'])}',
                         style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            // Status Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
  
  String _formatDate(String? dateStr) {
     if (dateStr == null) return '-';
     try {
       final d = DateTime.parse(dateStr);
       return '${d.day}/${d.month}/${d.year}';
     } catch (_) { return dateStr;}
  }
}
