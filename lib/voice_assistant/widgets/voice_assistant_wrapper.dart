import 'package:flutter/material.dart';
import 'voice_assistant_button.dart';

/// A wrapper widget that adds a voice assistant button to any screen
class VoiceAssistantWrapper extends StatelessWidget {
  /// The child widget that will be wrapped
  final Widget child;
  
  /// Whether to show the voice assistant button
  final bool showVoiceAssistant;
  
  const VoiceAssistantWrapper({
    Key? key,
    required this.child,
    this.showVoiceAssistant = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The main content
        child,
        
        // The voice assistant button
        if (showVoiceAssistant) const VoiceAssistantButton(),
      ],
    );
  }
} 