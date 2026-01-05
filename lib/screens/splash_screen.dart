import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/auth_manager.dart'; // import
import 'welcome_screen.dart';
import 'home_screen.dart'; // import
import 'main_screen.dart'; // import
import 'librarian/librarian_dashboard.dart'; // import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToWelcome();
  }

  void _navigateToWelcome() async {
    await Future.delayed(const Duration(seconds: 2)); // Reduced wait

    if (!mounted) return;

    try {
      if (AuthManager().isLoggedIn) {
        // Fetch role to decide where to go
        final role = await AuthManager().getUserRole();
        
        if (!mounted) return;

        if (role == 'librarian') {
           Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LibrarianDashboard()),
          );
        } else {
           Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()), // Fixed: Use MainScreen wrapper
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } catch (e) {
      // Fallback
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Library Icon/Logo
              Icon(
                Icons.library_books_outlined,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              // App Title
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'BOOKNEST',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                        height: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Loading Indicator
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
