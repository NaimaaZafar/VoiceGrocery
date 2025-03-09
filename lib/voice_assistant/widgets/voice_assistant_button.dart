import 'dart:async';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import '../services/voice_assistant_service.dart';

class VoiceAssistantButton extends StatefulWidget {
  const VoiceAssistantButton({Key? key}) : super(key: key);

  @override
  State<VoiceAssistantButton> createState() => _VoiceAssistantButtonState();
}

class _VoiceAssistantButtonState extends State<VoiceAssistantButton> with SingleTickerProviderStateMixin {
  final VoiceAssistantService _voiceService = VoiceAssistantService();
  bool _isListening = false;
  bool _isInitialized = false;
  bool _showDialog = false;
  late AnimationController _animationController;
  String _recognizedText = '';
  StreamSubscription? _textSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeService();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Subscribe to the speech service text stream
    _textSubscription = _voiceService._speechService.textStream.listen((text) {
      setState(() {
        _recognizedText = text;
      });
    });
  }
  
  Future<void> _initializeService() async {
    final initialized = await _voiceService.initialize();
    setState(() {
      _isInitialized = initialized;
    });
  }
  
  @override
  void dispose() {
    _textSubscription?.cancel();
    _voiceService.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleListening() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice assistant is not available')),
      );
      return;
    }
    
    setState(() {
      _isListening = !_isListening;
      _showDialog = _isListening;
      
      if (_isListening) {
        _animationController.forward();
        _recognizedText = '';
      } else {
        _animationController.reverse();
      }
    });
    
    if (_isListening) {
      await _voiceService.startListening();
    } else {
      await _voiceService.stopListening();
      await _voiceService.processVoiceCommand(context);
      
      // Hide dialog after processing
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showDialog = false;
          });
        }
      });
    }
  }
  
  void _toggleLanguage() async {
    await _voiceService.toggleLanguage();
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Language changed to ${_voiceService.getCurrentLanguage()}')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dialog that appears when listening
        if (_showDialog)
          Positioned(
            bottom: 120,
            right: 20,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                width: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Voice Assistant',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleLanguage,
                          child: Chip(
                            label: Text(_voiceService.getCurrentLanguage()),
                            backgroundColor: Colors.blue.shade100,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isListening 
                        ? 'Listening...' 
                        : 'Processing...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _recognizedText.isEmpty 
                        ? 'Say something...' 
                        : _recognizedText,
                      style: TextStyle(
                        fontSize: 14,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Floating button
        Positioned(
          bottom: 40,
          right: 20,
          child: AvatarGlow(
            animate: _isListening,
            glowColor: Theme.of(context).primaryColor,
            endRadius: 45.0,
            duration: const Duration(milliseconds: 2000),
            repeatPauseDuration: const Duration(milliseconds: 100),
            repeat: true,
            child: FloatingActionButton(
              onPressed: _toggleListening,
              tooltip: 'Voice Assistant',
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
              ),
            ),
          ),
        ),
      ],
    );
  }
} 