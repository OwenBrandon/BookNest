import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import 'custom_button.dart';
import '../core/borrowed_books_manager.dart';

class BorrowRequestSheet extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final String author;
  final String imageUrl;
  final int availableCopies;

  const BorrowRequestSheet({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.author,
    required this.imageUrl,
    required this.availableCopies,
  });

  @override
  State<BorrowRequestSheet> createState() => _BorrowRequestSheetState();
}

class _BorrowRequestSheetState extends State<BorrowRequestSheet> {
  int _selectedCopies = 1;
  DateTime? _returnDate;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Generate dropdown items based on available copies (cap at 10 to be safe/reasonable)
    final int maxSelectable = widget.availableCopies > 0 ? widget.availableCopies : 1;
    final List<int> copyOptions = List.generate(
      maxSelectable > 10 ? 10 : maxSelectable, 
      (index) => index + 1
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap content height
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
            'Request to Borrow',
            style: GoogleFonts.bebasNeue(
              fontSize: 24,
              letterSpacing: 1,
              color: Colors.black,
            ),
          ),
          Text(
            widget.bookTitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),

          // Copies Dropdown
          Text(
            'Number of Copies',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedCopies,
                isExpanded: true,
                items: copyOptions.map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(
                      '$value Copy${value > 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCopies = newValue!;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Return Date Picker
          Text(
            'Return Date',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)), // Default 1 week
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)), // Max borrow 30 days
              );
              if (picked != null && picked != _returnDate) {
                setState(() {
                  _returnDate = picked;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _returnDate == null 
                        ? 'Select return date' 
                        : '${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: _returnDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Action Button
          _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : CustomButton(
            text: 'Request Book',
            onPressed: () async {
              if (_returnDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a return date')),
                );
                return;
              }

              setState(() {
                _isLoading = true;
              });

              // Add to Manager (Supabase)
              final success = await BorrowedBooksManager().borrowBook(
                bookId: widget.bookId,
                returnDate: _returnDate!,
              );

              if (!mounted) return;

              if (success) {
                Navigator.pop(context, true); // Return success result
              } else {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to borrow book. Try again.')),
                );
              }
            },
          ),
          const SizedBox(height: 24), // Safety padding
        ],
      ),
    );
  }
}
