import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/utils/colors.dart';
import 'package:intl/intl.dart';

class AdminReviewsPage extends StatefulWidget {
  const AdminReviewsPage({Key? key}) : super(key: key);

  @override
  State<AdminReviewsPage> createState() => _AdminReviewsPageState();
}

class _AdminReviewsPageState extends State<AdminReviewsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Reviews'),
        backgroundColor: bg_dark,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search reviews by product or comment...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('reviews').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No reviews found'),
                  );
                }

                // Filter reviews based on search query only (remove star filter)
                var filteredReviews = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  
                  // Print out first review document for debugging field names
                  if (snapshot.data!.docs.indexOf(doc) == 0) {
                    print('First review document structure: ${data}');
                  }
                  
                  // Get review data with fallbacks for different field names
                  String productName = (data['productName'] ?? data['product_name'] ?? '').toString().toLowerCase();
                  
                  // Check multiple field names for the comment/text
                  String comment = (data['comment'] ?? 
                                  data['review'] ?? 
                                  data['text'] ?? 
                                  data['content'] ?? 
                                  data['reviewText'] ?? 
                                  data['review_text'] ??
                                  data['description'] ?? '').toString().toLowerCase();
                  
                  String userName = (data['userName'] ?? data['user_name'] ?? data['username'] ?? '').toString().toLowerCase();
                  
                  // Filter by search query across all text fields
                  return _searchQuery.isEmpty || 
                         productName.contains(_searchQuery) ||
                         comment.contains(_searchQuery) ||
                         userName.contains(_searchQuery);
                }).toList();

                // Sort reviews by date (most recent first)
                filteredReviews.sort((a, b) {
                  var aData = a.data() as Map<String, dynamic>;
                  var bData = b.data() as Map<String, dynamic>;
                  
                  Timestamp? aTimestamp = aData['timestamp'] as Timestamp?;
                  Timestamp? bTimestamp = bData['timestamp'] as Timestamp?;
                  
                  if (aTimestamp == null && bTimestamp == null) return 0;
                  if (aTimestamp == null) return 1;
                  if (bTimestamp == null) return -1;
                  
                  return bTimestamp.compareTo(aTimestamp);
                });

                if (filteredReviews.isEmpty) {
                  return const Center(
                    child: Text('No matching reviews found'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredReviews.length,
                  itemBuilder: (context, index) {
                    var review = filteredReviews[index];
                    var data = review.data() as Map<String, dynamic>;
                    
                    return _buildReviewCard(context, review.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, String reviewId, Map<String, dynamic> reviewData) {
    // Debug: print the actual data structure to see all available fields
    print('Review data: $reviewData');
    
    String productName = reviewData['productName'] ?? reviewData['product_name'] ?? 'Unknown Product';
    String userName = reviewData['userName'] ?? reviewData['user_name'] ?? reviewData['username'] ?? 'Anonymous User';
    
    // Try multiple possible field names for comment
    String comment = reviewData['comment'] ?? 
                     reviewData['review'] ?? 
                     reviewData['text'] ?? 
                     reviewData['content'] ?? 
                     reviewData['reviewText'] ?? 
                     reviewData['review_text'] ?? 
                     reviewData['description'] ?? 
                     'No comment';
    
    int rating = reviewData['rating'] ?? reviewData['stars'] ?? 0;
    Timestamp? timestamp = reviewData['timestamp'] as Timestamp?;
    String formattedDate = timestamp != null 
        ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
        : 'Unknown date';
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'by $userName • $formattedDate',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Replace stars with simple text rating
                          if (rating > 0)
                            Text(
                              'Rating: $rating',
                              style: TextStyle(
                                color: Colors.amber[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Removed star rating widget
              ],
            ),
            const SizedBox(height: 12),
            Text(
              comment,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    _showDeleteConfirmation(context, reviewId, productName);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // We can keep this method for filtering, but we won't display it
  Widget _buildStarRating(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: index < rating ? Colors.amber : Colors.grey,
          size: 18,
        );
      }),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String reviewId,
    String productName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Review'),
          content: Text(
            'Are you sure you want to delete this review for "$productName"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _firestore.collection('reviews').doc(reviewId).delete();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Review deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting review: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
} 