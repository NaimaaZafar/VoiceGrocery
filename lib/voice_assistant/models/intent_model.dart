import 'package:flutter/foundation.dart';

/// Represents the intent of a user's voice command
class Intent {
  /// The type of intent recognized (e.g., "add_to_cart", "remove_from_cart")
  final String type;
  
  /// The parameters extracted from the voice command (e.g., product name)
  final Map<String, dynamic> parameters;
  
  /// Original text from speech recognition
  final String originalText;
  
  /// The language detected (e.g., 'en' for English, 'ur' for Urdu)
  final String language;

  Intent({
    required this.type,
    required this.parameters,
    required this.originalText,
    required this.language,
  });

  factory Intent.fromJson(Map<String, dynamic> json) {
    return Intent(
      type: json['intent'] ?? 'unknown',
      parameters: json['parameters'] ?? {},
      originalText: json['text'] ?? '',
      language: json['language'] ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intent': type,
      'parameters': parameters,
      'text': originalText,
      'language': language,
    };
  }

  @override
  String toString() {
    return 'Intent{type: $type, parameters: $parameters, originalText: $originalText, language: $language}';
  }
}

/// Predefined intent types for the voice assistant
class IntentType {
  static const String addToCart = 'add_to_cart';
  static const String removeFromCart = 'remove_from_cart';
  static const String checkCart = 'check_cart';
  static const String checkout = 'checkout';
  static const String search = 'search';
  static const String unknown = 'unknown';
} 