import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fyp/screens/my_cart.dart';
import 'package:fyp/utils/colors.dart';
import 'package:fyp/widgets/button.dart';
import 'package:fyp/widgets/related_product_card.dart';
import 'package:fyp/widgets/text_field.dart';
import 'package:fyp/screens/cart_fav_provider.dart';
import 'package:fyp/utils/food_menu.dart';
import 'package:fyp/utils/text_to_speech_service.dart';
import 'package:fyp/utils/voice_responses.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ItemDetailsPage extends StatefulWidget {
  final String title;
  final String price;
  final String image;
  final String description;
  final VoidCallback? autoBuyCallback;
  final bool isReviewIntent;
  final String sourceLanguage;

  const ItemDetailsPage({
    super.key,
    required this.title,
    required this.price,
    required this.image,
    required this.description,
    this.autoBuyCallback,
    this.isReviewIntent = false,
    this.sourceLanguage = 'en',
  });

  @override
  State<ItemDetailsPage> createState() => ItemDetailsPageState();
}

class ItemDetailsPageState extends State<ItemDetailsPage> {
  final TextEditingController reviewController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextToSpeechService _ttsService = TextToSpeechService();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isVoiceReviewActive = false;
  bool _isRecording = false;
  String _recordingPath = '';
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    
    // Check if we should activate voice review mode
    if (widget.isReviewIntent) {
      // Add slight delay to let the UI render first
      Future.delayed(const Duration(milliseconds: 500), () {
        _startVoiceReview();
      });
    }
  }

  void _speak(String responseKey) {
    final message = VoiceResponses.getResponse(widget.sourceLanguage, responseKey);
    _ttsService.speakWithLanguage(message, widget.sourceLanguage);
  }

  void _startVoiceReview() {
    setState(() {
      _isVoiceReviewActive = true;
    });
    
    // Speak the prompt to start the review
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
      _recordingPath = '${tempDir.path}/review_recording.m4a';
      
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
        _isVoiceReviewActive = false;
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
        // Set review text
        reviewController.text = transcription;
        
        // Submit the review
        submitReview();
      }
      
      // Reset voice review mode
      setState(() {
        _isVoiceReviewActive = false;
      });
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isVoiceReviewActive = false;
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
      print("Debug - API Key loaded: ${apiKey != null ? 'Yes (not empty)' : 'No'}");
      print("Debug - API Key is empty: ${apiKey?.isEmpty ?? true}");
      
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
        String detectedLanguage = widget.sourceLanguage;
        
        // Extract detected language if available
        if (data.containsKey('language')) {
          detectedLanguage = data['language'];
          print("Whisper detected language: $detectedLanguage");
          
          // Update the sourceLanguage if different from what we expected
          // This ensures TTS responds in the same language the user spoke
          if (detectedLanguage != widget.sourceLanguage) {
            print("Updating language from ${widget.sourceLanguage} to $detectedLanguage");
            
            // Use Hindi for Urdu as they're similar
            if (detectedLanguage == 'ur') {
              detectedLanguage = 'hi';
            }
            
            // Set TTS language for response
            await _ttsService.setLanguage(detectedLanguage);
          }
        }
        
        // Store the detected language with the transcription
        return transcription + "|||" + detectedLanguage; // Use a marker to separate text and language
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

  void submitReview() async {
    String reviewText = reviewController.text.trim();
    if (reviewText.isNotEmpty) {
      try {
        // Check if the text contains our language marker
        String detectedLanguage = widget.sourceLanguage;
        
        if (reviewText.contains("|||")) {
          final parts = reviewText.split("|||");
          reviewText = parts[0].trim();
          if (parts.length > 1) {
            detectedLanguage = parts[1].trim();
          }
        }
        
        // Create the review data
        Map<String, dynamic> reviewData = {
          'productName': widget.title,
          'review': reviewText,
          'language': detectedLanguage,
          'timestamp': FieldValue.serverTimestamp(),
        };
        
        // Print debug info before saving
        print("Submitting review - Data: $reviewData");
        
        // Add the review document to Firestore
        DocumentReference docRef = await firestore.collection('reviews').add(reviewData);
        
        print("Review submitted successfully with ID: ${docRef.id}");

        // Clear the input field
        reviewController.clear();
        
        if (_isVoiceReviewActive) {
          // Speak confirmation for voice review in the detected language
          _speak('add_review_confirm');
        } else {
          // Show snackbar for manual review
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Refresh the reviews list by triggering a setState
        setState(() {});
      } catch (e) {
        // Show error message if submission fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Notify user if review text is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a review before submitting'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  
  // Method to handle the Buy Now action
  void buyNow() {
    final cartFavoriteProvider = Provider.of<CartFavoriteProvider>(context, listen: false);
    Food food = Food(
      name: widget.title,
      price: int.parse(widget.price),
      imagePath: widget.image,
      category: FoodCategory.MeatsFishes,
      quantity: 1,
      descriptions: {},
    );
    cartFavoriteProvider.addToCart(food);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${food.name} added to cart')),
    );
    
    // Direct navigation to cart
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const MyCart())
    );
  }

  @override
  void dispose() {
    reviewController.dispose();
    _ttsService.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: bg_dark,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCart()));
            },
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(widget.image, width: double.infinity, height: 200, fit: BoxFit.cover),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text("Rs ${widget.price}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Button(
                  onTap: widget.autoBuyCallback ?? buyNow, // Use autoBuyCallback if provided, or buyNow as fallback
                  text: 'Buy Now',
                ),
                const SizedBox(height: 20),
                const Text("Product Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(widget.description, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),

                // Reviews Section
                ExpansionTile(
                  initiallyExpanded: widget.isReviewIntent,
                  key: GlobalKey(), // Add a key to force rebuild
                  title: const Text("Reviews"),
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: firestore.collection('reviews')
                          .where('productName', isEqualTo: widget.title)
                          // Removing orderBy clause temporarily until index is created
                          //.orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        // Print debug information
                        print("Reviews debug - Product name: ${widget.title}");
                        print("Reviews debug - Has data: ${snapshot.hasData}");
                        if (snapshot.hasData) {
                          print("Reviews debug - Number of reviews: ${snapshot.data!.docs.length}");
                          for (var doc in snapshot.data!.docs) {
                            var data = doc.data() as Map<String, dynamic>;
                            print("Reviews debug - Review data: $data");
                          }
                        }
                        
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text("Error loading reviews: ${snapshot.error}", 
                                style: const TextStyle(fontSize: 16)),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text("No reviews yet", style: TextStyle(fontSize: 16)),
                          );
                        }
                        
                        var reviews = snapshot.data!.docs;
                        if (reviews.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text("No reviews yet", style: TextStyle(fontSize: 16)),
                          );
                        }
                        
                        return Column(
                          children: reviews.map((doc) {
                            var reviewData = doc.data() as Map<String, dynamic>;
                            return ListTile(
                              title: Text(reviewData['review'] ?? ""),
                              subtitle: Text(
                                reviewData['timestamp'] != null
                                    ? reviewData['timestamp'].toDate().toString().substring(0, 16)
                                    : 'Just now',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Review Input
                TextFieldInput(
                  textEditingController: reviewController,
                  hintText: "Enter a review",
                  icon: Icons.reviews,
                  obscureText: false,
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: submitReview,
                    child: const Text("Submit Review"),
                  ),
                ),
                const SizedBox(height: 20),

                // Related Products
                const Text("More Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      RelatedProduct(name: "Apple", price: "Rs 300.00", imagePath: "asset/apple.png"),
                      RelatedProduct(name: "Orange", price: "Rs 350.00", imagePath: "asset/orange.png"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Voice review overlay
          if (_isVoiceReviewActive)
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
                          ? "Recording your review..." 
                          : "Processing your review...",
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
                        reviewController.text.isEmpty 
                          ? _isRecording ? "Listening..." : "Transcribing..."
                          : reviewController.text,
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
    );
  }
}
