import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../widgets/category_chip.dart';
import '../widgets/book_card.dart';
import 'notifications_screen.dart';

import '../core/books_manager.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const HomeScreen({super.key, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Static Section ---
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    'ENJOY READING',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 24,
                      letterSpacing: 1,
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                          );
                        },
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search for books',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey), // Standard prefix
                  suffixIcon: const Icon(Icons.search, color: Colors.transparent), // Hidden or remove
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30), // Rounded pill
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                ),
              ),
              const SizedBox(height: 24),

              // Content conditional on search
              if (_searchQuery.isEmpty) ...[
                // Banner (Placeholder for now, could be a PageView)
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.blue[100],
                    image: const DecorationImage(
                       image: NetworkImage("https://img.freepik.com/free-vector/literature-book-festival-banner_23-2148194474.jpg"),
                       fit: BoxFit.cover,
                    ),
                  ),
                  child: Container( // Gradient overlay for text readability
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                         colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Categories
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
                const SizedBox(height: 24),
                // Recommend Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: const BoxDecoration(
                         border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
                       ),
                       child: Text(
                        'RECOMMEND',
                        style: GoogleFonts.bebasNeue(fontSize: 18, letterSpacing: 1),
                                         ),
                     ),
                    GestureDetector( // Added GestureDetector
                      onTap: () => widget.onTabChange?.call(1), // Navigate to Library (Index 1)
                      child: Text(
                        'See all',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // --- Scrollable Section ---
              Expanded(
                child: ValueListenableBuilder<bool>(
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
                            child: Text(
                              _searchQuery.isNotEmpty ? 'No books found' : 'No books in this category',
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: filteredBooks.length,
                          itemBuilder: (context, index) {
                            final book = filteredBooks[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: BookCard(
                                id: book['id'] ?? '',
                                title: book['title'] ?? 'No Title',
                                author: book['author'] ?? 'Unknown',
                                imageUrl: book['image_url'] ?? book['imageUrl'] ?? 'https://via.placeholder.com/150', // Handle DB snake_case
                                availableCopies: book['available_copies'] ?? book['availableCopies'] ?? 0, // Handle DB snake_case
                                category: book['category'],
                              ),
                            );
                          },
                        );
                      }
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
