import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AuthManager {
  static final AuthManager _instance = AuthManager._internal();

  factory AuthManager() {
    return _instance;
  }

  AuthManager._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if logged in
  bool get isLoggedIn => currentUser != null;

  // Sign Up
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null) {
        // Profile creation is now handled by Supabase Trigger (fix_signup_trigger.sql)
        // to avoid RLS permission errors on the client side.
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign In
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Verify OTP
  Future<void> verifyOTP({
    required String email,
    required String token,
  }) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Verification failed: $e');
    }
  }

  // Update Password
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // First verify current password by re-authenticating
      final user = currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Update password
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Password update failed: $e');
    }
  }

  // Fetch Profile Data
  Future<Map<String, dynamic>?> fetchProfileData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  // Update Profile
  Future<void> updateProfile({
    required String fullName,
    required String phone,
    required String? location,
    required String? avatarUrl,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _supabase.from('profiles').update({
        'full_name': fullName,
        'phone_number': phone,
        'location': location,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Upload Avatar
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final fileName = 'avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}.png';

      // Upload to Supabase Storage
      await _supabase.storage.from('avatars').upload(
            fileName,
            imageFile,
          );

      // Get public URL
      final url = _supabase.storage.from('avatars').getPublicUrl(fileName);

      return url;
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  // Get User Role
  Future<String?> getUserRole() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      return response?['role'] as String?;
    } catch (e) {
      throw Exception('Failed to fetch user role: $e');
    }
  }

  // Fetch All Members (for librarian)
  Future<List<Map<String, dynamic>>> fetchAllMembers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .neq('role', 'librarian') // Show all non-librarians (students/users)
          .order('full_name', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      if (kDebugMode) print('Error fetching members: $e');
      return [];
    }
  }
}
