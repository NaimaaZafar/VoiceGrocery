import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fyp/screens/cart_fav_provider.dart';
import 'package:fyp/utils/food_menu.dart';
import 'package:fyp/screens/my_cart.dart';
import 'speech_service.dart';
import 'intent_recognition_service.dart';
import '../models/intent_model.dart';

class VoiceAssistantService {
  final SpeechService _speechService = SpeechService();
  final IntentRecognitionService _intentService = IntentRecognitionService();
  
  // Stream controllers and status
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;
  
  // Language detection map
  final Map<String, String> _languageDetectionMap = {
    'en_US': 'en',
    'ur_PK': 'ur',
  };
  
  Future<bool> initialize() async {
    return await _speechService.initialize();
  }
  
  /// Start listening for voice commands
  Future<void> startListening() async {
    await _speechService.startListening();
  }
  
  /// Stop listening for voice commands
  Future<void> stopListening() async {
    await _speechService.stopListening();
  }
  
  /// Get the current language
  String getCurrentLanguage() {
    return _speechService.getCurrentLanguageName();
  }
  
  /// Toggle between English and Urdu
  Future<String> toggleLanguage() async {
    return await _speechService.toggleLanguage();
  }
  
  /// Process the recognized text to extract intent and execute actions
  Future<void> processVoiceCommand(BuildContext context) async {
    if (_isProcessing) return;
    
    _isProcessing = true;
    
    try {
      // Get recognized text from speech service
      final text = _speechService.recognizedText;
      if (text.isEmpty) {
        _isProcessing = false;
        return;
      }
      
      // Determine language from speech service's selected language
      final speechLanguage = _speechService._selectedLanguage;
      final language = _languageDetectionMap[speechLanguage] ?? 'en';
      
      // Recognize intent
      final intent = await _intentService.recognizeIntent(text, language: language);
      
      // Handle the intent
      await _handleIntent(context, intent);
      
    } catch (e) {
      print('Error processing voice command: $e');
      
      // Provide feedback about the error
      await _speechService.speak(
        language == 'ur' ? 'معذرت، کوئی خرابی ہوئی ہے۔' : 'Sorry, there was an error.',
        language: language == 'ur' ? 'ur-PK' : 'en-US'
      );
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Handle the recognized intent by executing corresponding actions
  Future<void> _handleIntent(BuildContext context, Intent intent) async {
    final cartProvider = Provider.of<CartFavoriteProvider>(context, listen: false);
    final restaurant = Provider.of<Restaurant>(context, listen: false);
    
    String responseText = '';
    bool success = false;
    
    switch (intent.type) {
      case IntentType.addToCart:
        final itemName = intent.parameters['item'] as String?;
        if (itemName != null) {
          // Find the item in the restaurant menu
          final food = _findItemInMenu(restaurant, itemName);
          
          if (food != null) {
            // Add the item to cart
            cartProvider.addToCart(food);
            success = true;
            
            // Prepare response
            responseText = intent.language == 'ur'
                ? '${food.name} کارٹ میں شامل کر دیا گیا ہے'
                : '${food.name} has been added to your cart';
          } else {
            responseText = intent.language == 'ur'
                ? 'معذرت، ${itemName} نہیں ملا'
                : 'Sorry, could not find ${itemName}';
          }
        } else {
          responseText = intent.language == 'ur'
              ? 'معذرت، کونسا آئٹم شامل کرنا ہے؟'
              : 'Sorry, which item would you like to add?';
        }
        break;
        
      case IntentType.removeFromCart:
        final itemName = intent.parameters['item'] as String?;
        if (itemName != null) {
          // Find the item in the cart
          final foodInCart = _findItemInCart(cartProvider, itemName);
          
          if (foodInCart != null) {
            // Remove the item from cart
            cartProvider.removeFromCart(foodInCart);
            success = true;
            
            // Prepare response
            responseText = intent.language == 'ur'
                ? '${foodInCart.name} کارٹ سے نکال دیا گیا ہے'
                : '${foodInCart.name} has been removed from your cart';
          } else {
            responseText = intent.language == 'ur'
                ? 'معذرت، ${itemName} آپ کے کارٹ میں نہیں ہے'
                : 'Sorry, ${itemName} is not in your cart';
          }
        } else {
          responseText = intent.language == 'ur'
              ? 'معذرت، کونسا آئٹم نکالنا ہے؟'
              : 'Sorry, which item would you like to remove?';
        }
        break;
        
      case IntentType.checkCart:
        final cartItems = cartProvider.cartItems;
        if (cartItems.isEmpty) {
          responseText = intent.language == 'ur'
              ? 'آپ کا کارٹ خالی ہے'
              : 'Your cart is empty';
        } else {
          if (intent.language == 'ur') {
            responseText = 'آپ کے کارٹ میں ${cartItems.length} آئٹمز ہیں';
          } else {
            responseText = 'You have ${cartItems.length} items in your cart';
          }
          
          // Navigate to cart
          _navigateToCart(context);
          success = true;
        }
        break;
        
      case IntentType.checkout:
        final cartItems = cartProvider.cartItems;
        if (cartItems.isEmpty) {
          responseText = intent.language == 'ur'
              ? 'معذرت، آپ کا کارٹ خالی ہے'
              : 'Sorry, your cart is empty';
        } else {
          responseText = intent.language == 'ur'
              ? 'چیک آؤٹ پر جا رہے ہیں'
              : 'Proceeding to checkout';
              
          // Navigate to cart (which has checkout button)
          _navigateToCart(context);
          success = true;
        }
        break;
        
      case IntentType.search:
        final query = intent.parameters['query'] as String?;
        if (query != null) {
          // Here you would navigate to search results
          // For this example, we'll just create a response
          responseText = intent.language == 'ur'
              ? '${query} کو تلاش کر رہے ہیں'
              : 'Searching for ${query}';
          success = true;
        } else {
          responseText = intent.language == 'ur'
              ? 'معذرت، آپ کیا تلاش کرنا چاہتے ہیں؟'
              : 'Sorry, what would you like to search for?';
        }
        break;
        
      case IntentType.unknown:
      default:
        responseText = intent.language == 'ur'
            ? 'معذرت، مجھے سمجھ نہیں آیا۔ براہ کرم دوبارہ کوشش کریں'
            : 'Sorry, I didn\'t understand. Please try again';
        break;
    }
    
    // Speak the response
    final language = intent.language == 'ur' ? 'ur-PK' : 'en-US';
    await _speechService.speak(responseText, language: language);
    
    return success;
  }
  
  /// Find an item in the restaurant menu by name (case-insensitive partial match)
  Food? _findItemInMenu(Restaurant restaurant, String itemName) {
    final normalizedItemName = itemName.toLowerCase();
    
    for (var food in restaurant.menu) {
      if (food.name.toLowerCase().contains(normalizedItemName)) {
        return food;
      }
    }
    
    return null;
  }
  
  /// Find an item in the cart by name (case-insensitive partial match)
  Food? _findItemInCart(CartFavoriteProvider cartProvider, String itemName) {
    final normalizedItemName = itemName.toLowerCase();
    
    for (var food in cartProvider.cartItems) {
      if (food.name.toLowerCase().contains(normalizedItemName)) {
        return food;
      }
    }
    
    return null;
  }
  
  /// Navigate to the cart screen
  void _navigateToCart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyCart()),
    );
  }
  
  /// Dispose resources
  void dispose() {
    _speechService.dispose();
  }
} 