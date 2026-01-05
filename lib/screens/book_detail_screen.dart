import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/favorites_manager.dart';
import '../core/borrowed_books_manager.dart';
import '../core/requests_manager.dart';
import '../widgets/borrow_request_sheet.dart';
import '../widgets/return_review_sheet.dart';

class BookDetailScreen extends StatefulWidget {
  final Map<String, dynamic> bookData;

  const BookDetailScreen({super.key, required this.bookData});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {

  @override
  Widget build(BuildContext context) {
    final String bookId = widget.bookData['id'] ?? '';
    
    // Check global state first
    bool isBorrowed = BorrowedBooksManager().isBookBorrowed(bookId);
    String dueDate = 'Unknown';

    if (isBorrowed) {
      final borrowedBook = BorrowedBooksManager().getBorrowedBook(bookId);
      if (borrowedBook != null) {
        dueDate = borrowedBook['dueDate'] ?? 'Unknown';
      }
    } else {
       // Fallback to passed arguments if not in global manager (e.g. legacy or direct pass)
       isBorrowed = widget.bookData['isBorrowed'] == true;
       if (isBorrowed) {
          dueDate = widget.bookData['dueDate'] ?? 'Unknown';
       }
    }

    // Scaffold background color matching the design (light purple/white)
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FC), // Light purple tint
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Search Bar (Visual only for now)
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search for books',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: const Icon(Icons.search, color: Colors.grey),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                ),
              ),
              const SizedBox(height: 32),
              
              // Main Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Image
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          widget.bookData['imageUrl'] ?? 'https://via.placeholder.com/150',
                          width: 200,
                          height: 300,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                             return Container(
                               width: 200,
                               height: 300,
                               color: Colors.grey[300],
                               child: const Icon(Icons.book, size: 50, color: Colors.grey),
                             );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title & Love Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.bookData['title'] ?? 'Book Title',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        ValueListenableBuilder(
                          valueListenable: FavoritesManager().favoriteBooks,
                          builder: (context, favorites, child) {
                             final isFav = FavoritesManager().isFavorite(
                               widget.bookData['title'], 
                               widget.bookData['author'],
                               id: bookId,
                             );
                             return GestureDetector(
                               onTap: () {
                                 FavoritesManager().toggleFavorite(widget.bookData);
                               },
                               child: Container(
                                 padding: const EdgeInsets.all(8),
                                 decoration: BoxDecoration(
                                   color: const Color(0xFFF3E5F5),
                                   borderRadius: BorderRadius.circular(50),
                                 ),
                                 child: Icon(
                                   isFav ? Icons.favorite : Icons.favorite_border,
                                   color: isFav ? Colors.red : AppColors.primary,
                                   size: 24
                                 ),
                               ),
                             );
                          }
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Description
                    Text(
                      widget.bookData['author'] ?? 'Author Name', // Using author as subtitle matching design
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                     const SizedBox(height: 8),
                    Text(
                      widget.bookData['description'] ?? 'No description available.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Genre Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        widget.bookData['category'] ?? 'General',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Pages & Read Button (or Due Date & Return Button)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isBorrowed) ...[
                               Text(
                                 'Due Date',
                                 style: GoogleFonts.poppins(
                                   color: Colors.grey,
                                   fontSize: 12,
                                 ),
                               ),
                               Text(
                                 dueDate,
                                 style: GoogleFonts.poppins(
                                   color: Colors.red[400],
                                   fontWeight: FontWeight.bold,
                                   fontSize: 20,
                                 ),
                               ),
                            ] else ...[
                               Text(
                                 '${widget.bookData['availableCopies'] ?? 0}',
                                 style: GoogleFonts.poppins(
                                   color: AppColors.primary,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 20,
                                 ),
                               ),
                              Text(
                                'Copies available',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Smart Action Button
                        SizedBox(
                          width: 170,
                          child: ValueListenableBuilder(
                            valueListenable: BorrowedBooksManager().borrowedBooks,
                            builder: (context, borrowed, _) {
                              return ValueListenableBuilder(
                                valueListenable: RequestsManager().requests,
                                builder: (context, requests, _) {
                                  final borrowedData = BorrowedBooksManager().getBorrowedBook(bookId);
                                  final isBorrowed = borrowedData != null;
                                  final isReturnPending = isBorrowed ? (borrowedData['isReturnPending'] ?? false) : false;
                                  
                                  final pendingRequest = RequestsManager().getRequestForBook(bookId);
                                  final isPending = pendingRequest != null;
                                  final int copies = widget.bookData['availableCopies'] ?? 0;

                                  if (isBorrowed) {
                                    return ElevatedButton(
                                      onPressed: isReturnPending 
                                        ? null 
                                        : () {
                                         showModalBottomSheet(
                                          context: context,
                                          backgroundColor: Colors.transparent,
                                          isScrollControlled: true,
                                          builder: (context) => ReturnReviewSheet(bookId: bookId, bookTitle: widget.bookData['title'] ?? ''),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isReturnPending ? Colors.grey : Colors.red[400],
                                        disabledBackgroundColor: Colors.grey,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                        minimumSize: const Size(0, 50),
                                      ),
                                      child: Text(
                                        isReturnPending ? 'Return Pending' : 'Return Book',
                                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    );
                                  } else if (isPending) {
                                    return ElevatedButton(
                                      onPressed: null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange[300],
                                        disabledBackgroundColor: Colors.orange[300],
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                        minimumSize: const Size(0, 50),
                                      ),
                                      child: Text(
                                        'Request Pending',
                                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    );
                                  } else {
                                    return ElevatedButton(
                                      onPressed: () async {
                                        if (copies > 0) {
                                          final result = await showModalBottomSheet<bool>(
                                            context: context,
                                            backgroundColor: Colors.transparent,
                                            isScrollControlled: true,
                                            builder: (context) => BorrowRequestSheet(
                                              bookId: bookId,
                                              bookTitle: widget.bookData['title'] ?? 'Book',
                                              author: widget.bookData['author'] ?? 'Unknown Author',
                                              imageUrl: widget.bookData['imageUrl'] ?? '',
                                              availableCopies: copies,
                                            ),
                                          );

                                          if (result == true && context.mounted) {
                                            Navigator.pop(context); // Close Detail Screen
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Request sent for "${widget.bookData['title']}"!'),
                                                backgroundColor: AppColors.primary,
                                              ),
                                            );
                                          }
                                        } else {
                                          // Place Hold Logic
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Placed on hold list')),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: copies > 0 ? AppColors.primary : Colors.orange,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                        minimumSize: const Size(0, 50),
                                      ),
                                      child: Text(
                                        copies > 0 ? 'Borrow Book' : 'Place Hold',
                                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
