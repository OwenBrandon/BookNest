import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../core/books_manager.dart';

class AddEditBookScreen extends StatefulWidget {
  final Map<String, dynamic>? book;

  const AddEditBookScreen({super.key, this.book});

  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descController = TextEditingController();
  final _copiesController = TextEditingController();
  // _categoryController removed in favor of Dropdown
  // _imageController removed in favor of picker
  
  String? _selectedCategory;
  File? _imageFile;
  String? _currentImageUrl;

  bool _isLoading = false;

  final List<String> _categories = [
    'Business', 'Design', 'Science', 'Self-help', 'Technology', 'Fiction', 'History', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _titleController.text = widget.book!['title'] ?? '';
      _authorController.text = widget.book!['author'] ?? '';
      _descController.text = widget.book!['description'] ?? '';
      _copiesController.text = (widget.book!['total_copies'] ?? 1).toString();
      
      _selectedCategory = widget.book!['category'];
      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = _categories.first; // Fallback
      }
      
      _currentImageUrl = widget.book!['image_url'];
    } else {
      _selectedCategory = _categories.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descController.dispose();
    _copiesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleSave() async {
    if (_titleController.text.isEmpty || _authorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and Author are required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    String? imageUrl = _currentImageUrl;

    // Upload Image if selected
    if (_imageFile != null) {
      imageUrl = await BooksManager().uploadBookCover(_imageFile!);
      if (imageUrl == null) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
           setState(() => _isLoading = false);
           return;
         }
      }
    }

    final bookData = {
      'title': _titleController.text.trim(),
      'author': _authorController.text.trim(),
      'description': _descController.text.trim(),
      'category': _selectedCategory,
      'image_url': imageUrl,
      'total_copies': int.tryParse(_copiesController.text) ?? 1,
      // Only set available_copies if adding new book
      if (widget.book == null) 'available_copies': int.tryParse(_copiesController.text) ?? 1,
    };

    try {
      if (widget.book == null) {
        await BooksManager().addBook(bookData);
      } else {
         // Do not overwrite available_copies blindly on edit
        await BooksManager().updateBook(widget.book!['id'], bookData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(widget.book == null ? 'Book Added' : 'Book Updated')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.book != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Book' : 'Add New Book',
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Image Picker Layout
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200, // Rectangular aspect ratio
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(_currentImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                ),
                child: (_imageFile == null && (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            'Upload Cover Photo',
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              hintText: 'Book Title',
              prefixIcon: Icons.book,
              controller: _titleController,
            ),
            const SizedBox(height: 16),
             CustomTextField(
              hintText: 'Author',
              prefixIcon: Icons.person,
              controller: _authorController,
            ),
            const SizedBox(height: 16),
            
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.category, color: Colors.grey),
                fillColor: AppColors.inputBackground,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category, style: GoogleFonts.poppins()),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
            
            const SizedBox(height: 16),
            CustomTextField(
              hintText: 'Total Copies',
              prefixIcon: Icons.numbers,
              controller: _copiesController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Description',
                fillColor: AppColors.inputBackground,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: _isLoading ? 'SAVING...' : 'SAVE BOOK',
              onPressed: _isLoading ? () {} : _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
