import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../sign_in_screen.dart';
import '../../core/auth_manager.dart';
import 'librarian_home_screen.dart';
import 'manage_books_screen.dart';
import 'librarian_requests_screen.dart';
import 'librarian_members_screen.dart';
import 'librarian_profile_screen.dart'; // import

class LibrarianDashboard extends StatefulWidget {
  const LibrarianDashboard({super.key});

  @override
  State<LibrarianDashboard> createState() => _LibrarianDashboardState();
}

class _LibrarianDashboardState extends State<LibrarianDashboard> {
  int _currentIndex = 0;

  // Placeholder Screens
  final List<Widget> _screens = [
    const LibrarianHomeScreen(), // Real Home Screen
    const ManageBooksScreen(),   // Real Books Management
    const LibrarianRequestsScreen(), // Real Requests Center
    const LibrarianMembersScreen(), // Real Members List
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Librarian Panel',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
           Padding(
             padding: const EdgeInsets.only(right: 16.0),
             child: GestureDetector(
               onTap: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => const LibrarianProfileScreen()),
                 );
               },
               child: CircleAvatar(
                 radius: 18,
                 backgroundColor: AppColors.primary.withOpacity(0.1),
                 child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                 // Note: Ideally load image from Auth, but simple icon is fine for now/placeholder or I can fetch it.
                 // We'll stick to a clean icon or I can wrap it in FutureBuilder if I really want the image.
                 // Let's use the icon as requested "profile icon".
               ),
             ),
           ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(24),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.dashboard, 'Home', 0),
            _buildNavItem(Icons.book, 'Books', 1),
            _buildNavItem(Icons.assignment, 'Requests', 2),
            _buildNavItem(Icons.people, 'Members', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.all(8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
