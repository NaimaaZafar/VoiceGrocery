import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/utils/colors.dart';
import 'package:fyp/utils/text_to_speech_service.dart';
import 'package:fyp/utils/voice_responses.dart';
import 'package:fyp/screens/voice_recognition.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SendFeedbackPage extends StatefulWidget {
  final bool isVoiceFeedbackIntent;
  final String sourceLanguage;

  const SendFeedbackPage({
    super.key, 
    this.isVoiceFeedbackIntent = false,
    this.sourceLanguage = 'en'
  });

  @override
  _SendFeedbackPageState createState() => _SendFeedbackPageState();
}

class _SendFeedbackPageState extends State<SendFeedbackPage> {
  int? selectedEmojiIndex;
  final TextEditingController feedbackController = TextEditingController();

  // Firestore instance
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  // Voice feedback components
  final TextToSpeechService _ttsService = TextToSpeechService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isVoiceFeedbackActive = false;
  bool _isRecording = false;
  String _recordingPath = '';
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    
    // Check if we should automatically start voice feedback
    if (widget.isVoiceFeedbackIntent) {
      // Add slight delay to let the UI render first
      Future.delayed(const Duration(milliseconds: 500), () {
        _startVoiceFeedback();
      });
    }
  }
  
  void _speak(String responseKey) {
    final message = VoiceResponses.getResponse(widget.sourceLanguage, responseKey);
    _ttsService.speakWithLanguage(message, widget.sourceLanguage);
  }

  void _startVoiceFeedback() {
    setState(() {
      _isVoiceFeedbackActive = true;
    });
    
    // Speak the prompt to start feedback
    _speak('add_review_start');
    
    // Start recording after 1.5 seconds to allow TTS to finish
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _startRecording();
      }
    });
  }
  
  // Start recording audio
  Future<void> _startRecording() async {
    try {
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/feedback_recording.m4a';
      
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
      
      // Start a counter for display
      int secondsLeft = 10;
      setState(() {
        _isRecording = true;
      });
      
      // Auto-stop recording after 10 seconds with countdown
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        secondsLeft--;
        if (secondsLeft <= 0) {
          _stopRecording();
        } else {
          // Update UI to show countdown
          if (mounted) {
            setState(() {});
          }
        }
      });
    } catch (e) {
      setState(() {
        _isVoiceFeedbackActive = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording: $e')),
      );
    }
  }
  
  // Stop recording and process the audio
  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    try {
      // Cancel timer if it's still active
      _recordingTimer?.cancel();
      
      // Stop recording
      await _audioRecorder.stop();
      
      setState(() {
        _isRecording = false;
      });
      
      // Transcribe the audio
      final transcription = await _transcribeAudio();
      if (transcription != null && transcription.isNotEmpty) {
        // Set feedback text
        feedbackController.text = transcription;
        
        // Auto-select middle emoji rating
        setState(() {
          selectedEmojiIndex = 1; // Default to "Was Ok" rating
        });
        
        // Submit the feedback
        submitFeedback();
      }
      
      // Reset voice feedback mode
      setState(() {
        _isVoiceFeedbackActive = false;
      });
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isVoiceFeedbackActive = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping recording: $e')),
      );
    }
  }
  
  // Transcribe audio using Whisper API
  Future<String?> _transcribeAudio() async {
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OpenAI API key not found.')),
        );
        return null;
      }
      
      // Check if file exists
      final file = File(_recordingPath);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio file not found')),
        );
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
      
      // Use the Whisper model
      request.fields['model'] = 'whisper-1';
      request.fields['response_format'] = 'verbose_json'; // Get detailed response with language info
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String transcription = data['text'];
        
        return transcription;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error transcribing audio: ${response.statusCode}')),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error transcribing audio: $e')),
      );
      return null;
    }
  }

  // Function to submit feedback
  void submitFeedback() async {
    String feedbackText = feedbackController.text.trim();

    if (feedbackText.isEmpty || selectedEmojiIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter feedback and select an emoji!')),
      );
      return;
    }

    try {
      await firestore.collection('feedback').add({
        'feedback': feedbackText,
        'rating': selectedEmojiIndex, // 0 = Horrible, 1 = Was Ok, 2 = Brilliant
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Clear inputs after submission
      feedbackController.clear();
      setState(() {
        selectedEmojiIndex = null;
      });

      if (_isVoiceFeedbackActive) {
        // Speak confirmation for voice feedback
        _speak('feedback_confirm');
        
        // Wait a moment for TTS to complete before navigating back
        Future.delayed(const Duration(seconds: 2), () {
          // Navigate back to voice assistant screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const VoiceRecognitionScreen()),
          );
        });
      } else {
        // Show snackbar for manual feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted successfully!')),
        );
        
        // Wait a moment for user to read the snackbar before navigating back
        Future.delayed(const Duration(seconds: 1), () {
          // Navigate back to voice assistant screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const VoiceRecognitionScreen()),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    feedbackController.dispose();
    _ttsService.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
        backgroundColor: bg_dark,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'asset/image.png',
                  height: 250,
                  width: 250,
                ),
                const SizedBox(height: 20),
                const Text(
                  "We'd love to hear your thoughts",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Your feedback is important to us! Please share your experience.",
                  style: TextStyle(fontSize: 13, color: Colors.black, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Emoji Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    emojiButton(0, Icons.sentiment_very_dissatisfied, 'Horrible'),
                    const SizedBox(width: 20),
                    emojiButton(1, Icons.sentiment_neutral, 'Was Ok'),
                    const SizedBox(width: 20),
                    emojiButton(2, Icons.sentiment_very_satisfied, 'Brilliant'),
                  ],
                ),
                const SizedBox(height: 20),

                // Feedback Text Field
                TextField(
                  controller: feedbackController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Type your feedback here...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Feedback Button
                ElevatedButton(
                  onPressed: submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bg_dark,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Share your feedback',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          
          // Voice feedback overlay
          if (_isVoiceFeedbackActive)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isRecording ? Icons.mic : Icons.hourglass_top,
                        color: _isRecording ? Colors.red : Colors.blue,
                        size: 48
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isRecording 
                          ? "Recording your feedback..." 
                          : "Processing your feedback...",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      if (_isRecording)
                        Text(
                          "Recording will automatically stop in ${_recordingTimer != null ? (10 - (_recordingTimer!.tick)) : 10} seconds",
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 20),
                      Text(
                        feedbackController.text.isEmpty 
                          ? _isRecording ? "Listening..." : "Transcribing..."
                          : feedbackController.text,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }

  // Emoji Button Widget
  Widget emojiButton(int index, IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedEmojiIndex = index;
        });
      },
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: selectedEmojiIndex == index ? bg_dark : Colors.transparent,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon, size: 60, color: Colors.amber),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: selectedEmojiIndex == index ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}