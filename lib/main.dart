import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fyp/firebase_options.dart';
import 'package:fyp/screens/splashscreen.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:fyp/screens/cart_fav_provider.dart';
import 'package:fyp/utils/food_menu.dart';
import 'package:fyp/voice_assistant/widgets/voice_assistant_wrapper.dart';

Future<void> main() async {
  final WidgetsBinding widgetsBining =
      WidgetsFlutterBinding.ensureInitialized();
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
        home: VoiceAssistantWrapper(
          child: Splashscreen(), // Your splash screen as the initial screen
        ),
      ),
    );
  }
}
