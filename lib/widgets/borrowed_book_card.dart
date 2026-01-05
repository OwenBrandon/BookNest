import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../screens/book_detail_screen.dart';
import 'return_review_sheet.dart';

class BorrowedBookCard extends StatelessWidget {
  final String id;
  final String title;
  final String author;
  final String imageUrl;
  final String dueDate;
  final bool isReturnPending;

  const BorrowedBookCard({
    super.key,
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.dueDate,
    this.isReturnPending = false,
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
                'availableCopies': 1, 
                'genre': 'Biopic', 
                'isBorrowed': true, // Context flag
                'dueDate': dueDate, // Pass due date
                'isReturnPending': isReturnPending,
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
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    author,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Placeholder Description for aesthetic
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
                  
                  // Action Row: Due Date & Return Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due Date',
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            dueDate,
                            style: GoogleFonts.poppins(
                              color: Colors.red[400],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: isReturnPending ? null : () {
                          // Return logic with Review Popup
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => ReturnReviewSheet(bookId: id, bookTitle: title),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isReturnPending ? Colors.grey : AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size(90, 32),
                          padding: EdgeInsets.zero,
                          elevation: 0,
                        ),
                        child: Text(
                          isReturnPending ? 'Pending Approval' : 'Return Book',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isReturnPending ? Colors.grey : AppColors.primary,
                          ),
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
    );
  }
}
