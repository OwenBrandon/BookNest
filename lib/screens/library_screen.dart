import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/category_chip.dart';
import '../widgets/book_card.dart';
import '../core/books_manager.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false; // Toggle search visibility
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All', 'Business', 'Design', 'Science', 'Self-help', 'Technology', 'Fiction', 'History'
  ];

  @override
  void initState() {
    super.initState();
    BooksManager().fetchBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                        'Library',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 24,
                          letterSpacing: 1,
                        ),
                      ),
                     ],
                   ),
                   IconButton(
                     onPressed: () {
                       setState(() {
                         _isSearchVisible = !_isSearchVisible;
                         if (!_isSearchVisible) {
                           _searchQuery = '';
                           _searchController.clear();
                         }
                       });
                     }, 
                     icon: Icon(_isSearchVisible ? Icons.close : Icons.search, size: 28)
                   )
                ],
              ),
              const SizedBox(height: 24),
              
              if (_isSearchVisible) ...[
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search library',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    fillColor: Colors.grey[100],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Categories
              if (_searchQuery.isEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                      return CategoryChip(
                        label: category,
                        isSelected: _selectedCategory == category,
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      );
                    }).toList(),
                ),
              ),
              if (_searchQuery.isEmpty)
              const SizedBox(height: 24),

              // Book List
              ValueListenableBuilder<bool>(
                valueListenable: BooksManager().isLoading,
                builder: (context, isLoading, _) {
                   if (isLoading) {
                      return const Center(child: CircularProgressIndicator());
                   }
                   
                   return ValueListenableBuilder<List<Map<String, dynamic>>>(
                      valueListenable: BooksManager().allBooks,
                      builder: (context, books, child) {
                        final filteredBooks = books.where((book) {
                          final title = (book['title'] ?? '').toString().toLowerCase();
                          final author = (book['author'] ?? '').toString().toLowerCase();
                          final query = _searchQuery.toLowerCase();
                          final matchesSearch = title.contains(query) || author.contains(query);
                          
                          final bookCategory = book['category'] ?? 'General';
                          final matchesCategory = _selectedCategory == 'All' || bookCategory == _selectedCategory;

                          return matchesSearch && matchesCategory;
                        }).toList();

                        if (filteredBooks.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40.0),
                              child: Text(
                                'No books found',
                                style: GoogleFonts.poppins(color: Colors.grey),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: filteredBooks.map((book) => Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: BookCard(
                              id: book['id'] ?? '',
                              title: book['title'] ?? 'No Title',
                              author: book['author'] ?? 'Unknown',
                              imageUrl: book['image_url'] ?? book['imageUrl'] ?? 'https://via.placeholder.com/150',
                              availableCopies: book['available_copies'] ?? book['availableCopies'] ?? 0,
                              category: book['category'],
                            ),
                          )).toList(),
                        );
                      }
                   );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
