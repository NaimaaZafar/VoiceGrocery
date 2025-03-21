import 'package:flutter/material.dart';
import 'package:fyp/utils/colors.dart';
import 'package:fyp/utils/payment_details.dart';
import 'package:fyp/widgets/button.dart';
import 'package:fyp/widgets/text_field.dart';
import 'package:fyp/widgets/dropdown_input.dart';
import 'package:fyp/utils/text_to_speech_service.dart';
import 'package:fyp/utils/voice_responses.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CheckoutDetails extends StatefulWidget {
  final bool useVoiceInput;
  final String? sourceLanguage;
  final List<Map<String, dynamic>> selectedItems;
  final double totalPrice;
  
  const CheckoutDetails({
    super.key, 
    required this.selectedItems,
    required this.totalPrice,
    this.useVoiceInput = false,
    this.sourceLanguage,
  });

  @override
  _CheckoutDetailsState createState() => _CheckoutDetailsState();
}

class _CheckoutDetailsState extends State<CheckoutDetails> {
  final _formKey = GlobalKey<FormState>();
  final _audioRecorder = AudioRecorder();
  final _ttsService = TextToSpeechService();
  String _languageCode = 'en'; // Default language

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  final List<String> _provinces = ['Punjab', 'Sindh', 'KPK'];
  String? _selectedProvince = 'Punjab'; // Default value
  
  bool _isRecording = false;
  String _recordingPath = '';
  int _currentField = 0; // 0: name, 1: phone, 2: city, 3: address, 4: postal code
  bool _processingVoice = false;

  @override
  void initState() {
    super.initState();
    
    // Set language
    _languageCode = widget.sourceLanguage ?? 'en';
    
    // Start voice checkout process if requested
    if (widget.useVoiceInput) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startVoiceCheckout();
      });
    }
  }

  // Start voice-guided checkout process
  void _startVoiceCheckout() async {
    // Prepare for recording
    await _requestPermissions();
    
    // Delay to let the UI render completely
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Start asking for information
    _askForNextField();
  }
  
  // Request necessary permissions
  Future<void> _requestPermissions() async {
    await _audioRecorder.hasPermission();
  }

  // Ask for the next field
  void _askForNextField() {
    switch (_currentField) {
      case 0:
        _speak('checkout_name');
        _recordFieldInput();
        break;
      case 1:
        _speak('checkout_phone');
        _recordFieldInput();
        break;
      case 2:
        _speak('checkout_city');
        _recordFieldInput();
        break;
      case 3:
        _speak('checkout_address');
        _recordFieldInput();
        break;
      case 4:
        _speak('checkout_confirm');
        // Proceed to payment
        Future.delayed(const Duration(seconds: 2), () {
          _proceedToPayment();
        });
        break;
    }
  }
  
  // Helper method to speak using the TTS service
  void _speak(String responseKey) {
    final message = VoiceResponses.getResponse(_languageCode, responseKey);
    _ttsService.speakWithLanguage(message, _languageCode);
  }
  
  // Record input for the current field
  void _recordFieldInput() async {
    try {
      // Wait for TTS to finish before starting recording
      await Future.delayed(const Duration(seconds: 2));
      
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/field_recording.m4a';
      
      // Start recording
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
        _processingVoice = true;
      });
      
      // Record for a few seconds then stop
      Future.delayed(const Duration(seconds: 5), () {
        _stopRecording();
      });
    } catch (e) {
      setState(() {
        _processingVoice = false;
      });
      
      // Try again
      Future.delayed(const Duration(seconds: 1), () {
        _askForNextField();
      });
    }
  }
  
  // Stop recording and process the audio
  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
      
      // Process the recorded audio
      final transcription = await _transcribeAudio();
      if (transcription != null && transcription.isNotEmpty) {
        _setFieldValue(transcription);
      } else {
        // If transcription failed, try again
        _askForNextField();
      }
    } catch (e) {
      setState(() {
        _processingVoice = false;
      });
      
      // Try again
      Future.delayed(const Duration(seconds: 1), () {
        _askForNextField();
      });
    }
  }
  
  // Transcribe audio using Whisper API
  Future<String?> _transcribeAudio() async {
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }
      
      // Check if file exists
      final file = File(_recordingPath);
      if (!await file.exists()) {
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
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String transcription = data['text'];
        
        return transcription;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  // Set the value for the current field and move to the next one
  void _setFieldValue(String value) {
    String cleanValue = value.trim();
    
    switch (_currentField) {
      case 0: // Name
        _fullNameController.text = cleanValue;
        break;
      case 1: // Phone
        // Extract only numbers from the transcription
        final numericValue = cleanValue.replaceAll(RegExp(r'[^0-9]'), '');
        _phoneNumberController.text = numericValue;
        break;
      case 2: // City
        _cityController.text = cleanValue;
        break;
      case 3: // Address
        _addressController.text = cleanValue;
        break;
      case 4: // We don't have a 4th field to fill via voice in this implementation
        break;
    }
    
    // Move to the next field
    setState(() {
      _currentField++;
      _processingVoice = false;
    });
    
    // Continue with the next field
    Future.delayed(const Duration(seconds: 1), () {
      _askForNextField();
    });
  }
  
  void _proceedToPayment() {
    // Set a default postal code since we're not asking for it in voice flow
    if (_postalCodeController.text.isEmpty) {
      _postalCodeController.text = '12345';
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoicePaymentDetailsScreen(
          useVoiceInput: widget.useVoiceInput,
          sourceLanguage: _languageCode,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _audioRecorder.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  String? _validateField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    } else if (!RegExp(r'^\d{10,11}$').hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validatePostalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Postal code is required';
    } else if (!RegExp(r'^\d{5}$').hasMatch(value)) {
      return 'Enter a valid 5-digit postal code';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Details', style: TextStyle(color: Colors.white)),
        backgroundColor: bg_dark,
      ),
      body: Stack(
        children: [
          Container(
            color: bg_dark,
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  TextFieldInput(
                    textEditingController: _fullNameController,
                    hintText: 'Enter your full name',
                    icon: Icons.person,
                    obscureText: false,
                    validator: (value) => _validateField(value, 'Full Name'),
                  ),
                  const SizedBox(height: 10),
                  TextFieldInput(
                    textEditingController: _phoneNumberController,
                    hintText: 'Enter your phone number',
                    icon: Icons.phone,
                    obscureText: false,
                    validator: _validatePhoneNumber,
                  ),
                  const SizedBox(height: 10),
                  DropdownInput(
                    hintText: 'Select Province',
                    items: _provinces,
                    selectedItem: _selectedProvince,
                    onChanged: (value) {
                      setState(() {
                        _selectedProvince = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFieldInput(
                    textEditingController: _cityController,
                    hintText: 'Enter your city',
                    icon: Icons.location_city,
                    obscureText: false,
                    validator: (value) => _validateField(value, 'City'),
                  ),
                  const SizedBox(height: 10),
                  TextFieldInput(
                    textEditingController: _addressController,
                    hintText: 'Enter your address',
                    icon: Icons.home,
                    obscureText: false,
                    validator: (value) => _validateField(value, 'Address'),
                  ),
                  const SizedBox(height: 10),
                  TextFieldInput(
                    textEditingController: _postalCodeController,
                    hintText: 'Enter your postal code',
                    icon: Icons.local_post_office,
                    obscureText: false,
                    validator: _validatePostalCode,
                  ),
                  const SizedBox(height: 20),
                  Button(
                    onTap: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => widget.useVoiceInput 
                              ? VoicePaymentDetailsScreen(
                                  useVoiceInput: true,
                                  sourceLanguage: widget.sourceLanguage,
                                )
                              : const PaymentDetailsScreen(),
                          ),
                        );
                      }
                    },
                    text: "Next",
                  ),
                ],
              ),
            ),
          ),
          // Show loading overlay when processing voice
          if (_processingVoice)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      _isRecording ? 'Listening...' : 'Processing...',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
