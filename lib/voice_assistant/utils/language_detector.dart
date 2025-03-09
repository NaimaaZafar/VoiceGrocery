/// A simple utility for language detection
class LanguageDetector {
  /// Detect language from text
  /// Returns 'ur' for Urdu, 'en' for English, or null if unsure
  static String? detectLanguage(String text) {
    if (text.isEmpty) return null;
    
    // Urdu Unicode ranges
    bool hasUrduCharacters = _containsUrduCharacters(text);
    
    // If text contains Urdu characters, it's probably Urdu
    if (hasUrduCharacters) {
      return 'ur';
    }
    
    // If text contains mostly Latin characters, it's probably English
    // This is a simple heuristic and might not work for all cases
    bool hasEnglishCharacters = _containsEnglishCharacters(text);
    if (hasEnglishCharacters) {
      return 'en';
    }
    
    // Default to null if unsure
    return null;
  }
  
  /// Check if text contains Urdu characters
  static bool _containsUrduCharacters(String text) {
    // Urdu Unicode ranges
    final urduRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]');
    return urduRegex.hasMatch(text);
  }
  
  /// Check if text contains English characters
  static bool _containsEnglishCharacters(String text) {
    // Basic Latin characters
    final englishRegex = RegExp(r'[a-zA-Z]');
    
    // Count English characters
    int englishCount = 0;
    for (int i = 0; i < text.length; i++) {
      if (englishRegex.hasMatch(text[i])) {
        englishCount++;
      }
    }
    
    // If more than 50% of characters are English, it's probably English
    return englishCount > text.length / 2;
  }
} 