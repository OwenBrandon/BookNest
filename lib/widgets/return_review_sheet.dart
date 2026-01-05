import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/borrowed_books_manager.dart';

class ReturnReviewSheet extends StatefulWidget {
  final String bookId;
  final String bookTitle;

  const ReturnReviewSheet({super.key, required this.bookId, required this.bookTitle});

  @override
  State<ReturnReviewSheet> createState() => _ReturnReviewSheetState();
}

class _ReturnReviewSheetState extends State<ReturnReviewSheet> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 0;
  
  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submitReturn() {
    final review = _reviewController.text.trim();
    if (review.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a short review')),
      );
      return;
    }
    
    // Word count check (max 20 words)
    final wordCount = review.split(RegExp(r'\s+')).length;
    if (wordCount > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Review must be 20 words or less (Current: $wordCount)')),
      );
      return;
    }

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give a rating')),
      );
      return;
    }

    // Success
    BorrowedBooksManager().markAsReturnPending(widget.bookId);

    Navigator.pop(context); // Close sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Book returned successfully! Thanks for your review of "${widget.bookTitle}".'),
        backgroundColor: Colors.green,
      ),
    );
     // In a real app, you would send this data to the backend here
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Return & Review',
            style: GoogleFonts.bebasNeue(
              fontSize: 28,
              letterSpacing: 1,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How was "${widget.bookTitle}"?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Review Input
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write a short review (max 20 words)...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _submitReturn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Submit Review & Return',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
