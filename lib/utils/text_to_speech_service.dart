import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io' show Platform;

enum TtsState { playing, stopped }

class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  final FlutterTts _flutterTts = FlutterTts();
  String _currentLanguage = 'en-US'; // Default language
  bool _isSpeaking = false;
  List<dynamic> _availableLanguages = [];

  // Factory constructor
  factory TextToSpeechService() {
    return _instance;
  }

  // Private constructor
  TextToSpeechService._internal() {
    _initTts();
  }

  // Initialize TTS settings
  Future<void> _initTts() async {
    try {
      // Basic configuration - keep this simple
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.45);
      
      // iOS-specific settings
      if (Platform.isIOS) {
        try {
          await _flutterTts.setSharedInstance(true);
          await _flutterTts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.ambient,
            [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker],
            IosTextToSpeechAudioMode.defaultMode,
          );
        } catch (e) {
          print("iOS audio category setup error (non-critical): $e");
          // Continue even if this fails
        }
      }
      
      // Setup listeners
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      
      _flutterTts.setErrorHandler((error) {
        _isSpeaking = false;
        print("TTS Error: $error");
      });
      
      // Get available languages
      try {
        _availableLanguages = await _flutterTts.getLanguages;
        print("Available languages: $_availableLanguages");
        
        // Debug language capabilities
        _debugLanguageSupport();
      } catch (e) {
        print("Error getting languages: $e");
        _availableLanguages = [];
      }
    } catch (e) {
      print("Error initializing TTS: $e");
    }
  }
  
  // Debug language support 
  void _debugLanguageSupport() {
    try {
      // Check for Hindi support
      final hindiVariants = _findHindiLanguageCodes();
      if (hindiVariants.isNotEmpty) {
        print("HINDI SUPPORT: AVAILABLE");
        print("Hindi variants: $hindiVariants");
      } else {
        print("HINDI SUPPORT: NOT AVAILABLE");
      }
      
      // Print all Indian languages
      final indianLanguages = _availableLanguages.where((lang) {
        final langStr = lang.toString().toLowerCase();
        return langStr.contains('hi') || 
               langStr.contains('ind') || 
               langStr.contains('ta-') || 
               langStr.contains('te-') || 
               langStr.contains('ml-') || 
               langStr.contains('pa-');
      }).toList();
      
      if (indianLanguages.isNotEmpty) {
        print("Indian languages available: $indianLanguages");
      }
    } catch (e) {
      print("Error debugging language support: $e");
    }
  }
  
  // Find Hindi language codes from available languages
  List<dynamic> _findHindiLanguageCodes() {
    if (_availableLanguages.isEmpty) return [];
    
    return _availableLanguages.where((lang) {
      final langStr = lang.toString().toLowerCase();
      return langStr == 'hi-in' || 
             langStr == 'hi' || 
             langStr.contains('hind') || 
             langStr.contains('hi-');
    }).toList();
  }

  // Get available languages
  Future<List<String>> getAvailableLanguages() async {
    if (_availableLanguages.isEmpty) {
      try {
        _availableLanguages = await _flutterTts.getLanguages;
      } catch (e) {
        print("Error refreshing languages: $e");
      }
    }
    return _availableLanguages.map((lang) => lang.toString()).toList();
  }

  // Find best match for a language code
  String _findBestLanguageMatch(String languageCode) {
    if (_availableLanguages.isEmpty) return 'en-US';
    
    // Convert to lowercase for case-insensitive comparison
    final normalizedLangCode = languageCode.toLowerCase().trim();
    
    // Special case for Hindi
    if (normalizedLangCode == 'hi' || 
        normalizedLangCode == 'hin' || 
        normalizedLangCode == 'hindi') {
      
      final hindiMatches = _findHindiLanguageCodes();
      
      if (hindiMatches.isNotEmpty) {
        final bestHindiMatch = hindiMatches.first.toString();
        print("Found Hindi match: $bestHindiMatch");
        return bestHindiMatch;
      }
    }
    
    // Special case for Urdu (use Hindi as fallback)
    if (normalizedLangCode == 'ur' || normalizedLangCode == 'urdu') {
      final hindiMatches = _findHindiLanguageCodes();
      
      if (hindiMatches.isNotEmpty) {
        final bestHindiMatch = hindiMatches.first.toString();
        print("Using Hindi ($bestHindiMatch) for Urdu");
        return bestHindiMatch;
      }
    }
    
    // Look for exact matches first
    for (final lang in _availableLanguages) {
      final langStr = lang.toString().toLowerCase();
      if (langStr == normalizedLangCode ||
          langStr.startsWith("$normalizedLangCode-")) {
        return lang.toString();
      }
    }
    
    // Look for partial matches
    final matches = _availableLanguages.where((lang) {
      final langStr = lang.toString().toLowerCase();
      return langStr.contains(normalizedLangCode);
    }).toList();
    
    if (matches.isNotEmpty) {
      return matches.first.toString();
    }
    
    // Default to English
    return 'en-US';
  }

  // Set language based on detected language code
  Future<void> setLanguage(String languageCode) async {
    try {
      // Find the best language match
      final bestMatch = _findBestLanguageMatch(languageCode);
      _currentLanguage = bestMatch;
      
      print("Setting language to: $bestMatch");
      await _flutterTts.setLanguage(bestMatch);
      
      // Set speech rate based on language
      double speechRate = 0.45; // Default rate
      
      // Use slower rate for Indian languages
      final lowerLangCode = languageCode.toLowerCase();
      if (lowerLangCode.startsWith('hi') || 
          lowerLangCode.startsWith('ur') ||
          lowerLangCode == 'hindi' ||
          lowerLangCode == 'urdu') {
        speechRate = 0.35; 
      }
      
      await _flutterTts.setSpeechRate(speechRate);
    } catch (e) {
      print("Error setting language: $e");
      // Fallback to English
      _currentLanguage = 'en-US';
      await _flutterTts.setLanguage('en-US');
    }
  }

  // Speak text in current language
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    // Don't interrupt ongoing speech unless really necessary
    if (_isSpeaking) {
      await stop();
    }
    
    try {
      _isSpeaking = true;
      await _flutterTts.speak(text);
    } catch (e) {
      print("Error speaking: $e");
      _isSpeaking = false;
    }
  }
  
  // Speak text with specific language
  Future<void> speakWithLanguage(String text, String languageCode) async {
    if (text.isEmpty) return;
    
    // Always stop previous speech
    if (_isSpeaking) {
      await stop();
    }
    
    try {
      // Log for debugging
      print("Speaking in language: $languageCode, Text: $text");
      
      // Handle special case for Hindi and Urdu
      final lowerLangCode = languageCode.toLowerCase();
      if (lowerLangCode == 'hi' || 
          lowerLangCode == 'hindi' ||
          lowerLangCode == 'ur' ||
          lowerLangCode == 'urdu') {
          
        print("Attempting to speak in Hindi/Urdu");
        
        // Find Hindi code that works on this device
        final hindiMatches = _findHindiLanguageCodes();
        print("Hindi matches: $hindiMatches");
        
        if (hindiMatches.isNotEmpty) {
          final hindiCode = hindiMatches.first.toString();
          
          try {
            // Simple approach - directly set language and speak
            await _flutterTts.setSpeechRate(0.35); // Slower for Hindi
            await _flutterTts.setLanguage(hindiCode);
            
            _isSpeaking = true;
            await _flutterTts.speak(text);
            return;
          } catch (e) {
            print("Error with direct Hindi approach: $e");
            // Continue to fallback
          }
          
          // If direct approach failed, try alternative method
          try {
            // Reset TTS config
            await _flutterTts.stop();
            
            // For iOS, try different audio category
            if (Platform.isIOS) {
              try {
                await _flutterTts.setIosAudioCategory(
                  IosTextToSpeechAudioCategory.playback,
                  [
                    IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
                    IosTextToSpeechAudioCategoryOptions.mixWithOthers,
                  ],
                  IosTextToSpeechAudioMode.defaultMode,
                );
              } catch (e) {
                print("iOS category change error: $e");
              }
            }
            
            await _flutterTts.setSpeechRate(0.35);
            await _flutterTts.setLanguage(hindiCode);
            
            _isSpeaking = true;
            await _flutterTts.speak(text);
            return;
          } catch (e) {
            print("Error with alternative Hindi approach: $e");
            // Continue to fallback
          }
        }
      }
      
      // For other languages or if Hindi failed
      // Set language through best match
      final mappedLanguageCode = _findBestLanguageMatch(languageCode);
      
      double speechRate = 0.45; // Default rate
      if (lowerLangCode.startsWith('hi') || 
          lowerLangCode.startsWith('ur')) {
        speechRate = 0.35;
      }
      
      await _flutterTts.setSpeechRate(speechRate);
      await _flutterTts.setLanguage(mappedLanguageCode);
      
      _isSpeaking = true;
      await _flutterTts.speak(text);
    } catch (e) {
      print("Error in speakWithLanguage: $e");
      
      // Last resort fallback - try English
      try {
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setSpeechRate(0.45);
        await _flutterTts.speak(text);
      } catch (e2) {
        print("Error in fallback speech: $e2");
        _isSpeaking = false;
      }
    }
  }

  // Stop speaking
  Future<void> stop() async {
    if (!_isSpeaking) return;
    
    _isSpeaking = false;
    await _flutterTts.stop();
  }
  
  // Check if currently speaking
  bool get isSpeaking => _isSpeaking;
  
  // Get current language
  String get currentLanguage => _currentLanguage;
  
  // Dispose resources
  Future<void> dispose() async {
    await _flutterTts.stop();
  }
} 