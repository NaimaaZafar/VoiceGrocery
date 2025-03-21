import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/utils/colors.dart';
import 'package:intl/intl.dart';

class AdminFeedbackPage extends StatefulWidget {
  const AdminFeedbackPage({Key? key}) : super(key: key);

  @override
  State<AdminFeedbackPage> createState() => _AdminFeedbackPageState();
}

class _AdminFeedbackPageState extends State<AdminFeedbackPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _ratingFilter;
  
  // Rating options for filtering
  final List<String> ratingLabels = ['All', 'Horrible', 'Was Ok', 'Brilliant'];

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
        title: const Text('App Feedback'),
        backgroundColor: bg_dark,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search feedback...',
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
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      _buildFilterChip('Horrible', 0),
                      _buildFilterChip('Was Ok', 1),
                      _buildFilterChip('Brilliant', 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('feedback').orderBy('timestamp', descending: true).snapshots(),
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
                    child: Text('No feedback found'),
                  );
                }

                // Filter feedback based on search query and rating
                var filteredFeedback = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  
                  // Extract feedback data
                  String feedbackText = (data['feedback'] ?? '').toString().toLowerCase();
                  int rating = data['rating'] ?? 1; // Default to "Was Ok" if not specified
                  
                  // Filter by search query
                  bool matchesSearch = _searchQuery.isEmpty || 
                                      feedbackText.contains(_searchQuery);
                  
                  // Filter by rating
                  bool matchesRating = _ratingFilter == null || rating == _ratingFilter;
                  
                  return matchesSearch && matchesRating;
                }).toList();

                if (filteredFeedback.isEmpty) {
                  return const Center(
                    child: Text('No matching feedback found'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredFeedback.length,
                  itemBuilder: (context, index) {
                    var feedback = filteredFeedback[index];
                    var data = feedback.data() as Map<String, dynamic>;
                    
                    return _buildFeedbackCard(context, feedback.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int? ratingValue) {
    bool isSelected = _ratingFilter == ratingValue;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _ratingFilter = selected ? ratingValue : null;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: bg_dark.withOpacity(0.2),
        checkmarkColor: bg_dark,
        labelStyle: TextStyle(
          color: isSelected ? bg_dark : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context, String feedbackId, Map<String, dynamic> feedbackData) {
    // Extract feedback data
    String feedbackText = feedbackData['feedback'] ?? 'No feedback text';
    int rating = feedbackData['rating'] ?? 1; // Default to "Was Ok" if not specified
    
    // Format timestamp
    Timestamp? timestamp = feedbackData['timestamp'] as Timestamp?;
    String formattedDate = timestamp != null 
        ? DateFormat('MMM d, yyyy h:mm a').format(timestamp.toDate())
        : 'Unknown date';
    
    // Get the appropriate emoji and label based on rating
    IconData emojiIcon;
    String ratingLabel;
    Color emojiColor;
    
    switch (rating) {
      case 0:
        emojiIcon = Icons.sentiment_very_dissatisfied;
        ratingLabel = 'Horrible';
        emojiColor = Colors.red;
        break;
      case 1:
        emojiIcon = Icons.sentiment_neutral;
        ratingLabel = 'Was Ok';
        emojiColor = Colors.amber;
        break;
      case 2:
        emojiIcon = Icons.sentiment_very_satisfied;
        ratingLabel = 'Brilliant';
        emojiColor = Colors.green;
        break;
      default:
        emojiIcon = Icons.sentiment_neutral;
        ratingLabel = 'Unknown';
        emojiColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _showFeedbackDetails(context, feedbackId, feedbackData);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(emojiIcon, color: emojiColor, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              ratingLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: emojiColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      _showDeleteConfirmation(context, feedbackId);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                feedbackText,
                style: const TextStyle(fontSize: 16),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackDetails(BuildContext context, String feedbackId, Map<String, dynamic> feedbackData) {
    String feedbackText = feedbackData['feedback'] ?? 'No feedback text';
    int rating = feedbackData['rating'] ?? 1;
    
    // Format timestamp
    Timestamp? timestamp = feedbackData['timestamp'] as Timestamp?;
    String formattedDate = timestamp != null 
        ? DateFormat('MMM d, yyyy h:mm a').format(timestamp.toDate())
        : 'Unknown date';
    
    // Get the appropriate emoji and label based on rating
    IconData emojiIcon;
    String ratingLabel;
    Color emojiColor;
    
    switch (rating) {
      case 0:
        emojiIcon = Icons.sentiment_very_dissatisfied;
        ratingLabel = 'Horrible';
        emojiColor = Colors.red;
        break;
      case 1:
        emojiIcon = Icons.sentiment_neutral;
        ratingLabel = 'Was Ok';
        emojiColor = Colors.amber;
        break;
      case 2:
        emojiIcon = Icons.sentiment_very_satisfied;
        ratingLabel = 'Brilliant';
        emojiColor = Colors.green;
        break;
      default:
        emojiIcon = Icons.sentiment_neutral;
        ratingLabel = 'Unknown';
        emojiColor = Colors.grey;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(emojiIcon, color: emojiColor),
              const SizedBox(width: 8),
              Text('Feedback Details'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rating: $ratingLabel',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: emojiColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Date: $formattedDate'),
                const SizedBox(height: 16),
                const Text(
                  'Feedback:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(feedbackText),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, feedbackId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String feedbackId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Feedback'),
          content: const Text(
            'Are you sure you want to delete this feedback? This action cannot be undone.',
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
                  await _firestore.collection('feedback').doc(feedbackId).delete();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Feedback deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting feedback: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
} 