import 'package:flutter/material.dart';
import 'package:fyp/screens/cart_fav_provider.dart';
import 'package:fyp/screens/profile.dart';
import 'package:fyp/screens/category.dart';
import 'package:fyp/screens/fav.dart';
import 'package:fyp/screens/settings.dart';
import 'package:fyp/screens/checkout.dart';
import 'package:fyp/screens/voice_recognition.dart';
import 'package:fyp/utils/food_menu.dart';
import 'package:fyp/utils/text_to_speech_service.dart';
import 'package:fyp/utils/voice_responses.dart';
import 'package:fyp/widgets/navbar.dart';
import 'package:fyp/widgets/button.dart';
import 'package:provider/provider.dart';
import '../widgets/product_card_add_remove.dart';

class MyCart extends StatefulWidget {
  final List<String>? itemsToRemove;
  final String? sourceLanguage; // The language detected from voice input
  final bool isCheckoutIntent; // Flag to indicate checkout intent
  
  const MyCart({
    super.key,
    this.itemsToRemove,
    this.sourceLanguage,
    this.isCheckoutIntent = false,
  });

  @override
  State<MyCart> createState() => _MyCartState();
}

class _MyCartState extends State<MyCart> {
  int _selectedIndex = 0;
  final _ttsService = TextToSpeechService();
  String _languageCode = 'en'; // Default language

  // List to track whether an item is selected
  List<bool> selectedItems = [];
  
  @override
  void initState() {
    super.initState();
    
    // Set the language from the source or default to English
    _languageCode = widget.sourceLanguage ?? 'en';
    
    // Process items to remove if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.itemsToRemove != null && widget.itemsToRemove!.isNotEmpty) {
        _processItemsToRemove();
      }
      
      // If checkout intent is true, start the checkout process
      if (widget.isCheckoutIntent) {
        _startCheckoutProcess();
      }
    });
  }
  
  void _speak(String responseKey) {
    final message = VoiceResponses.getResponse(_languageCode, responseKey);
    _ttsService.speakWithLanguage(message, _languageCode);
  }
  
  void _processItemsToRemove() {
    final cartFavoriteProvider = Provider.of<CartFavoriteProvider>(context, listen: false);
    List<Food> itemsToRemove = [];
    
    // Find items in cart that match the names provided
    for (String itemName in widget.itemsToRemove!) {
      for (Food food in cartFavoriteProvider.cartItems) {
        if (food.name.toLowerCase().contains(itemName.toLowerCase())) {
          itemsToRemove.add(food);
        }
      }
    }
    
    // If items to remove are found, show a confirmation dialog
    if (itemsToRemove.isNotEmpty) {
      // Speak the confirmation prompt
      _speak('remove_from_cart');
      _showRemoveConfirmationDialog(itemsToRemove, autoConfirm: true);
    } else {
      // If no matching items are found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No items matching "${widget.itemsToRemove!.join(', ')}" found in your cart.'),
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Speak the error message
      _speak('item_not_found');
    }
  }
  
  void _showRemoveConfirmationDialog(List<Food> itemsToRemove, {bool autoConfirm = false}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Items'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Do you want to remove these items from your cart?'),
            const SizedBox(height: 10),
            ...itemsToRemove.map((food) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Image.asset(food.imagePath, width: 40, height: 40),
                  const SizedBox(width: 10),
                  Text(food.name),
                ],
              ),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final cartFavoriteProvider = Provider.of<CartFavoriteProvider>(context, listen: false);
              
              // Remove each item
              for (Food food in itemsToRemove) {
                cartFavoriteProvider.removeFromCart(food);
              }
              
              Navigator.of(dialogContext).pop();
              
              // Show confirmation message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${itemsToRemove.length} item(s) removed from your cart'),
                  duration: const Duration(seconds: 2),
                ),
              );
              
              // Speak confirmation message
              _speak('remove_from_cart_confirm');
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    // Auto-confirm after a short delay if requested
    if (autoConfirm) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        // Make sure the dialog is still showing before trying to confirm
        if (Navigator.of(context).canPop()) {
          final cartFavoriteProvider = Provider.of<CartFavoriteProvider>(context, listen: false);
          
          // Remove each item
          for (Food food in itemsToRemove) {
            cartFavoriteProvider.removeFromCart(food);
          }
          
          // Close the dialog
          Navigator.of(context).pop();
          
          // Show confirmation message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${itemsToRemove.length} item(s) removed from your cart'),
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Speak confirmation message
          _speak('remove_from_cart_confirm');
        }
      });
    }
  }

  // Start the checkout process
  void _startCheckoutProcess() {
    final cartFavoriteProvider = Provider.of<CartFavoriteProvider>(context, listen: false);
    
    // Check if cart is empty
    if (cartFavoriteProvider.cartItems.isEmpty) {
      _speak('empty_cart');
      return;
    }
    
    // Select all items in the cart
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        selectedItems = List.generate(cartFavoriteProvider.cartItems.length, (index) => true);
      });
      
      // After selecting all items, proceed to checkout
      Future.delayed(const Duration(seconds: 2), () {
        // Get the selected Food objects
        final selectedFoods = cartFavoriteProvider.cartItems.where((food) {
          final index = cartFavoriteProvider.cartItems.indexOf(food);
          return selectedItems[index];
        }).toList();

        // Convert Food objects to Map<String, dynamic>
        final itemsForCheckout = selectedFoods.map((food) {
          return {
            'food': food,
            'name': food.name,
            'price': food.price,
            'quantity': food.quantity,
            'imagePath': food.imagePath,
          };
        }).toList();
        
        // Navigate to checkout screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutScreen(
              selectedItems: itemsForCheckout,
              useVoiceInput: true,
              sourceLanguage: widget.sourceLanguage,
            )
          ),
        );
      });
    });
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Using Navigator to push replacement
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CategoryScreen(categoryName: '')),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FavScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AccountsPage()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VoiceRecognitionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartFavoriteProvider = Provider.of<CartFavoriteProvider>(context);

    // Initialize selectedItems list if it's empty
    if (selectedItems.isEmpty) {
      selectedItems = List.generate(cartFavoriteProvider.cartItems.length, (index) => false);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B57B2),
        elevation: 0,
        title: const Text('My Cart', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CategoryScreen(categoryName: 'MeatsFishes')),
            );
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content displaying cart items
          cartFavoriteProvider.cartItems.isEmpty
              ? const Center(child: Text('Your cart is currently empty.', style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
            itemCount: cartFavoriteProvider.cartItems.length,
            itemBuilder: (context, index) {
              return Card(
                color: Colors.white, // Set the card background color to white
                elevation: 2, // Optional: Adjust the elevation for the card shadow
                child: CheckboxListTile(
                  title: ProductCardAddRemove(food: cartFavoriteProvider.cartItems[index]),
                  value: selectedItems[index],
                  onChanged: (bool? value) {
                    setState(() {
                      selectedItems[index] = value ?? false;
                    });
                  },
                ),
              );
            },
          ),
          // "Buy Now" Button
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Button(
              onTap: () {
                // Filter the selected items
                final selectedFoods = cartFavoriteProvider.cartItems.where((food) {
                  final index = cartFavoriteProvider.cartItems.indexOf(food);
                  return selectedItems[index]; // Check if the item is selected
                }).toList();

                // Convert Food objects to Map<String, dynamic>
                final itemsForCheckout = selectedFoods.map((food) {
                  return {
                    'food': food,
                    'name': food.name,
                    'price': food.price,
                    'quantity': food.quantity,
                    'imagePath': food.imagePath,
                  };
                }).toList();

                // Pass the selected items to the CheckoutScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CheckoutScreen(selectedItems: itemsForCheckout)),
                );
              },
              text: 'Buy Now',
            ),
          ),
          const SizedBox(height: 30),
          // Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomNavBar(
              currentIndex: _selectedIndex,
              onItemSelected: _onItemSelected,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
