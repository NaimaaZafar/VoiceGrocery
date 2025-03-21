import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/utils/colors.dart';
import 'dart:convert';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({Key? key}) : super(key: key);

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
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
        title: const Text('Manage Products'),
        backgroundColor: bg_dark,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
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
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddProductDialog(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bg_dark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('products').snapshots(),
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
                    child: Text('No products found'),
                  );
                }

                // Filter products based on search query
                var filteredProducts = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String productName = (data['name'] ?? '').toString().toLowerCase();
                  String category = (data['category'] ?? '').toString().toLowerCase();
                  
                  // Also search in descriptions if available
                  Map<String, dynamic> descriptions = data['descriptions'] ?? {};
                  String descEn = (descriptions['en'] ?? '').toString().toLowerCase();
                  String descUr = (descriptions['ur'] ?? '').toString().toLowerCase();
                  String descHi = (descriptions['hi'] ?? '').toString().toLowerCase();
                  
                  return _searchQuery.isEmpty || 
                         productName.contains(_searchQuery) ||
                         category.contains(_searchQuery) ||
                         descEn.contains(_searchQuery) ||
                         descUr.contains(_searchQuery) ||
                         descHi.contains(_searchQuery);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text('No matching products found'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    var product = filteredProducts[index];
                    var data = product.data() as Map<String, dynamic>;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: data['imagePath'] != null && data['imagePath'].toString().isNotEmpty
                            ? Image.network(
                                data['imagePath'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.error),
                                  );
                                },
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image),
                              ),
                        title: Text(
                          data['name'] ?? 'Unnamed Product',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Price: ₹${data['price'] ?? 0}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showEditProductDialog(context, product.id, data);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmation(context, product.id, data['name']);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          _showProductDetails(context, data);
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

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final imagePathController = TextEditingController();
    final englishDescController = TextEditingController();
    final urduDescController = TextEditingController();
    final hindiDescController = TextEditingController();
    String selectedCategory = 'MeatsFishes';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                  ),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (₹)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: imagePathController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'MeatsFishes',
                      child: Text('Meats & Fishes'),
                    ),
                    DropdownMenuItem(
                      value: 'FreshVegetables',
                      child: Text('Fresh Vegetables'),
                    ),
                    DropdownMenuItem(
                      value: 'FreshFruits',
                      child: Text('Fresh Fruits'),
                    ),
                    DropdownMenuItem(
                      value: 'Snacks',
                      child: Text('Snacks'),
                    ),
                    DropdownMenuItem(
                      value: 'BrookiBakery',
                      child: Text('Bakery Items'),
                    ),
                  ],
                  onChanged: (value) {
                    selectedCategory = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: englishDescController,
                  decoration: const InputDecoration(
                    labelText: 'English Description',
                  ),
                  maxLines: 2,
                ),
                TextField(
                  controller: urduDescController,
                  decoration: const InputDecoration(
                    labelText: 'Urdu Description',
                  ),
                  maxLines: 2,
                ),
                TextField(
                  controller: hindiDescController,
                  decoration: const InputDecoration(
                    labelText: 'Hindi Description',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
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
                if (nameController.text.isEmpty ||
                    priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name and price are required'),
                    ),
                  );
                  return;
                }

                try {
                  await _firestore.collection('products').add({
                    'name': nameController.text,
                    'price': int.parse(priceController.text),
                    'imagePath': imagePathController.text,
                    'category': selectedCategory,
                    'descriptions': {
                      'en': englishDescController.text,
                      'ur': urduDescController.text,
                      'hi': hindiDescController.text,
                    },
                    'quantity': 100, // Default quantity
                    'Fav': false,
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding product: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: bg_dark,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditProductDialog(
    BuildContext context,
    String productId,
    Map<String, dynamic> productData,
  ) {
    final nameController = TextEditingController(text: productData['name']);
    final priceController = TextEditingController(
      text: productData['price'].toString(),
    );
    final imagePathController = TextEditingController(
      text: productData['imagePath'],
    );
    
    Map<String, dynamic> descriptions = productData['descriptions'] ?? {};
    
    final englishDescController = TextEditingController(
      text: descriptions['en'] ?? '',
    );
    final urduDescController = TextEditingController(
      text: descriptions['ur'] ?? '',
    );
    final hindiDescController = TextEditingController(
      text: descriptions['hi'] ?? '',
    );
    
    String selectedCategory = productData['category'] ?? 'MeatsFishes';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                  ),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (₹)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: imagePathController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'MeatsFishes',
                      child: Text('Meats & Fishes'),
                    ),
                    DropdownMenuItem(
                      value: 'FreshVegetables',
                      child: Text('Fresh Vegetables'),
                    ),
                    DropdownMenuItem(
                      value: 'FreshFruits',
                      child: Text('Fresh Fruits'),
                    ),
                    DropdownMenuItem(
                      value: 'Snacks',
                      child: Text('Snacks'),
                    ),
                    DropdownMenuItem(
                      value: 'BrookiBakery',
                      child: Text('Bakery Items'),
                    ),
                  ],
                  onChanged: (value) {
                    selectedCategory = value!;
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: englishDescController,
                  decoration: const InputDecoration(
                    labelText: 'English Description',
                  ),
                  maxLines: 2,
                ),
                TextField(
                  controller: urduDescController,
                  decoration: const InputDecoration(
                    labelText: 'Urdu Description',
                  ),
                  maxLines: 2,
                ),
                TextField(
                  controller: hindiDescController,
                  decoration: const InputDecoration(
                    labelText: 'Hindi Description',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
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
                if (nameController.text.isEmpty ||
                    priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name and price are required'),
                    ),
                  );
                  return;
                }

                try {
                  await _firestore.collection('products').doc(productId).update({
                    'name': nameController.text,
                    'price': int.parse(priceController.text),
                    'imagePath': imagePathController.text,
                    'category': selectedCategory,
                    'descriptions': {
                      'en': englishDescController.text,
                      'ur': urduDescController.text,
                      'hi': hindiDescController.text,
                    },
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating product: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: bg_dark,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String productId,
    String productName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text(
            'Are you sure you want to delete "$productName"? This action cannot be undone.',
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
                  await _firestore.collection('products').doc(productId).delete();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$productName deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting product: $e'),
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

  void _showProductDetails(
    BuildContext context,
    Map<String, dynamic> productData,
  ) {
    Map<String, dynamic> descriptions = productData['descriptions'] ?? {};
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(productData['name'] ?? 'Product Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (productData['imagePath'] != null &&
                    productData['imagePath'].toString().isNotEmpty)
                  Center(
                    child: Image.network(
                      productData['imagePath'],
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.error)),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Price: ₹${productData['price'] ?? 0}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Category: ${productData['category'] ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Descriptions:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDescriptionItem('English', descriptions['en'] ?? 'No description'),
                _buildDescriptionItem('Urdu', descriptions['ur'] ?? 'No description'),
                _buildDescriptionItem('Hindi', descriptions['hi'] ?? 'No description'),
                const SizedBox(height: 8),
                Text(
                  'Quantity in Stock: ${productData['quantity'] ?? 0}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: bg_dark,
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDescriptionItem(String language, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$language:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(description),
        ],
      ),
    );
  }
} 