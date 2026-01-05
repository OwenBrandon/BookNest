import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/book_card.dart';
import '../core/favorites_manager.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: FavoritesManager().favoriteBooks,
            builder: (context, favorites, _) {
              final filteredFavorites = favorites.where((book) {
                final title = book['title'].toString().toLowerCase();
                final author = book['author'].toString().toLowerCase();
                final query = _searchQuery.toLowerCase();
                return title.contains(query) || author.contains(query);
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'FAVOURITES ',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 24,
                            color: Colors.black,
                            letterSpacing: 1,
                          ),
                        ),
                        TextSpan(
                          text: '(${filteredFavorites.length} ITEMS)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      // suffixIcon: const Icon(Icons.mic, color: Colors.grey), // Removed suffix to match clean design or keep search icon
                      suffixIcon: const Icon(Icons.search, color: Colors.transparent), // Hidden or remove
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

                  // Content
                  Expanded(
                    child: filteredFavorites.isEmpty 
                        ? (favorites.isEmpty ? _buildEmptyState() : _buildNoSearchResults()) 
                        : _buildListState(filteredFavorites),
                  ),
                ],
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Text(
        'No books found matching "$_searchQuery"',
        style: GoogleFonts.poppins(color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.purple[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.note_alt_outlined, size: 80, color: Colors.purple[200]),
          ),
          const SizedBox(height: 32),
          Text(
            'Oops! Your Wishlist is Empty 😔',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Start adding your favorites and make your wishlist shine! ✨',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildListState(List<Map<String, dynamic>> favorites) {
    return ListView.builder(
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final book = favorites[index];
        return BookCard(
          id: book['id'],
          title: book['title'],
          author: book['author'],
          imageUrl: book['imageUrl'],
          availableCopies: book['availableCopies'],
        );
      },
    );
  }
}
