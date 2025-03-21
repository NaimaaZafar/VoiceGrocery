import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/utils/colors.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({Key? key}) : super(key: key);

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _currentUserId = '';

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
        title: const Text('Manage Users'),
        backgroundColor: bg_dark,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
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
              stream: _firestore.collection('users').snapshots(),
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
                    child: Text('No users found'),
                  );
                }

                // Filter users based on search query
                var filteredUsers = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String username = (data['username'] ?? '').toString().toLowerCase();
                  String email = (data['email'] ?? '').toString().toLowerCase();
                  String firstName = (data['first name'] ?? data['firstName'] ?? '').toString().toLowerCase();
                  String lastName = (data['last name'] ?? data['lastName'] ?? '').toString().toLowerCase();
                  
                  return _searchQuery.isEmpty || 
                         username.contains(_searchQuery) ||
                         email.contains(_searchQuery) ||
                         firstName.contains(_searchQuery) ||
                         lastName.contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(
                    child: Text('No matching users found'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    var user = filteredUsers[index];
                    var data = user.data() as Map<String, dynamic>;
                    
                    // Determine if this is the admin user to prevent modification
                    bool isAdmin = (data['email'] ?? '').toString() == 'admin@gmail.com';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAdmin ? Colors.orange : Colors.blue,
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          data['username'] ?? data['email'] ?? 'Unknown User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isAdmin ? Colors.orange.shade800 : Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['email'] ?? 'No email'),
                            if (data['phone number'] != null)
                              Text('Phone: ${data['phone number']}'),
                            if (data['phone'] != null && data['phone number'] == null)
                              Text('Phone: ${data['phone']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () {
                                _currentUserId = user.id;
                                _showUserDetails(context, data);
                              },
                            ),
                            if (!isAdmin) // Only show delete for non-admin users
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _showDeleteConfirmation(context, user.id, data['username'] ?? data['email'] ?? 'this user');
                                },
                              ),
                          ],
                        ),
                        onTap: () {
                          _currentUserId = user.id;
                          _showUserDetails(context, data);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(
    BuildContext context,
    Map<String, dynamic> userData,
  ) {
    // Print userData to debug console to see actual structure
    print('User data: $userData');
    print('Current user ID: $_currentUserId');
    
    String email = userData['email'] ?? 'No email';
    bool isAdmin = email == 'admin@gmail.com';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: isAdmin ? Colors.orange : Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  userData['username'] ?? email,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSimpleDetailItem('Email', email),
              _buildSimpleDetailItem('First Name', userData['first name'] ?? userData['firstName'] ?? 'Not available'),
              _buildSimpleDetailItem('Last Name', userData['last name'] ?? userData['lastName'] ?? 'Not available'),
              _buildSimpleDetailItem('Phone', userData['phone number'] ?? userData['phone'] ?? 'Not available'),
              if (isAdmin)
                _buildSimpleDetailItem('Role', 'Administrator'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
            if (!isAdmin)
              ElevatedButton(
                onPressed: () {
                  // Handle delete with the correct document ID
                  Navigator.pop(context);
                  _showDeleteConfirmation(
                    context, 
                    _currentUserId, 
                    userData['username'] ?? userData['email'] ?? 'this user'
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Delete User'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSimpleDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String userId,
    String userName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User'),
          content: Text(
            'Are you sure you want to delete "$userName"? This action cannot be undone and will remove all user data.',
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
                  // Delete user from Firestore
                  await _firestore.collection('users').doc(userId).delete();
                  
                  // Note: This doesn't delete the user from Firebase Authentication
                  // In a production app, you would need admin SDK or Cloud Functions
                  // to fully delete the user from Auth as well
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$userName deleted from database'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting user: $e'),
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