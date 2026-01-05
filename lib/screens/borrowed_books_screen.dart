import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/borrowed_book_card.dart';

import '../core/borrowed_books_manager.dart';

class BorrowedBooksScreen extends StatefulWidget {
  const BorrowedBooksScreen({super.key});

  @override
  State<BorrowedBooksScreen> createState() => _BorrowedBooksScreenState();
}

class _BorrowedBooksScreenState extends State<BorrowedBooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    BorrowedBooksManager().fetchBorrowedBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Borrowed Books',
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search borrowed books',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: const Icon(Icons.mic, color: Colors.grey),
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

            Expanded(
              child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: BorrowedBooksManager().borrowedBooks,
                builder: (context, borrowedBooks, _) {
                  final filteredBooks = borrowedBooks.where((book) {
                    final title = book['title'].toLowerCase();
                    final author = book['author'].toLowerCase();
                    final query = _searchQuery.toLowerCase();
                    return title.contains(query) || author.contains(query);
                  }).toList();

                  return filteredBooks.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty ? 'No borrowed books' : 'No books found',
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredBooks.length,
                          itemBuilder: (context, index) {
                            final book = filteredBooks[index];
                            return BorrowedBookCard(
                              id: book['id'],
                              title: book['title'],
                              author: book['author'],
                              imageUrl: book['imageUrl'],
                              dueDate: book['dueDate'],
                              isReturnPending: book['isReturnPending'] ?? false,
                            );
                          },
                        );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}
