import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../core/auth_manager.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool isValid = true;
    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    if (_currentPasswordController.text.isEmpty) {
      setState(() => _currentPasswordError = 'Current password is required');
      isValid = false;
    }

    if (_newPasswordController.text.isEmpty) {
      setState(() => _newPasswordError = 'New password is required');
      isValid = false;
    } else if (_newPasswordController.text.length < 6) {
      setState(() => _newPasswordError = 'Password must be at least 6 characters');
      isValid = false;
    }

    if (_confirmPasswordController.text != _newPasswordController.text) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleUpdatePassword() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthManager().updatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password updated successfully!', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        // If the error message is simply the exception string, try to clean it
        String errorMessage = e.toString().replaceAll('Exception:', '').trim();
        
        setState(() {
           if (errorMessage.toLowerCase().contains('incorrect')) {
             _currentPasswordError = errorMessage;
           } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMessage, style: GoogleFonts.poppins())),
              );
           }
        });
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
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a new password for your account',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            
            CustomTextField(
              hintText: 'Current Password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              controller: _currentPasswordController,
              errorText: _currentPasswordError,
            ),
            const SizedBox(height: 20),
            
            CustomTextField(
              hintText: 'New Password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              controller: _newPasswordController,
              errorText: _newPasswordError,
            ),
            const SizedBox(height: 20),
            
            CustomTextField(
              hintText: 'Confirm New Password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              controller: _confirmPasswordController,
              errorText: _confirmPasswordError,
            ),

             const SizedBox(height: 12),
            Text(
              'Make sure your password is strong (8+ characters, special symbol)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
            
            const SizedBox(height: 40), // Spacer replacement for scroll view
            
            CustomButton(
              text: _isLoading ? 'UPDATING...' : 'Update Password',
              onPressed: _isLoading ? () {} : _handleUpdatePassword,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
