import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../screens/book_detail_screen.dart';
import '../core/favorites_manager.dart';
import 'borrow_request_sheet.dart';
import '../core/borrowed_books_manager.dart';
import '../core/requests_manager.dart';
import 'return_review_sheet.dart';

class BookCard extends StatelessWidget {
  final String id;
  final String title;
  final String author;
  final String imageUrl;
  final int availableCopies;
  final String? category; // New optional parameter
  final bool isLarge;

  const BookCard({
    super.key,
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.availableCopies,
    this.category,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailScreen(
              bookData: {
                'id': id,
                'title': title,
                'author': author,
                'imageUrl': imageUrl,
                'availableCopies': availableCopies,
                'category': category, // Pass category
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: 80,
                height: 120,
                fit: BoxFit.cover,
                 errorBuilder: (context, error, stackTrace) {
                   return Container(
                     width: 80,
                     height: 120,
                     color: Colors.grey[300],
                     child: const Icon(Icons.book, color: Colors.grey),
                   );
                },
              ),
            ),
            const SizedBox(width: 16),
            // Book Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Favorite Icon logic
                      ValueListenableBuilder(
                        valueListenable: FavoritesManager().favoriteBooks,
                        builder: (context, favorites, child) {
                          final isFav = FavoritesManager().isFavorite(title, author, id: id);
                          return GestureDetector(
                            onTap: () {
                              FavoritesManager().toggleFavorite({
                                'id': id,
                                'title': title,
                                'author': author,
                                'imageUrl': imageUrl,
                                'availableCopies': availableCopies,
                              });
                            },
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: isFav ? Colors.red : Colors.grey,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    author,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lorem Ipsum Dolor Sit Amet.Lorem Ipsum Dolor Sit .',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[400],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Action Row: Copies/Due Date & Button
                  ValueListenableBuilder(
                    valueListenable: BorrowedBooksManager().borrowedBooks,
                    builder: (context, borrowed, _) {
                      return ValueListenableBuilder(
                        valueListenable: RequestsManager().requests,
                        builder: (context, requests, _) {
                          final borrowedData = BorrowedBooksManager().getBorrowedBook(id);
                          final isBorrowed = borrowedData != null;
                          final isReturnPending = isBorrowed ? (borrowedData['isReturnPending'] ?? false) : false;
                          
                          final pendingRequest = RequestsManager().getRequestForBook(id);
                          final isPendingRequest = pendingRequest != null;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Left info: Copies or Due Date
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isBorrowed 
                                      ? (borrowedData['dueDate'] ?? 'Unknown')
                                      : '$availableCopies',
                                    style: GoogleFonts.poppins(
                                      color: isBorrowed ? Colors.red[400] : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    isBorrowed ? 'Due Date' : 'Copies available',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Right Button
                              if (isBorrowed)
                                ElevatedButton(
                                  onPressed: isReturnPending 
                                    ? null // Disabled if return pending
                                    : () {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        isScrollControlled: true,
                                        builder: (context) => ReturnReviewSheet(bookId: id, bookTitle: title),
                                      ).then((_) {});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isReturnPending ? Colors.grey : Colors.red[400],
                                    disabledBackgroundColor: Colors.grey,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  child: Text(
                                    isReturnPending ? 'Pending' : 'Return',
                                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                )
                              else if (isPendingRequest)
                                ElevatedButton(
                                  onPressed: null, // Disabled
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[300],
                                    disabledBackgroundColor: Colors.orange[300],
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  child: Text(
                                    'Pending',
                                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                )
                              else
                                ElevatedButton(
                                  onPressed: () async {
                                    if (availableCopies > 0) {
                                      final result = await showModalBottomSheet<bool>(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        isScrollControlled: true,
                                        builder: (context) => BorrowRequestSheet(
                                          bookId: id,
                                          bookTitle: title,
                                          author: author,
                                          imageUrl: imageUrl,
                                          availableCopies: availableCopies,
                                        ),
                                      );

                                      if (result == true && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Request sent for "$title"!'),
                                            backgroundColor: AppColors.primary,
                                          ),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Hold placed for "$title".', style: GoogleFonts.poppins()),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: availableCopies > 0 ? AppColors.primary : Colors.orange,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  child: Text(
                                    availableCopies > 0 ? 'Borrow' : 'Place Hold',
                                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                )
                            ],
                          );
                        }
                      );
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
