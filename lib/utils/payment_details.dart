import 'package:flutter/material.dart';
import 'package:fyp/screens/add_new_card.dart';
import 'package:fyp/screens/success.dart';
import 'package:fyp/utils/colors.dart';
import 'package:fyp/widgets/button.dart';
import 'package:fyp/utils/text_to_speech_service.dart';
import 'package:fyp/utils/voice_responses.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentDetailsScreen extends StatefulWidget {
  const PaymentDetailsScreen({super.key});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  String? _selectedPaymentMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg_dark, // Blue background
      appBar: AppBar(
        backgroundColor: bg_dark, // Consistent AppBar color
        title: const Text('Payment Details', style: TextStyle(color: Colors.white),),
        elevation: 0, // Flat AppBar
      ),
      body: Column(
        mainAxisAlignment:
        MainAxisAlignment.center, // Center content vertically
        children: [
          const Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white, // White text for contrast
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceEvenly, // Space between options
            children: [
              _buildPaymentOption(
                icon: Icons.money,
                label: 'Cash on Delivery',
                value: 'COD',
              ),
              _buildPaymentOption(
                icon: Icons.credit_card,
                label: 'Credit Card',
                value: 'Credit Card',
              ),
            ],
          ),
          const SizedBox(height: 40), // Space between options and button
            Button(
              onTap: () {
                if (_selectedPaymentMethod == 'Credit Card') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddCardScreen(),
                    ),
                  );
                } else if (_selectedPaymentMethod == 'COD') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SuccessScreen(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a payment method'),
                    ),
                  );
                }
              },
              text: "NEXT",
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 60, // Big icon size
            backgroundColor: _selectedPaymentMethod == value
                ? Colors.white
                : Colors.grey[300],
            child: Icon(
              icon,
              size: 50, // Larger icon size
              color:
              _selectedPaymentMethod == value ? Colors.blue : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: _selectedPaymentMethod == value
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: Colors.white, // White text
            ),
          ),
        ],
      ),
    );
  }
}

// Voice-driven Payment Screen
class VoicePaymentDetailsScreen extends StatefulWidget {
  final bool useVoiceInput;
  final String? sourceLanguage;
  
  const VoicePaymentDetailsScreen({
    super.key, 
    this.useVoiceInput = false,
    this.sourceLanguage,
  });

  @override
  State<VoicePaymentDetailsScreen> createState() => _VoicePaymentDetailsScreenState();
}

class _VoicePaymentDetailsScreenState extends State<VoicePaymentDetailsScreen> {
  final _audioRecorder = AudioRecorder();
  final _ttsService = TextToSpeechService();
  String _languageCode = 'en'; // Default language
  
  String? _selectedPaymentMethod;
  bool _isRecording = false;
  String _recordingPath = '';
  bool _processingVoice = false;
  
  @override
  void initState() {
    super.initState();
    
    // Set language
    _languageCode = widget.sourceLanguage ?? 'en';
    
    // Start voice checkout process if requested
    if (widget.useVoiceInput) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startVoicePayment();
      });
    }
  }
  
  // Start voice-guided payment process
  void _startVoicePayment() async {
    // Prepare for recording
    await _requestPermissions();
    
    // Delay to let the UI render completely
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Ask for payment method
    _askForPaymentMethod();
  }
  
  // Request necessary permissions
  Future<void> _requestPermissions() async {
    await _audioRecorder.hasPermission();
  }
  
  // Ask for payment method
  void _askForPaymentMethod() {
    _speak('checkout_payment');
    _recordPaymentMethod();
  }
  
  // Helper method to speak using the TTS service
  void _speak(String responseKey) {
    final message = VoiceResponses.getResponse(_languageCode, responseKey);
    _ttsService.speakWithLanguage(message, _languageCode);
  }
  
  // Record input for payment method
  void _recordPaymentMethod() async {
    try {
      // Wait for TTS to finish before starting recording
      await Future.delayed(const Duration(seconds: 2));
      
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/payment_recording.m4a';
      
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
        _askForPaymentMethod();
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
        _processPaymentMethod(transcription);
      } else {
        // If transcription failed, try again
        _askForPaymentMethod();
      }
    } catch (e) {
      setState(() {
        _processingVoice = false;
      });
      
      // Try again
      Future.delayed(const Duration(seconds: 1), () {
        _askForPaymentMethod();
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
  
  // Process payment method from transcription
  void _processPaymentMethod(String transcription) {
    final text = transcription.toLowerCase();
    
    if (text.contains('cash') || 
        text.contains('delivery') || 
        text.contains('cod') || 
        text.contains('cash on delivery')) {
      setState(() {
        _selectedPaymentMethod = 'COD';
        _processingVoice = false;
      });
      
      // Confirm and proceed
      _speak('checkout_confirm');
      Future.delayed(const Duration(seconds: 2), () {
        _proceedWithPayment();
      });
    } else if (text.contains('card') || 
               text.contains('credit') || 
               text.contains('debit') || 
               text.contains('payment card')) {
      setState(() {
        _selectedPaymentMethod = 'Credit Card';
        _processingVoice = false;
      });
      
      // Confirm and proceed
      _speak('checkout_confirm');
      Future.delayed(const Duration(seconds: 2), () {
        _proceedWithPayment();
      });
    } else {
      // Couldn't determine payment method, try again
      setState(() {
        _processingVoice = false;
      });
      
      Future.delayed(const Duration(seconds: 1), () {
        _askForPaymentMethod();
      });
    }
  }
  
  // Proceed with the selected payment method
  void _proceedWithPayment() {
    if (_selectedPaymentMethod == 'Credit Card') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AddCardScreen(),
        ),
      );
    } else if (_selectedPaymentMethod == 'COD') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SuccessScreen(),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _audioRecorder.dispose();
    _ttsService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg_dark, // Blue background
      appBar: AppBar(
        backgroundColor: bg_dark, // Consistent AppBar color
        title: const Text('Payment Details', style: TextStyle(color: Colors.white),),
        elevation: 0, // Flat AppBar
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
            children: [
              const Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text for contrast
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Space between options
                children: [
                  _buildPaymentOption(
                    icon: Icons.money,
                    label: 'Cash on Delivery',
                    value: 'COD',
                  ),
                  _buildPaymentOption(
                    icon: Icons.credit_card,
                    label: 'Credit Card',
                    value: 'Credit Card',
                  ),
                ],
              ),
              const SizedBox(height: 40), // Space between options and button
              Button(
                onTap: () {
                  if (_selectedPaymentMethod == 'Credit Card') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddCardScreen(),
                      ),
                    );
                  } else if (_selectedPaymentMethod == 'COD') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SuccessScreen(),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a payment method'),
                      ),
                    );
                  }
                },
                text: "NEXT",
              ),
            ],
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

  Widget _buildPaymentOption({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 60, // Big icon size
            backgroundColor: _selectedPaymentMethod == value
                ? Colors.white
                : Colors.grey[300],
            child: Icon(
              icon,
              size: 50, // Larger icon size
              color:
              _selectedPaymentMethod == value ? Colors.blue : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: _selectedPaymentMethod == value
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: Colors.white, // White text
            ),
          ),
        ],
      ),
    );
  }
}