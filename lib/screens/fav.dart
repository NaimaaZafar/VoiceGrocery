import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/screens/cart_fav_provider.dart';
import 'package:fyp/screens/category.dart';
import 'package:fyp/screens/profile.dart';
import 'package:fyp/screens/settings.dart';
import 'package:fyp/widgets/navbar.dart';
import 'package:fyp/widgets/product_cards.dart';
import 'package:provider/provider.dart';

import '../utils/food_menu.dart';
import 'package:fyp/screens/voice_recognition.dart';

class FavScreen extends StatefulWidget {
  final int initialIndex;

  const FavScreen({super.key, this.initialIndex = 0});

  @override
  _FavScreenState createState() => _FavScreenState();
}

class _FavScreenState extends State<FavScreen> {
  int _selectedIndex = 1;
  List<Food> favoriteItems = [];

  @override
  void initState() {
    super.initState();
    _fetchFavoriteItems();
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const CategoryScreen(categoryName: 'BrookiBakery')));
    } else if (index == 1) {
      // We're already on the Favorite screen
    } else if (index == 2) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AccountsPage()));
    } else if (index == 3) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    } else if (index == 4) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const VoiceRecognitionScreen()));
    }
  }

  List<Food> removeDuplicates(List<Food> list) {
    return list.toSet().toList();
  }

  Future<void> _fetchFavoriteItems() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('Fav', isEqualTo: true)
          .get();

      final List<Food> fetchedItems = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Food.fromMap(data);
      }).toList();

      setState(() {
        favoriteItems = removeDuplicates(fetchedItems);
      });
    } catch (e) {
      print('Error fetching favorite items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3B57B2),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Favorites', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const CategoryScreen(categoryName: 'MeatsFishes'),
              ),
            );
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: favoriteItems.isEmpty
          ? Center(child: Text('No favorite items yet.'))
          : ListView.builder(
              itemCount: favoriteItems.length,
              itemBuilder: (context, index) {
                return ProductCard(
                    food: favoriteItems[index]); // Pass food object
              },
            ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
    );
  }
}
