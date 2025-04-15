import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fyp/firebase_options.dart';
import 'package:fyp/screens/splashscreen.dart';
import 'package:fyp/widgets/app_scaffold_wrapper.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:fyp/screens/cart_fav_provider.dart';
import 'package:fyp/utils/food_menu.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fyp/screens/voice_recognition.dart';
import 'package:fyp/screens/my_cart.dart';
import 'package:fyp/screens/search.dart';
import 'package:fyp/screens/settings.dart';
import 'package:fyp/screens/profile.dart';
import 'dart:io';

Future<void> main() async {
  final WidgetsBinding widgetsBining =
      WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print("Environment variables loaded successfully");
    print("OPENAI_API_KEY exists: ${dotenv.env.containsKey('OPENAI_API_KEY')}");
    if (!dotenv.env.containsKey('OPENAI_API_KEY')) {
      print("Warning: OPENAI_API_KEY is not set in .env file");
    }
  } catch (e) {
    // If the .env file doesn't exist or can't be loaded, we'll continue with a fallback
    print("Warning: Unable to load .env file: $e");
    print("Current working directory: ${Directory.current.path}");
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
        home: Splashscreen(),
        // Use the AppScaffoldWrapper to add the floating AI assistant to all screens
        builder: (context, child) {
          return AppScaffoldWrapper(child: child!);
        },
        routes: {
          '/voice': (context) => const VoiceRecognitionScreen(),
          '/cart': (context) => const MyCart(),
          '/search': (context) => const SearchPage(),
          '/settings': (context) => const SettingsScreen(),
          '/profile': (context) => const AccountsPage(),
        },
      ),
    );
  }
}
