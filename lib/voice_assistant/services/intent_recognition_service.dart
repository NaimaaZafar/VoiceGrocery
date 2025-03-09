import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/intent_model.dart';

/// Service for recognizing intents from user speech using an external AI model
class IntentRecognitionService {
  // You would replace this with your actual AI service API endpoint
  static const String _apiEndpoint = 'https://api.openai.com/v1/chat/completions';
  static const String _apiKey = ''; // Keep this empty; user will need to add their own key
  
  // Fallback for when API isn't available - simple rule-based intent matching
  Intent _fallbackIntentRecognition(String text, String language) {
    // Convert text to lowercase for case-insensitive matching
    final lowerText = text.toLowerCase();
    
    // Common grocery item names in English and Urdu
    final commonGroceryItems = [
      'apple', 'banana', 'orange', 'milk', 'bread', 'eggs', 'chicken', 'rice',
      'سیب', 'کیلا', 'مالٹا', 'دودھ', 'روٹی', 'انڈے', 'چکن', 'چاول'
    ];
    
    // Extract potential item name from text
    String? itemName;
    for (var item in commonGroceryItems) {
      if (lowerText.contains(item.toLowerCase())) {
        itemName = item;
        break;
      }
    }
    
    // Pattern matching for English
    if (language == 'en') {
      if (lowerText.contains('add') && itemName != null) {
        return Intent(
          type: IntentType.addToCart,
          parameters: {'item': itemName},
          originalText: text,
          language: language,
        );
      } else if (lowerText.contains('remove') && itemName != null) {
        return Intent(
          type: IntentType.removeFromCart,
          parameters: {'item': itemName},
          originalText: text,
          language: language,
        );
      } else if (lowerText.contains('check') && lowerText.contains('cart')) {
        return Intent(
          type: IntentType.checkCart,
          parameters: {},
          originalText: text,
          language: language,
        );
      } else if (lowerText.contains('checkout') || (lowerText.contains('check') && lowerText.contains('out'))) {
        return Intent(
          type: IntentType.checkout,
          parameters: {},
          originalText: text,
          language: language,
        );
      } else if (lowerText.contains('search') && itemName != null) {
        return Intent(
          type: IntentType.search,
          parameters: {'query': itemName},
          originalText: text,
          language: language,
        );
      }
    } 
    // Pattern matching for Urdu
    else if (language == 'ur') {
      if ((lowerText.contains('شامل') || lowerText.contains('ڈالو') || lowerText.contains('ڈالیں')) && itemName != null) {
        return Intent(
          type: IntentType.addToCart,
          parameters: {'item': itemName},
          originalText: text,
          language: language,
        );
      } else if ((lowerText.contains('نکالو') || lowerText.contains('نکالیں') || lowerText.contains('ہٹاؤ') || lowerText.contains('ہٹائیں')) && itemName != null) {
        return Intent(
          type: IntentType.removeFromCart,
          parameters: {'item': itemName},
          originalText: text,
          language: language,
        );
      } else if (lowerText.contains('کارٹ') && (lowerText.contains('دیکھو') || lowerText.contains('دیکھیں') || lowerText.contains('چیک'))) {
        return Intent(
          type: IntentType.checkCart,
          parameters: {},
          originalText: text,
          language: language,
        );
      } else if (lowerText.contains('چیک آؤٹ') || lowerText.contains('ادائیگی')) {
        return Intent(
          type: IntentType.checkout,
          parameters: {},
          originalText: text,
          language: language,
        );
      } else if ((lowerText.contains('تلاش') || lowerText.contains('ڈھونڈو') || lowerText.contains('ڈھونڈیں')) && itemName != null) {
        return Intent(
          type: IntentType.search,
          parameters: {'query': itemName},
          originalText: text,
          language: language,
        );
      }
    }
    
    // Default to unknown intent
    return Intent(
      type: IntentType.unknown,
      parameters: {},
      originalText: text,
      language: language,
    );
  }
  
  /// Recognize intent using the AI model or fallback to rule-based matching
  Future<Intent> recognizeIntent(String text, {String language = 'en'}) async {
    // If API key is not provided, use fallback
    if (_apiKey.isEmpty) {
      return _fallbackIntentRecognition(text, language);
    }
    
    try {
      // Create prompt for the AI model
      final prompt = _createPrompt(text, language);
      
      // Call the API
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an AI assistant that extracts intent and parameters from user messages. '
                  'For grocery app commands, identify the intent (add_to_cart, remove_from_cart, '
                  'check_cart, checkout, search, unknown) and extract relevant parameters. '
                  'Respond in JSON format with intent and parameters fields.'
            },
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.1,
          'max_tokens': 150
        }),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];
        
        // Try to parse the JSON response
        try {
          final Map<String, dynamic> jsonContent = jsonDecode(content);
          return Intent(
            type: jsonContent['intent'] ?? IntentType.unknown,
            parameters: jsonContent['parameters'] ?? {},
            originalText: text,
            language: language,
          );
        } catch (e) {
          print('Error parsing API response: $e');
          return _fallbackIntentRecognition(text, language);
        }
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        return _fallbackIntentRecognition(text, language);
      }
    } catch (e) {
      print('Exception during API call: $e');
      return _fallbackIntentRecognition(text, language);
    }
  }
  
  /// Create a prompt for the AI model based on the user's text and language
  String _createPrompt(String text, String language) {
    if (language == 'ur') {
      return '''
Analyze this Urdu text and extract the grocery shopping intent and parameters:
"$text"

Possible intents:
- add_to_cart: Add item to shopping cart
- remove_from_cart: Remove item from cart
- check_cart: View current cart contents
- checkout: Proceed to checkout
- search: Search for products
- unknown: Can't determine intent

Return JSON format:
{
  "intent": "intent_type",
  "parameters": {"item": "product_name"} 
}
''';
    } else {
      return '''
Analyze this English text and extract the grocery shopping intent and parameters:
"$text"

Possible intents:
- add_to_cart: Add item to shopping cart
- remove_from_cart: Remove item from cart
- check_cart: View current cart contents
- checkout: Proceed to checkout
- search: Search for products
- unknown: Can't determine intent

Return JSON format:
{
  "intent": "intent_type",
  "parameters": {"item": "product_name"} 
}
''';
    }
  }
} 