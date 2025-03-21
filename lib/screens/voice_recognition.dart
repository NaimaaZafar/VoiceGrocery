import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fyp/screens/fav.dart';
import 'package:fyp/screens/profile.dart';
import 'package:fyp/screens/search_product.dart';
import 'package:fyp/screens/settings.dart';
import 'package:fyp/utils/colors.dart';
import 'package:fyp/utils/text_to_speech_service.dart';
import 'package:fyp/utils/voice_responses.dart';
import 'package:fyp/widgets/navbar.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fyp/screens/my_cart.dart';
import 'package:fyp/screens/category.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:fyp/screens/search.dart';
import 'package:fyp/screens/cart_fav_provider.dart';

class VoiceRecognitionScreen extends StatefulWidget {
  const VoiceRecognitionScreen({super.key});

  @override
  State<VoiceRecognitionScreen> createState() => _VoiceRecognitionScreenState();
}

class _VoiceRecognitionScreenState extends State<VoiceRecognitionScreen> {
  final _audioRecorder = AudioRecorder();
  final _ttsService = TextToSpeechService();
  bool _isRecording = false;
  String _recordingPath = '';
  String _text = 'Press the microphone button to start speaking';
  String _intentText = '';
  String _detectedIntent = '';
  List<String> _detectedItems = [];
  bool _isProcessing = false;
  bool _isTranscribing = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _selectedIndex = 4; // For navbar selection
  String _detectedLanguage = '';
  String _languageCode = 'en'; // Default language code
  
  @override
  void initState() {
    super.initState();
    _requestPermissions();
    
    // Speak welcome message after a short delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      _speak('welcome');
    });
  }

  // Request necessary permissions
  // Future<void> _requestPermissions() async {
  //   // Only check for iOS simulator, otherwise just request permission without blocking
  //   if (Platform.isIOS) {
  //     bool isIosSimulator = !await _audioRecorder.hasPermission();
  //
  //     if (isIosSimulator) {
  //       setState(() {
  //         _hasError = true;
  //         _errorMessage = 'Microphone access is not available in iOS simulator. Please use a physical device for full functionality.';
  //       });
  //       return;
  //     }
  //   }
  //
  //   // Just request permissions without blocking on the result
  //   // The actual recording attempt will determine if we have permission
  //   await Permission.microphone.request();
  //   await Permission.storage.request();
  //
  //   // Clear any previous error messages
  //   setState(() {
  //     _hasError = false;
  //     _errorMessage = '';
  //   });
  // }
  Future<void> _requestPermissions() async {
    // Request permissions for both iOS and Android
    PermissionStatus microphoneStatus = await Permission.microphone.request();
    PermissionStatus storageStatus = await Permission.storage.request();

    // Check if permissions are granted
    bool hasMicrophonePermission = microphoneStatus.isGranted;
    bool hasStoragePermission = storageStatus.isGranted;

    if (!hasMicrophonePermission || !hasStoragePermission) {
      setState(() {
        _hasError = true;
        _errorMessage = '';
      });

      // Automatically request permissions again if not granted
      if (!hasMicrophonePermission) {
        await Permission.microphone.request();
      }
      if (!hasStoragePermission) {
        await Permission.storage.request();
      }
    } else {
      // Clear any previous error messages
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
    }
  }

  // Helper method to speak using the TTS service with current language
  void _speak(String responseKey) {
    final message = VoiceResponses.getResponse(_languageCode, responseKey);
    _ttsService.speakWithLanguage(message, _languageCode);
  }

  // Start recording audio
  Future<void> _startRecording() async {
    // Clear any previous error state
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    
    try {
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/audio_recording.m4a';
      
      // Start recording - if this fails, we'll catch the exception
      final audioConfig = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );
      
      await _audioRecorder.start(
        audioConfig,
        path: _recordingPath,
      );
      
      setState(() {
        _isRecording = true;
        _text = 'Recording...';
        _intentText = '';
        _detectedIntent = '';
        _detectedItems = [];
      });
      
      // Stop any ongoing speech
      await _ttsService.stop();
    } catch (e) {
      setState(() {
        _hasError = true;
        // Provide a more user-friendly error message
        _errorMessage = 'Could not access microphone. If you\'ve already granted permission in settings, please restart the app.';
      });
      
      // Try requesting permission again as a last resort
      await Permission.microphone.request();
      
      // Speak error message
      _speak('permission_denied');
    }
  }

  // Stop recording and process the audio
  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
        _text = 'Processing your voice...';
      });
      
      // Speak processing message
      _speak('processing');
      
      // First transcribe the audio, then process the intent
      final transcription = await _transcribeAudio();
      if (transcription != null && transcription.isNotEmpty) {
        await _processIntentWithGPT4o(transcription);
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _hasError = true;
        _errorMessage = 'Error stopping recording: $e';
      });
      
      // Speak error message
      _speak('try_again');
    }
  }

  // Step 1: Transcribe audio using Whisper API
  Future<String?> _transcribeAudio() async {
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _isTranscribing = false;
          _hasError = true;
          _errorMessage = 'OpenAI API key not found. Please add it to the .env file and restart the app.';
        });
        return null;
      }
      
      // Check if file exists
      final file = File(_recordingPath);
      if (!await file.exists()) {
        setState(() {
          _isTranscribing = false;
          _hasError = true;
          _errorMessage = 'Audio file not found';
        });
        return null;
      }
      
      // Prepare the request for transcription
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
      );
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $apiKey',
      });
      
      // Add file and fields
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _recordingPath,
      ));
      
      // Use the more capable model for better multilingual support
      request.fields['model'] = 'whisper-1';
      request.fields['response_format'] = 'verbose_json'; // Get detailed response with language info
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String transcription = data['text'];
        
        // Extract language if available
        if (data.containsKey('language')) {
          final detectedLang = data['language'].toString().toLowerCase();
          
          // Normalize language codes
          if (detectedLang == 'ur' || detectedLang == 'urdu' || 
              detectedLang.contains('urdu')) {
            // If Urdu is detected, use 'ur' code
            _languageCode = 'ur';
          } else if (detectedLang == 'hi' || detectedLang == 'hindi' || 
                    detectedLang.contains('hindi') || 
                    detectedLang.contains('hind')) {
            // If Hindi is detected, use 'hi' code
            _languageCode = 'hi';
            
            // Print debug info for Hindi detection
            print("Hindi detected! Using code: hi");
          } else if (detectedLang == 'pa' || detectedLang == 'punjabi' || 
                    detectedLang.contains('punjabi') || 
                    detectedLang.contains('panjabi')) {
            _languageCode = 'pa';
          } else if (detectedLang.startsWith('en') || 
                    detectedLang == 'english' || 
                    detectedLang.contains('english')) {
            _languageCode = 'en';
          } else {
            // Default fallback
            _languageCode = detectedLang;
          }
          
          // Map language code to full name for display
          final Map<String, String> languageNames = {
            'en': 'English',
            'ur': 'Urdu',
            'hi': 'Hindi',
            'pa': 'Punjabi',
          };
          
          _detectedLanguage = languageNames[_languageCode] ?? _languageCode;
          
          // Print debug information
          print("Detected language code: $_languageCode");
          print("Detected language name: $_detectedLanguage");
          
          // Use direct speak with language rather than setLanguage for reliability
          // await _ttsService.setLanguage(_languageCode);
          
          // Try speaking a test message to ensure TTS is working with this language
          if (_languageCode == 'hi' || _languageCode == 'ur') {
            // This forces the TTS engine to configure Hindi correctly
            await _ttsService.speakWithLanguage("परीक्षण", _languageCode);
            await Future.delayed(Duration(milliseconds: 500));
            await _ttsService.stop();
          }
          
          // Verify that language is properly set with debug message
          print("Language set for TTS: ${_ttsService.currentLanguage}");
        }
        
        setState(() {
          _text = transcription;
        });
        
        return transcription;
      } else {
        setState(() {
          _isTranscribing = false;
          _hasError = true;
          _errorMessage = 'Error transcribing audio: ${response.statusCode} - ${response.body}';
        });
        
        // Speak error message
        _speak('try_again');
        
        return null;
      }
    } catch (e) {
      setState(() {
        _isTranscribing = false;
        _hasError = true;
        _errorMessage = 'Error transcribing audio: $e';
      });
      
      // Speak error message
      _speak('try_again');
      
      return null;
    }
  }

  // Step 2: Process the transcription with GPT-4o for intent detection
  Future<void> _processIntentWithGPT4o(String transcription) async {
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      print("Debug - API Key loaded: ${apiKey != null ? 'Yes (not empty)' : 'No'}");
      print("Debug - API Key is empty: ${apiKey?.isEmpty ?? true}");
      
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _isTranscribing = false;
          _hasError = true;
          _errorMessage = 'OpenAI API key not found. Please add it to the .env file and restart the app.';
        });
        return;
      }
      
      // Prepare the request to chat completions API
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a helpful assistant that identifies user intents for a grocery shopping app.
The user may speak in English or Urdu but your response should be in English. Regardless of the language, identify if the user wants to:
1) add item(s) to cart
2) search for item(s)
3) go to cart
4) remove item(s) from cart
5) add a review for an item
6) favorite an item
7) checkout items in cart

Return ONLY a valid JSON object with:
- "intent" field (one of: "add_to_cart", "search", "go_to_cart", "remove_from_cart", "add_review", "favorite", "checkout" or "unknown")
- "items" array containing any item names mentioned, ALWAYS TRANSLATED TO ENGLISH regardless of the language spoken

Examples:
English: "I want to buy apples and bananas" → {"intent": "add_to_cart", "items": ["apple", "banana"]}
Urdu: "میں سیب اور کیلے خریدنا چاہتا ہوں" → {"intent": "add_to_cart", "items": ["apple", "banana"]}
English: "Show me tomatoes" → {"intent": "search", "items": ["tomato"]}
Urdu: "مجھے ٹماٹر دکھائیں" → {"intent": "search", "items": ["tomato"]}
English: "Go to my cart" → {"intent": "go_to_cart", "items": []}
Urdu: "میرے کارٹ پر جائیں" → {"intent": "go_to_cart", "items": []}
English: "Remove tomatoes from my cart" → {"intent": "remove_from_cart", "items": ["tomato"]}
Urdu: "میرے کارٹ سے ٹماٹر نکالیں" → {"intent": "remove_from_cart", "items": ["tomato"]}
English: "I want to add a review for apples" → {"intent": "add_review", "items": ["apple"]}
Urdu: "میں سیب کے لیے ایک جائزہ شامل کرنا چاہتا ہوں" → {"intent": "add_review", "items": ["apple"]}
English: "I want to favorite apples" → {"intent": "favorite", "items": ["apple"]}
English: "Add chicken to my favorites" → {"intent": "favorite", "items": ["chicken"]}
Urdu: "میں سیب کو پسندیدہ کرنا چاہتا ہوں" → {"intent": "favorite", "items": ["apple"]}
Urdu: "مرغی کو میرے پسندیدہ میں شامل کریں" → {"intent": "favorite", "items": ["chicken"]}
English: "I want to checkout my cart" → {"intent": "checkout", "items": []}
English: "Proceed to checkout" → {"intent": "checkout", "items": []}
Urdu: "میں چیک آؤٹ کرنا چاہتا ہوں" → {"intent": "checkout", "items": []}
Urdu: "ادائیگی کے لیے آگے بڑھیں" → {"intent": "checkout", "items": []}

Common grocery items in Urdu and their English translations:
- سیب = apple
- کیلے = banana
- ٹماٹر = tomato
- پیاز = onion
- آلو = potato
- گوشت = meat
- مرغی = chicken
- مچھلی = fish
- دودھ = milk
- پنیر = cheese
- روٹی = bread
- چاول = rice
- دال = lentils

IMPORTANT: Your response must be a valid JSON object and nothing else. No explanations, no markdown formatting, just the JSON.'''
            },
            {
              'role': 'user',
              'content': transcription
            }
          ],
          'temperature': 0.1, // Lower temperature for more consistent JSON formatting
        }),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        String content = data['choices'][0]['message']['content'];
        
        // Clean up the content to ensure it's valid JSON
        content = _sanitizeJsonString(content);
        
        // Parse the JSON response
        try {
          final Map<String, dynamic> intentData = json.decode(content);
          
          setState(() {
            _isTranscribing = false;
            _intentText = content;
            
            if (intentData.containsKey('intent')) {
              _detectedIntent = intentData['intent'];
              if (intentData.containsKey('items') && intentData['items'] is List) {
                _detectedItems = List<String>.from(intentData['items']);
              }
              
              // Handle navigation based on intent
              _handleIntent();
            }
          });
        } catch (e) {
          // JSON parsing failed, try to extract intent and items using fallback method
          _extractIntentWithFallback(content, transcription);
        }
      } else {
        setState(() {
          _isTranscribing = false;
          _hasError = true;
          _errorMessage = 'Error processing intent: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _isTranscribing = false;
        _hasError = true;
        _errorMessage = 'Error processing intent: $e';
      });
    }
  }
  
  // Sanitize the string to ensure it's valid JSON
  String _sanitizeJsonString(String jsonString) {
    // Remove any markdown code block markers
    jsonString = jsonString.replaceAll('```json', '').replaceAll('```', '');
    
    // Trim whitespace
    jsonString = jsonString.trim();
    
    // If the string doesn't start with {, try to find the first {
    if (!jsonString.startsWith('{')) {
      final startIndex = jsonString.indexOf('{');
      if (startIndex >= 0) {
        jsonString = jsonString.substring(startIndex);
      }
    }
    
    // If the string doesn't end with }, try to find the last }
    if (!jsonString.endsWith('}')) {
      final endIndex = jsonString.lastIndexOf('}');
      if (endIndex >= 0) {
        jsonString = jsonString.substring(0, endIndex + 1);
      }
    }
    
    return jsonString;
  }
  
  // Fallback method to extract intent and items when JSON parsing fails
  void _extractIntentWithFallback(String content, String originalTranscription) {
    // Set default values
    String intent = 'unknown';
    List<String> items = [];
    
    try {
      // Check for intent keywords in the content or original transcription
      String textToCheck = content.toLowerCase() + ' ' + originalTranscription.toLowerCase();
      
      if (textToCheck.contains('add') || 
          textToCheck.contains('buy') || 
          textToCheck.contains('purchase') ||
          textToCheck.contains('cart') && textToCheck.contains('add')) {
        intent = 'add_to_cart';
      } else if (textToCheck.contains('search') || 
                textToCheck.contains('find') || 
                textToCheck.contains('show') ||
                textToCheck.contains('look')) {
        intent = 'search';
      } else if (textToCheck.contains('cart') || 
                textToCheck.contains('checkout') || 
                textToCheck.contains('basket')) {
        intent = 'go_to_cart';
      } else if (textToCheck.contains('remove') || 
                textToCheck.contains('delete') ||
                (textToCheck.contains('cart') && textToCheck.contains('take out'))) {
        intent = 'remove_from_cart';
      } else if (textToCheck.contains('review') || 
                textToCheck.contains('add review') ||
                textToCheck.contains('write review')) {
        intent = 'add_review';
      } else if (textToCheck.contains('favorite') || 
                textToCheck.contains('like') ||
                textToCheck.contains('heart') ||
                textToCheck.contains('save') && textToCheck.contains('item')) {
        intent = 'favorite';
      } else if (textToCheck.contains('checkout') || 
                textToCheck.contains('proceed') || 
                textToCheck.contains('pay') ||
                textToCheck.contains('purchase') || 
                textToCheck.contains('buy now')) {
        intent = 'checkout';
      }
      
      // Try to extract items using regex
      RegExp itemsRegex = RegExp(r'"items":\s*\[(.*?)\]');
      final match = itemsRegex.firstMatch(content);
      if (match != null && match.groupCount >= 1) {
        final itemsString = match.group(1) ?? '';
        items = itemsString
            .split(',')
            .map((item) => item.trim().replaceAll('"', '').replaceAll("'", ""))
            .where((item) => item.isNotEmpty)
            .toList();
      }
      
      setState(() {
        _isTranscribing = false;
        _intentText = 'Fallback processing: Intent=$intent, Items=$items';
        _detectedIntent = intent;
        _detectedItems = items;
        
        // Handle navigation based on intent
        _handleIntent();
      });
    } catch (e) {
      setState(() {
        _isTranscribing = false;
        _hasError = true;
        _errorMessage = 'Error in fallback processing: $e\nOriginal error was with parsing JSON response.';
      });
    }
  }

  // Handle the intent with appropriate navigation
  void _handleIntent() {
    setState(() {
      _isProcessing = false;
    });

    if (_detectedIntent.isEmpty || _detectedIntent == 'unknown') {
      return;
    }

    // Speak the appropriate response
    switch (_detectedIntent) {
      case 'search':
        _speak('search_starting');
        break;
      case 'add_to_cart':
        _speak('add_to_cart_success');
        break;
      case 'go_to_cart':
        _speak('go_to_cart');
        break;
      case 'remove_from_cart':
        _speak('remove_from_cart');
        break;
      case 'add_review':
        _speak('add_review');
        break;
      case 'favorite':
        _speak('favorite_starting');
        break;
      case 'checkout':
        _speak('checkout_starting');
        break;
    }

    // Wait for TTS to complete before navigating
    Future.delayed(const Duration(seconds: 2), () {
      switch (_detectedIntent) {
        case 'search':
        case 'add_to_cart':
          if (_detectedItems.isNotEmpty) {
            // Navigate to search page with intent data
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SearchPage(
                  searchQuery: _detectedItems.first,
                  intent: _detectedIntent,
                  detectedItems: _detectedItems,
                  sourceLanguage: _languageCode,
                ),
              ),
            );
          }
          break;
        case 'go_to_cart':
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => MyCart(
              sourceLanguage: _languageCode,
            ))
          );
          break;
        case 'remove_from_cart':
          if (_detectedItems.isNotEmpty) {
            // Navigate to cart page with intent to remove items
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MyCart(
                  itemsToRemove: _detectedItems,
                  sourceLanguage: _languageCode,
                ),
              ),
            );
          }
          break;
        case 'add_review':
          if (_detectedItems.isNotEmpty) {
            // Navigate to search page with intent data for review
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SearchPage(
                  searchQuery: _detectedItems.first,
                  intent: _detectedIntent,
                  detectedItems: _detectedItems,
                  sourceLanguage: _languageCode,
                ),
              ),
            );
          }
          break;
        case 'favorite':
          if (_detectedItems.isNotEmpty) {
            // Navigate to search page with intent data for favoriting
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SearchPage(
                  searchQuery: _detectedItems.first,
                  intent: _detectedIntent,
                  detectedItems: _detectedItems,
                  sourceLanguage: _languageCode,
                ),
              ),
            );
          }
          break;
        case 'checkout':
          // Navigate to cart page with checkout intent
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => MyCart(
              isCheckoutIntent: true,
              sourceLanguage: _languageCode,
            ))
          );
          break;
        default:
          // Stay on the same page
          break;
      }
    });
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CategoryScreen(categoryName: 'MeatsFishes')
        )
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const FavScreen())
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const AccountsPage())
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const SettingsScreen())
      );
    } else if (index == 4) {
      // We're already on the Voice Recognition screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.normal,
        ),
        backgroundColor: bg_dark,
        elevation: 10,
      ),
      body: Column(
        children: [
          // Detected language display
          if (_detectedLanguage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Detected Language:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _detectedLanguage,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          
          // Transcribed text
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isTranscribing
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Transcribing your audio...',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Voice Input:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _text.isEmpty ? 'Press the microphone button to start speaking' : _text,
                            style: TextStyle(
                              fontSize: 16,
                              color: _text.isEmpty ? Colors.grey : Colors.black,
                            ),
                          ),
                          if (_hasError) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
          
          // Detected intent
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detected Intent:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_detectedIntent.isNotEmpty) ...[
                            _buildIntentDisplay(),
                          ] else ...[
                            const Text(
                              'Speak to detect your intent',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        tooltip: _isRecording ? 'Stop recording' : 'Start recording',
        backgroundColor: _isRecording ? Colors.red : bg_dark,
        child: Icon(_isRecording ? Icons.stop : Icons.mic),
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
    );
  }
  
  Widget _buildIntentDisplay() {
    IconData intentIcon;
    String intentLabel;
    Color intentColor;
    
    switch (_detectedIntent) {
      case 'add_to_cart':
        intentIcon = Icons.add_shopping_cart;
        intentLabel = 'Add to Cart';
        intentColor = Colors.green;
        break;
      case 'search':
        intentIcon = Icons.search;
        intentLabel = 'Search';
        intentColor = Colors.blue;
        break;
      case 'go_to_cart':
        intentIcon = Icons.shopping_cart;
        intentLabel = 'Go to Cart';
        intentColor = Colors.orange;
        break;
      case 'remove_from_cart':
        intentIcon = Icons.delete;
        intentLabel = 'Remove from Cart';
        intentColor = Colors.red;
        break;
      case 'add_review':
        intentIcon = Icons.star;
        intentLabel = 'Add Review';
        intentColor = Colors.yellow;
        break;
      case 'favorite':
        intentIcon = Icons.favorite;
        intentLabel = 'Add to Favorites';
        intentColor = Colors.pink;
        break;
      case 'checkout':
        intentIcon = Icons.payment;
        intentLabel = 'Checkout';
        intentColor = Colors.purple;
        break;
      default:
        intentIcon = Icons.question_mark;
        intentLabel = 'Unknown Intent';
        intentColor = Colors.grey;
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(intentIcon, color: intentColor, size: 24),
            const SizedBox(width: 8),
            Text(
              intentLabel,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: intentColor,
              ),
            ),
          ],
        ),
        if (_detectedItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Items:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _detectedItems
                .map(
                  (item) => Chip(
                    label: Text(item),
                    backgroundColor: Colors.grey.shade100,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
  
  @override
  void dispose() {
    _audioRecorder.dispose();
    _ttsService.dispose();
    super.dispose();
  }
} 