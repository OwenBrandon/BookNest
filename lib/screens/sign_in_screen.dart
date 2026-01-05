import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/social_button.dart';
import 'main_screen.dart';
import 'create_account_screen.dart';
import '../core/auth_manager.dart';
import 'librarian/librarian_dashboard.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _emailError;
  String? _passwordError;

  bool _validate() {
    bool isValid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      isValid = false;
    } else if (!email.contains('@') || !email.contains('.')) {
      setState(() => _emailError = 'Enter a valid email');
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleSignIn() async {
    if (!_validate()) return;
    
    setState(() => _isLoading = true);

    try {
      await AuthManager().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Check Role
      final role = await AuthManager().getUserRole();

      if (mounted) {
        if (role == 'librarian') {
          // Navigate to Librarian Dashboard
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LibrarianDashboard()),
            (route) => false,
          );
        } else {
          // Navigate to User Main Screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        final error = e.toString().toLowerCase();
        
        // Parse basic errors
        if (error.contains('invalid login credentials') || error.contains('invalid_credentials')) {
           setState(() {
             _emailError = 'Invalid email or password';
             _passwordError = 'Invalid email or password';
           });
        } else if (error.contains('email')) {
           setState(() => _emailError = error.replaceAll('exception:', '').trim());
        } else if (error.contains('password')) {
           setState(() => _passwordError = error.replaceAll('exception:', '').trim());
        } else {
          // Fallback for unknown errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception:', '').trim()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'Sign In.',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome back! Sign in to continue.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            CustomTextField(
              hintText: 'Enter Your Email',
              prefixIcon: Icons.email_outlined,
              controller: _emailController,
              errorText: _emailError,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              hintText: 'Enter Password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              controller: _passwordController,
              errorText: _passwordError,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                   // Forgot Password Logic
                },
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: _isLoading ? 'SIGNING IN...' : 'SIGN IN',
              onPressed: _isLoading ? () {} : _handleSignIn,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),
            const SizedBox(height: 32),
             SocialButton(
              text: 'Sign In With Google',
              icon: Icons.g_mobiledata,
              iconColor: Colors.red,
              onPressed: () {},
            ),
             const SizedBox(height: 16),
            SocialButton(
              text: 'Sign In With Facebook',
              icon: Icons.facebook,
              iconColor: Colors.blue[800],
              onPressed: () {},
            ),
           
            const SizedBox(height: 40),
            Center(
              child: RichText(
                text: TextSpan(
                  text: "Don't have an Account? ",
                  style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
                  children: [
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateAccountScreen()),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14, // Adjusted size to match
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
