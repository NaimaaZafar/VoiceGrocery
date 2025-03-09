/// Configuration for the voice assistant
class VoiceAssistantConfig {
  /// OpenAI API key for intent recognition
  /// This should be provided by the user through a settings screen
  static String openAIApiKey = '';
  
  /// Whether to use fallback intent recognition when API is not available
  static bool useFallbackRecognition = true;
  
  /// Supported languages
  static const List<String> supportedLanguages = ['en_US', 'ur_PK'];
  
  /// Default language
  static const String defaultLanguage = 'en_US';
  
  /// User-friendly language names
  static const Map<String, String> languageNames = {
    'en_US': 'English',
    'ur_PK': 'Urdu',
  };
} 