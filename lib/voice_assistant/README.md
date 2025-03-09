# Voice Assistant for Flutter Grocery App

This module implements a bilingual voice assistant (English and Urdu) for the grocery app that can understand user intents and execute corresponding actions.

## Features

- Floating voice assistant button that can be added to any screen
- Speech recognition in both English and Urdu
- Automatic language detection
- Intent recognition using an AI model or rule-based fallback
- Text-to-speech responses in both languages
- Handles intents like adding/removing items from cart, checking cart, etc.

## Setup

1. Make sure you have all the required dependencies in your `pubspec.yaml`:
   ```yaml
   dependencies:
     speech_to_text: ^6.6.0
     flutter_tts: ^3.8.5
     avatar_glow: ^3.0.0
     http: ^1.2.0
     permission_handler: ^11.3.0
     rxdart: ^0.27.7
   ```

2. For AI-based intent recognition, set your OpenAI API key in `lib/voice_assistant/utils/voice_assistant_config.dart`:
   ```dart
   static String openAIApiKey = 'your-api-key-here';
   ```

3. Ensure you have the necessary permissions in your app manifests:

   **Android (android/app/src/main/AndroidManifest.xml):**
   ```xml
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.INTERNET"/>
   <queries>
       <intent>
           <action android:name="android.intent.action.TTS_SERVICE" />
       </intent>
   </queries>
   ```

   **iOS (ios/Runner/Info.plist):**
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>This app needs microphone access for voice commands</string>
   <key>NSSpeechRecognitionUsageDescription</key>
   <string>This app uses speech recognition to convert your speech to text</string>
   ```

## Usage

To add the voice assistant to any screen, wrap your widget with `VoiceAssistantWrapper`:

```dart
VoiceAssistantWrapper(
  child: YourWidget(),
)
```

The voice assistant provides a floating button that users can press to start voice interaction. 

## How It Works

1. The user taps the floating voice assistant button
2. The voice assistant listens for the user's speech
3. The speech is converted to text
4. The text is analyzed to determine the user's intent
5. The app executes the corresponding action based on the intent
6. The voice assistant provides a voice response

## Supported Intents

- **add_to_cart**: Add an item to the cart
  - Example: "Add bananas to my cart" / "میرے کارٹ میں کیلے شامل کریں"
  
- **remove_from_cart**: Remove an item from the cart
  - Example: "Remove milk from my cart" / "میرے کارٹ سے دودھ نکال دیں"
  
- **check_cart**: View the current contents of the cart
  - Example: "Check my cart" / "میرا کارٹ دیکھیں"
  
- **checkout**: Proceed to checkout
  - Example: "Checkout" / "چیک آؤٹ"
  
- **search**: Search for products
  - Example: "Search for apples" / "سیب تلاش کریں"

## Customization

You can customize the voice assistant by modifying the following files:

- `voice_assistant_config.dart`: Configuration options
- `intent_recognition_service.dart`: Add more intents or improve recognition
- `voice_assistant_service.dart`: Add more actions for recognized intents
- `voice_assistant_button.dart`: Customize the UI of the button and dialog 