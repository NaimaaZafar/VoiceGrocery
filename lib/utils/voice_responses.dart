class VoiceResponses {
  // Response messages for different intents and actions
  static Map<String, Map<String, String>> responses = {
    // English responses
    'en': {
      // Welcome and general responses
      'welcome': 'Welcome to Voice Grocery. How can I help you today?',
      'processing': 'Processing your request...',
      'command_understood': 'I understood your command.',
      'command_not_understood': 'Sorry, I didn\'t understand that command.',
      
      // Intent responses
      'add_to_cart_success': 'Adding items to your cart.',
      'add_to_cart_confirm': 'Items have been added to your cart.',
      'search_starting': 'Searching for your items.',
      'search_results': 'Here are the results for your search.',
      'go_to_cart': 'Going to your shopping cart.',
      'remove_from_cart': 'Removing items from your cart.',
      'remove_from_cart_confirm': 'Items have been removed from your cart.',
      'empty_cart': 'Your cart is empty.',
      'add_review': 'Let\'s add a review for this item.',
      'add_review_start': 'Please tell me your review.',
      'add_review_confirm': 'Your review has been added.',
      'favorite_starting': 'Searching for items to add to favorites.',
      'favorite_confirm': 'Item has been added to your favorites.',
      
      // Error responses
      'item_not_found': 'Sorry, I couldn\'t find that item.',
      'try_again': 'Please try again.',
      'permission_denied': 'Please grant microphone access to use voice features.',
    },
    
    // Urdu responses
    'ur': {
      // Welcome and general responses
      'welcome': 'وائس گروسری میں خوش آمدید۔ میں آپ کی کیسے مدد کر سکتا ہوں؟',
      'processing': 'آپ کی درخواست پر کارروائی کی جا رہی ہے...',
      'command_understood': 'میں نے آپ کا حکم سمجھ لیا ہے۔',
      'command_not_understood': 'معذرت، مجھے وہ حکم سمجھ نہیں آیا۔',
      
      // Intent responses
      'add_to_cart_success': 'آپ کی ٹوکری میں اشیاء شامل کی جا رہی ہیں۔',
      'add_to_cart_confirm': 'آئٹمز آپ کی ٹوکری میں شامل کر دیے گئے ہیں۔',
      'search_starting': 'آپ کی اشیاء کی تلاش کی جا رہی ہے۔',
      'search_results': 'آپ کی تلاش کے نتائج یہ ہیں۔',
      'go_to_cart': 'آپ کی شاپنگ ٹوکری میں جا رہے ہیں۔',
      'remove_from_cart': 'آپ کی ٹوکری سے اشیاء ہٹائی جا رہی ہیں۔',
      'remove_from_cart_confirm': 'آئٹمز آپ کی ٹوکری سے ہٹا دیے گئے ہیں۔',
      'empty_cart': 'آپ کی ٹوکری خالی ہے۔',
      'add_review': 'آئیے اس آئٹم کا جائزہ شامل کریں۔',
      'add_review_start': 'براہ کرم مجھے اپنی رائے بتائیں۔',
      'add_review_confirm': 'آپ کا جائزہ شامل کر دیا گیا ہے۔',
      'favorite_starting': 'پسندیدہ میں شامل کرنے کے لیے آئٹمز تلاش کی جا رہی ہیں۔',
      'favorite_confirm': 'آئٹم آپ کے پسندیدہ میں شامل کر دیا گیا ہے۔',
      
      // Error responses
      'item_not_found': 'معذرت، مجھے وہ آئٹم نہیں مل سکا۔',
      'try_again': 'براہ کرم دوبارہ کوشش کریں۔',
      'permission_denied': 'آواز کی خصوصیات کا استعمال کرنے کے لیے براہ کرم مائیکروفون تک رسائی دیں۔',
    },
    
    // Hindi/Hindustani responses (as sometimes Urdu may be detected as Hindi)
    'hi': {
      // Welcome and general responses
      'welcome': 'वॉयस ग्रोसरी में आपका स्वागत है। मैं आपकी कैसे मदद कर सकता हूँ?',
      'processing': 'आपके अनुरोध पर कार्रवाई की जा रही है...',
      'command_understood': 'मैंने आपका कमांड समझ लिया है।',
      'command_not_understood': 'क्षमा करें, मुझे वह कमांड समझ नहीं आया।',
      
      // Intent responses
      'add_to_cart_success': 'आइटम आपकी कार्ट में जोड़े जा रहे हैं।',
      'add_to_cart_confirm': 'आइटम आपकी कार्ट में जोड़ दिए गए हैं।',
      'search_starting': 'आपके आइटम खोजे जा रहे हैं।',
      'search_results': 'आपकी खोज के परिणाम यहाँ हैं।',
      'go_to_cart': 'आपकी शॉपिंग कार्ट पर जा रहे हैं।',
      'remove_from_cart': 'आपकी कार्ट से आइटम हटाए जा रहे हैं।',
      'remove_from_cart_confirm': 'आइटम आपकी कार्ट से हटा दिए गए हैं।',
      'empty_cart': 'आपकी कार्ट खाली है।',
      'add_review': 'चलिए इस आइटम के लिए समीक्षा जोड़ते हैं।',
      'add_review_start': 'कृपया मुझे अपनी समीक्षा बताएं।',
      'add_review_confirm': 'आपकी समीक्षा जोड़ दी गई है।',
      'favorite_starting': 'पसंदीदा में जोड़ने के लिए आइटम खोजे जा रहे हैं।',
      'favorite_confirm': 'आइटम आपके पसंदीदा में जोड़ दिया गया है।',
      
      // Error responses
      'item_not_found': 'क्षमा करें, मुझे वह आइटम नहीं मिला।',
      'try_again': 'कृपया फिर से प्रयास करें।',
      'permission_denied': 'आवाज़ सुविधाओं का उपयोग करने के लिए कृपया माइक्रोफ़ोन एक्सेस दें।',
    },
  };
  
  // Get response text based on language and response key
  static String getResponse(String language, String responseKey) {
    // Default to English if language not available
    if (!responses.containsKey(language)) {
      language = 'en';
    }
    
    // Get the appropriate response or return a default message
    return responses[language]![responseKey] ?? 
        responses['en']![responseKey] ?? 
        'I\'m here to help you with your grocery shopping.';
  }
} 