import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../core/auth_manager.dart';
import 'main_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_codeController.text.isEmpty) {
      setState(() => _errorText = 'Please enter the code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await AuthManager().verifyOTP(
        email: widget.email,
        token: _codeController.text.trim(),
      );

      if (mounted) {
        // Success! Go to main screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _errorText = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorText = 'Verification failed. Please try again.');
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'Verification.',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                text: 'Enter the 6-digit code sent to ',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: widget.email,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            CustomTextField(
              hintText: 'Enter 6-Digit Code',
              prefixIcon: Icons.lock_clock_outlined,
              controller: _codeController,
              keyboardType: TextInputType.number,
              errorText: _errorText,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: _isLoading ? 'VERIFYING...' : 'VERIFY & CONTINUE',
              onPressed: _isLoading ? () {} : _handleVerify,
            ),
             const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {
                  // TODO: Resend logic if needed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Resend code feature coming soon')),
                  );
                },
                child: Text(
                  'Resend Code',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
