import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils/language_detector.dart';
import '../utils/voice_assistant_config.dart';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isInitialized = false;
  bool _isListening = false;
  
  String _recognizedText = '';
  String _selectedLanguage = VoiceAssistantConfig.defaultLanguage; // Default language is English
  
  StreamController<String> _textStreamController = StreamController<String>.broadcast();
  Stream<String> get textStream => _textStreamController.stream;
  
  final List<stt.LocaleName> _localeNames = [];
  
  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;
  
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return false;
    }
    
    bool speechAvailable = await _speech.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );
    
    if (speechAvailable) {
      _localeNames = await _speech.locales();
      
      // Initialize TTS
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      _isInitialized = true;
    }
    
    return _isInitialized;
  }
  
  Future<void> startListening({String? language}) async {
    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) return;
    }
    
    if (_isListening) return;
    
    if (language != null) {
      _selectedLanguage = language;
    }
    
    // Check if the selected language is available
    if (!_localeNames.any((locale) => locale.localeId.contains(_selectedLanguage.split('_')[0]))) {
      print('Selected language not available, using default language');
      // Try to find Urdu or use English as fallback
      _selectedLanguage = _localeNames.any((locale) => locale.localeId.contains('ur')) 
          ? 'ur_PK' 
          : 'en_US';
    }
    
    _recognizedText = '';
    _isListening = true;
    
    await _speech.listen(
      onResult: (result) {
        _recognizedText = result.recognizedWords;
        _textStreamController.add(_recognizedText);
        
        // Auto-detect language if needed
        if (_recognizedText.isNotEmpty) {
          final detectedLanguage = LanguageDetector.detectLanguage(_recognizedText);
          if (detectedLanguage == 'ur' && !_selectedLanguage.startsWith('ur')) {
            _selectedLanguage = 'ur_PK';
            _speech.stop();
            _speech.listen(
              onResult: (result) {
                _recognizedText = result.recognizedWords;
                _textStreamController.add(_recognizedText);
              },
              localeId: _selectedLanguage,
              listenMode: stt.ListenMode.confirmation,
            );
          } else if (detectedLanguage == 'en' && !_selectedLanguage.startsWith('en')) {
            _selectedLanguage = 'en_US';
            _speech.stop();
            _speech.listen(
              onResult: (result) {
                _recognizedText = result.recognizedWords;
                _textStreamController.add(_recognizedText);
              },
              localeId: _selectedLanguage,
              listenMode: stt.ListenMode.confirmation,
            );
          }
        }
      },
      localeId: _selectedLanguage,
      listenMode: stt.ListenMode.confirmation,
    );
  }
  
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    await _speech.stop();
    _isListening = false;
  }
  
  Future<void> speak(String text, {String language = 'en-US'}) async {
    if (text.isEmpty) return;
    
    // Convert language code format if necessary
    String ttsLanguage = language.replaceAll('_', '-');
    
    // Set language for TTS
    await _flutterTts.setLanguage(ttsLanguage);
    
    // Speak the text
    await _flutterTts.speak(text);
  }
  
  void dispose() {
    _speech.cancel();
    _flutterTts.stop();
    _textStreamController.close();
  }
  
  /// Toggle between English and Urdu
  Future<String> toggleLanguage() async {
    if (_selectedLanguage.startsWith('en')) {
      _selectedLanguage = 'ur_PK';
    } else {
      _selectedLanguage = 'en_US';
    }
    
    return _selectedLanguage;
  }
  
  /// Get current language name in human-readable format
  String getCurrentLanguageName() {
    return VoiceAssistantConfig.languageNames[_selectedLanguage] ?? 'English';
  }
} 