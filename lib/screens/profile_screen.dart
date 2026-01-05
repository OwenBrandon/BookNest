import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../screens/welcome_screen.dart'; // For Logout navigation
import '../screens/personal_details_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/borrowed_books_screen.dart';
import '../screens/requests_screen.dart';
import '../screens/history_screen.dart';
import '../screens/favorites_screen.dart';
import '../core/auth_manager.dart';

class ProfileScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const ProfileScreen({super.key, this.onTabChange});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await AuthManager().fetchProfileData();
    if (mounted) {
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthManager().currentUser;
    final String name = _profileData?['full_name'] ?? user?.userMetadata?['full_name'] ?? 'Library User';
    final String email = user?.email ?? 'No user';

    return Scaffold(
      body: Stack(
        children: [
          // Background Decoration
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFD1C4E9).withOpacity(0.5), // Light purple blob
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title
              Text(
                'PROFILE',
                style: GoogleFonts.bebasNeue(
                  fontSize: 24,
                  letterSpacing: 1,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // Profile Card (Avatar + Info)
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      image: _profileData?['avatar_url'] != null
                          ? DecorationImage(
                              image: NetworkImage(_profileData!['avatar_url']),
                              fit: BoxFit.cover,
                            )
                          : null,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _profileData?['avatar_url'] == null
                        ? Icon(Icons.person, size: 40, color: Colors.grey[400])
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                         Row(
                           children: [
                             const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                             const SizedBox(width: 4),
                             Text(
                              email,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                             ),
                           ],
                         ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PersonalDetailsScreen()),
                      );
                      _loadProfile();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0D4FC), // Light purple
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'EDIT',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Usage Chart Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5), // Light purple bg
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Usage',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'This week',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primary)
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Custom Bar Chart
                    SizedBox(
                      height: 150,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildChartBar('Mon', 4, true),
                          _buildChartBar('Tue', 10, true),
                          _buildChartBar('Wed', 7, true),
                          _buildChartBar('Thu', 9, true),
                          _buildChartBar('Fri', 3, true),
                          _buildChartBar('Sat', 12, true),
                          _buildChartBar('Sun', 11, true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Menu Options
              _buildMenuItem(
                Icons.book_outlined, 
                'Books Borrowed',
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BorrowedBooksScreen()),
                  );
                }
              ),
              _buildMenuItem(
                Icons.pending_actions_outlined, 
                'Requests',
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RequestsScreen()),
                  );
                }
              ),
              _buildMenuItem(
                Icons.history, 
                'History',
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  );
                }
              ),
              _buildMenuItem(
                Icons.favorite_border, 
                'Favourites', 
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                  );
                },
              ),
              _buildMenuItem(
                Icons.person_outline, 
                'Personal Details',
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PersonalDetailsScreen()),
                  );
                }
              ),
              _buildMenuItem(
                Icons.settings_outlined, 
                'Setting',
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                }
              ),
              _buildMenuItem(Icons.help_outline, 'Help & Support'),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Logout
              InkWell(
                onTap: () async {
                   await AuthManager().signOut();
                   
                   if (context.mounted) {
                     Navigator.pushAndRemoveUntil(
                      context, 
                      MaterialPageRoute(builder: (context) => const WelcomeScreen()), 
                      (route) => false,
                    );
                   }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.red),
                      const SizedBox(width: 16),
                      Text(
                        'Log Out',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildChartBar(String day, int value, bool isActive) {
    // Max value assumed roughly 16 for scaling
    double height = (value / 16) * 100; 
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: 100, // Max height container
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            width: 12,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
