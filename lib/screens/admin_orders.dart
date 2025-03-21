import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/utils/colors.dart';
import 'package:intl/intl.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({Key? key}) : super(key: key);

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';
  
  // Possible order statuses
  final List<String> orderStatuses = [
    'All',
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];

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
        title: const Text('Manage Orders'),
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
                    hintText: 'Search by order ID or customer name...',
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
                    children: orderStatuses.map((status) => _buildFilterChip(status)).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('orders').snapshots(),
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
                    child: Text('No orders found'),
                  );
                }

                // Print the first document for debugging
                if (snapshot.data!.docs.isNotEmpty) {
                  print('First order document: ${snapshot.data!.docs[0].data()}');
                }

                // Filter orders based on search query and status filter
                var filteredOrders = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  
                  // Extract order data
                  String orderId = doc.id.toLowerCase();
                  String customerName = ((data['customerName'] ?? 
                                     data['customer_name'] ?? 
                                     data['userName'] ?? 
                                     data['user_name'] ?? 
                                     data['name'] ?? '')).toString().toLowerCase();
                  String email = (data['email'] ?? '').toString().toLowerCase();
                  String phone = (data['phone'] ?? data['phoneNumber'] ?? data['phone_number'] ?? '').toString().toLowerCase();
                  String status = (data['status'] ?? data['orderStatus'] ?? data['order_status'] ?? 'Pending').toString();
                  
                  // Filter by search query
                  bool matchesSearch = _searchQuery.isEmpty || 
                                      orderId.contains(_searchQuery) ||
                                      customerName.contains(_searchQuery) ||
                                      email.contains(_searchQuery) ||
                                      phone.contains(_searchQuery);
                  
                  // Filter by status
                  bool matchesStatus = _selectedStatus == 'All' || 
                                      status.toLowerCase() == _selectedStatus.toLowerCase();
                  
                  return matchesSearch && matchesStatus;
                }).toList();

                // Sort orders by date (most recent first)
                filteredOrders.sort((a, b) {
                  var aData = a.data() as Map<String, dynamic>;
                  var bData = b.data() as Map<String, dynamic>;
                  
                  Timestamp? aTimestamp = aData['timestamp'] ?? aData['date'] ?? aData['orderDate'] ?? aData['order_date'];
                  Timestamp? bTimestamp = bData['timestamp'] ?? bData['date'] ?? bData['orderDate'] ?? bData['order_date'];
                  
                  if (aTimestamp == null && bTimestamp == null) return 0;
                  if (aTimestamp == null) return 1;
                  if (bTimestamp == null) return -1;
                  
                  if (aTimestamp is Timestamp && bTimestamp is Timestamp) {
                    return bTimestamp.compareTo(aTimestamp); // Most recent first
                  }
                  
                  return 0;
                });

                if (filteredOrders.isEmpty) {
                  return const Center(
                    child: Text('No matching orders found'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    var order = filteredOrders[index];
                    var data = order.data() as Map<String, dynamic>;
                    
                    return _buildOrderCard(context, order.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedStatus == label;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = selected ? label : 'All';
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

  Widget _buildOrderCard(BuildContext context, String orderId, Map<String, dynamic> orderData) {
    // Extract order data with fallbacks for different field names
    String customerName = orderData['customerName'] ?? 
                       orderData['customer_name'] ?? 
                       orderData['userName'] ?? 
                       orderData['user_name'] ?? 
                       orderData['name'] ?? 
                       'Unknown Customer';
    
    // Extract timestamp with fallbacks
    dynamic timestamp = orderData['timestamp'] ?? 
                       orderData['date'] ?? 
                       orderData['orderDate'] ?? 
                       orderData['order_date'];
                       
    String formattedDate = 'Unknown date';
    if (timestamp is Timestamp) {
      formattedDate = DateFormat('MMM d, yyyy h:mm a').format(timestamp.toDate());
    }
    
    // Extract status with fallbacks
    String status = orderData['status'] ?? 
                 orderData['orderStatus'] ?? 
                 orderData['order_status'] ?? 
                 'Pending';
                 
    // Extract total amount with fallbacks
    num totalAmount = 0;
    
    if (orderData.containsKey('totalAmount')) {
      totalAmount = orderData['totalAmount'] ?? 0;
    } else if (orderData.containsKey('total_amount')) {
      totalAmount = orderData['total_amount'] ?? 0;
    } else if (orderData.containsKey('total')) {
      totalAmount = orderData['total'] ?? 0;
    }
    
    // Get items count
    int itemCount = 0;
    if (orderData.containsKey('items') && orderData['items'] is List) {
      itemCount = (orderData['items'] as List).length;
    } else if (orderData.containsKey('cartItems') && orderData['cartItems'] is List) {
      itemCount = (orderData['cartItems'] as List).length;
    } else if (orderData.containsKey('cart_items') && orderData['cart_items'] is List) {
      itemCount = (orderData['cart_items'] as List).length;
    } else if (orderData.containsKey('products') && orderData['products'] is List) {
      itemCount = (orderData['products'] as List).length;
    }
    
    // Get color based on status
    Color statusColor = _getStatusColor(status);
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _showOrderDetails(context, orderId, orderData);
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
                        Text(
                          'Order #${orderId.substring(0, min(8, orderId.length))}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By $customerName',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, String orderId, Map<String, dynamic> orderData) {
    // Print order data for debugging
    print('Order details: $orderData');
    
    // Extract customer information
    String customerName = orderData['customerName'] ?? 
                       orderData['customer_name'] ?? 
                       orderData['userName'] ?? 
                       orderData['user_name'] ?? 
                       orderData['name'] ?? 
                       'Unknown Customer';
    
    String email = orderData['email'] ?? orderData['customerEmail'] ?? orderData['customer_email'] ?? 'Not provided';
    String phone = orderData['phone'] ?? orderData['phoneNumber'] ?? orderData['phone_number'] ?? 'Not provided';
    String address = orderData['address'] ?? orderData['deliveryAddress'] ?? orderData['delivery_address'] ?? 'Not provided';
    
    // Extract order status
    String status = orderData['status'] ?? 
                 orderData['orderStatus'] ?? 
                 orderData['order_status'] ?? 
                 'Pending';
    
    // Extract payment method
    String paymentMethod = orderData['paymentMethod'] ?? 
                        orderData['payment_method'] ?? 
                        orderData['payment'] ?? 
                        'Not specified';
    
    // Extract order items
    List<dynamic> items = [];
    if (orderData.containsKey('items') && orderData['items'] is List) {
      items = orderData['items'];
    } else if (orderData.containsKey('cartItems') && orderData['cartItems'] is List) {
      items = orderData['cartItems'];
    } else if (orderData.containsKey('cart_items') && orderData['cart_items'] is List) {
      items = orderData['cart_items'];
    } else if (orderData.containsKey('products') && orderData['products'] is List) {
      items = orderData['products'];
    }
    
    // Extract total amount
    num totalAmount = 0;
    if (orderData.containsKey('totalAmount')) {
      totalAmount = orderData['totalAmount'] ?? 0;
    } else if (orderData.containsKey('total_amount')) {
      totalAmount = orderData['total_amount'] ?? 0;
    } else if (orderData.containsKey('total')) {
      totalAmount = orderData['total'] ?? 0;
    }
    
    // Show order details in a dialog
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${orderId.substring(0, min(8, orderId.length))}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Information
                        _buildSectionTitle('Customer Information'),
                        _buildDetailItem('Name', customerName),
                        _buildDetailItem('Email', email),
                        _buildDetailItem('Phone', phone),
                        _buildDetailItem('Address', address),
                        
                        const SizedBox(height: 16),
                        
                        // Order Information
                        _buildSectionTitle('Order Information'),
                        _buildStatusDropdown(context, orderId, status),
                        _buildDetailItem('Payment Method', paymentMethod),
                        
                        const SizedBox(height: 16),
                        
                        // Order Items
                        _buildSectionTitle('Order Items'),
                        ...items.map((item) => _buildOrderItem(item)).toList(),
                        
                        const Divider(),
                        
                        // Order Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '₹${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Delete Order', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.pop(context);
                        _showDeleteConfirmation(context, orderId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: bg_dark,
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context, String orderId, String currentStatus) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: Text(
              'Status:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: DropdownButton<String>(
                value: currentStatus,
                isExpanded: true,
                underline: const SizedBox(), // Remove the default underline
                items: orderStatuses.where((status) => status != 'All').map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _updateOrderStatus(orderId, newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(dynamic item) {
    // Debug print to see item structure
    print('Order item: $item');
    
    // Extract item details with fallbacks for different field names
    String name = '';
    int quantity = 1;
    num price = 0;
    
    if (item is Map) {
      // Try to extract product name
      name = item['name'] ?? 
             item['productName'] ?? 
             item['product_name'] ?? 
             'Unknown Item';
      
      // Try to extract quantity
      quantity = item['quantity'] ?? 
                item['qty'] ?? 
                item['count'] ?? 
                1;
      
      // Try to extract price
      price = item['price'] ?? 
             item['unitPrice'] ?? 
             item['unit_price'] ?? 
             0;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(name),
          ),
          Expanded(
            flex: 1,
            child: Text('x$quantity'),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹${price.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _updateOrderStatus(String orderId, String newStatus) {
    _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
      'orderStatus': newStatus,
      'order_status': newStatus,
      'lastUpdated': FieldValue.serverTimestamp(),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order status: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _showDeleteConfirmation(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Order'),
          content: const Text(
            'Are you sure you want to delete this order? This action cannot be undone.',
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
                  await _firestore.collection('orders').doc(orderId).delete();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting order: $e'),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  int min(int a, int b) {
    return a < b ? a : b;
  }
} 