import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fyp/firebase_options.dart';
import 'package:fyp/screens/splashscreen.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:fyp/screens/cart_fav_provider.dart';
import 'package:fyp/utils/food_menu.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fyp/screens/voice_recognition.dart';

Future<void> main() async {
  final WidgetsBinding widgetsBining =
      WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print("Environment variables loaded successfully");
    print("OPENAI_API_KEY exists: ${dotenv.env.containsKey('OPENAI_API_KEY')}");
  } catch (e) {
    // If the .env file doesn't exist or can't be loaded, we'll continue with a fallback
    print("Warning: Unable to load .env file: $e");
  }
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GetStorage.init();

  // Fetch food menu from firebase
  final restaurant = Restaurant();
  await restaurant.fetchFoodMenu();

  runApp(VoiceGrocery(restaurant: restaurant));
}

class VoiceGrocery extends StatelessWidget {
  final Restaurant restaurant;

  const VoiceGrocery({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartFavoriteProvider()),
        Provider<Restaurant>.value(value: restaurant),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Splashscreen(), // Your splash screen as the initial screen
        routes: {
          '/voice': (context) => const VoiceRecognitionScreen(),
        },
      ),
    );
  }
}
