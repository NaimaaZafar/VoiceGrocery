import 'package:flutter/material.dart';
import 'package:fyp/utils/checkoutDetails.dart';
import 'package:fyp/utils/colors.dart';
import 'package:fyp/utils/food_menu.dart';
import 'package:fyp/widgets/button.dart';
import 'package:fyp/widgets/product_card_add_remove.dart'; // Import your food model to work with

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedItems;
  final bool useVoiceInput;
  final String? sourceLanguage;

  const CheckoutScreen({
    Key? key, 
    required this.selectedItems,
    this.useVoiceInput = false,
    this.sourceLanguage,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  @override
  void initState() {
    super.initState();
    
    // If voice input is enabled, automatically continue to checkout details
    if (widget.useVoiceInput) {
      // Add slight delay to let the screen render first
      Future.delayed(const Duration(milliseconds: 500), () {
        _continueToCheckoutDetails();
      });
    }
  }
  
  // Calculate total price
  double _calculateTotalPrice() {
    return widget.selectedItems.fold(0, (sum, item) => sum + item['price']*item['quantity']);
  }
  
  // Navigate to checkout details
  void _continueToCheckoutDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutDetails(
          selectedItems: widget.selectedItems,
          totalPrice: _calculateTotalPrice(),
          useVoiceInput: widget.useVoiceInput,
          sourceLanguage: widget.sourceLanguage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Checkout",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: bg_dark,
        elevation: 10,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: widget.selectedItems.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ProductCardAddRemove(food: widget.selectedItems[index]['food']),
                  );
                },
              ),
            ),
            Text('Total Price: \$${_calculateTotalPrice().toStringAsFixed(2)}'),
            const SizedBox(height: 20),
            Button(
              text: "Continue", 
              onTap: _continueToCheckoutDetails,
            ),
          ],
        ),
      ),
    );
  }
}
