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
      
      // Assistant specific responses
      'assistant_ready': 'I\'m here to help. What would you like me to do?',
      'general_response': 'I\'m your voice assistant. You can ask me to search for products, check your cart, or navigate to different sections of the app.',
      'going_to_settings': 'Taking you to the settings page.',
      'going_to_profile': 'Opening your profile page.',
      
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
      'checkout_starting': 'Starting the checkout process.',
      'checkout_success': 'Taking you to checkout.',
      'checkout_name': 'Please say your full name.',
      'checkout_phone': 'Please say your phone number.',
      'checkout_address': 'Please say your delivery address.',
      'checkout_city': 'Please say your city.',
      'checkout_payment': 'Please tell me your payment method: card payment or cash on delivery.',
      'checkout_confirm': 'Thank you! Your order has been placed successfully.',
      'feedback_starting': 'Taking you to the feedback page.',
      'feedback_confirm': 'Thank you for your feedback!',
      
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
      
      // Assistant specific responses
      'assistant_ready': 'میں آپ کی مدد کے لیے حاضر ہوں۔ آپ مجھ سے کیا کروانا چاہتے ہیں؟',
      'general_response': 'میں آپ کا وائس اسسٹنٹ ہوں۔ آپ مجھ سے پروڈکٹس کی تلاش، اپنی کارٹ چیک کرنے، یا ایپ کے مختلف حصوں میں جانے کے لیے کہہ سکتے ہیں۔',
      'going_to_settings': 'آپ کو سیٹنگز پیج پر لے جایا جا رہا ہے۔',
      'going_to_profile': 'آپ کا پروفائل پیج کھولا جا رہا ہے۔',
      
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
      'checkout_starting': 'چیک آؤٹ کا عمل شروع کیا جا رہا ہے۔',
      'checkout_success': 'آپ کو چیک آؤٹ پر لے جایا جا رہا ہے۔',
      'checkout_name': 'براہ کرم اپنا پورا نام بتائیں۔',
      'checkout_phone': 'براہ کرم اپنا فون نمبر بتائیں۔',
      'checkout_address': 'براہ کرم اپنا ڈیلیوری ایڈریس بتائیں۔',
      'checkout_city': 'براہ کرم اپنا شہر بتائیں۔',
      'checkout_payment': 'براہ کرم اپنی ادائیگی کا طریقہ بتائیں: کارڈ پیمنٹ یا کیش آن ڈیلیوری۔',
      'checkout_confirm': 'شکریہ! آپ کا آرڈر کامیابی سے درج کر لیا گیا ہے۔',
      'feedback_starting': 'آپ کو فیدبک پیج پر لے جانے کی جا رہی ہے۔',
      'feedback_confirm': 'آپ کی فیدبک لطف سے شکریہ!',
      
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
      
      // Assistant specific responses
      'assistant_ready': 'मैं आपकी मदद के लिए मौजूद हूँ। आप मुझसे क्या करवाना चाहते हैं?',
      'general_response': 'मैं आपका वॉइस असिस्टेंट हूँ। आप मुझसे प्रोडक्ट्स खोजने, अपनी कार्ट चेक करने, या ऐप के विभिन्न भागों में जाने के लिए कह सकते हैं।',
      'going_to_settings': 'आपको सेटिंग्स पेज पर ले जा रहा हूँ।',
      'going_to_profile': 'आपका प्रोफाइल पेज खोला जा रहा है।',
      
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
      'checkout_starting': 'चेकआउट प्रक्रिया शुरू की जा रही है।',
      'checkout_success': 'आपको चेकआउट पर ले जाया जा रहा है।',
      'checkout_name': 'कृपया अपना पूरा नाम बताएं।',
      'checkout_phone': 'कृपया अपना फोन नंबर बताएं।',
      'checkout_address': 'कृपया अपना डिलीवरी पता बताएं।',
      'checkout_city': 'कृपया अपना शहर बताएं।',
      'checkout_payment': 'कृपया अपना भुगतान विधि बताएं: कार्ड भुगतान या डिलीवरी पर नकद।',
      'checkout_confirm': 'धन्यवाद! आपका ऑर्डर सफलतापूर्वक दर्ज कर लिया गया है।',
      'feedback_starting': 'आपको फीडबैक पेज पर ले जाने की जा रही है।',
      'feedback_confirm': 'आपकी फीडबैक के लिए धन्यवाद!',
      
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