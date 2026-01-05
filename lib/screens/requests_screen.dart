import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/request_book_card.dart';
import '../core/requests_manager.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  @override
  void initState() {
    super.initState();
    RequestsManager().fetchRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Requests',
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
        child: ValueListenableBuilder<bool>(
          valueListenable: RequestsManager().isLoading,
          builder: (context, isLoading, _) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            return ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: RequestsManager().requests,
              builder: (context, requests, _) {
                return requests.isEmpty 
                  ? Center(
                      child: Text(
                        'No requests found',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        final isDismissible = request['status'] != RequestStatus.pending;

                        return Dismissible(
                          key: Key(request['id']), // Use unique DB ID
                          direction: isDismissible ? DismissDirection.endToStart : DismissDirection.none,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 24.0),
                              child: Icon(Icons.delete_outline, color: Colors.red[700], size: 28),
                            ),
                          ),
                          onDismissed: (direction) {
                            RequestsManager().removeRequest(request['id']);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Request removed')),
                            );
                          },
                          child: RequestBookCard(
                            title: request['title'],
                            author: request['author'],
                            imageUrl: request['imageUrl'],
                            returnDate: request['returnDate'],
                            status: request['status'],
                          ),
                        );
                      },
                    );
              }
            );
          }
        ),
      ),
    );
  }
}
