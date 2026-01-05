import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/auth_manager.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedLocation;
  bool _isLoading = false;

  final List<String> _bueaStreets = [
    'Molyko',
    'Clerks Quarters',
    'Federal Quarters',
    'Buea Town',
    'Mile 17',
    'Bonduma',
    'Check Point',
    'Great Soppo',
    'Bolyki',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    setState(() => _isLoading = true);
    final data = await AuthManager().fetchProfileData();
    if (data != null) {
      _fullNameController.text = data['full_name'] ?? '';
      _phoneController.text = data['phone_number'] ?? '';
      if (_bueaStreets.contains(data['location'])) {
         _selectedLocation = data['location'];
      }
      _avatarUrl = data['avatar_url'];
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      await AuthManager().updateProfile(
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        location: _selectedLocation,
        avatarUrl: _avatarUrl,
      );
      if (mounted) {
        Navigator.pop(context); // Return to PersonalDetailsScreen
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  String? _avatarUrl;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _isLoading = true);
      final File imageFile = File(image.path);
      final String? url = await AuthManager().uploadAvatar(imageFile);
      
      if (url != null) {
        setState(() {
          _avatarUrl = url;
          _isLoading = false;
        });
      } else {
        if (mounted) {
           setState(() => _isLoading = false);
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image. Ensure "avatars" bucket exists and is public.')),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar Edit
          Center(
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    image: _avatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _avatarUrl == null 
                      ? Icon(Icons.person, size: 50, color: Colors.grey[400]) 
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          CustomTextField(
            hintText: 'Full Name',
            controller: _fullNameController,
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            hintText: 'Enter phone number',
            controller: _phoneController,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),

          // Location Dropdown
          Text(
            'Location',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLocation,
                hint: Text('Select Location', style: GoogleFonts.poppins(color: Colors.grey)),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                items: _bueaStreets.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: GoogleFonts.poppins()),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedLocation = newValue;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 48),
          CustomButton(
            text: 'Save Changes',
            onPressed: _saveProfile,
          ),
        ],
      ),
    );
  }
}
