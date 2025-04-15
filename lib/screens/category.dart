import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fyp/screens/search.dart';
import 'package:fyp/screens/settings.dart';
import 'package:fyp/utils/get_user_name.dart';
import 'package:fyp/widgets/app_scaffold.dart';
import 'package:fyp/widgets/my_drawer.dart';
import 'package:fyp/widgets/my_sliver_app_bar.dart';
import 'package:fyp/widgets/navbar.dart';
import 'package:fyp/screens/fav.dart';
import 'package:fyp/screens/cart_fav_provider.dart';
import 'package:fyp/screens/profile.dart';
import 'package:fyp/screens/my_cart.dart';
import 'package:fyp/screens/search_product.dart';
import 'package:fyp/utils/category_content.dart';
import 'package:fyp/utils/colors.dart';
import 'package:fyp/widgets/category_button.dart';
import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';
import 'package:fyp/screens/voice_recognition.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryName;

  const CategoryScreen({
    super.key,
    required this.categoryName,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late String selectedCategory;
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';
  int _selectedIndex = 0;

  String firstName = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    selectedCategory =
    widget.categoryName.isNotEmpty ? widget.categoryName : 'Meats & Fishes';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToCategory();
    });

    fetchUserFirstName();
  }

  Future fetchUserFirstName() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc('AUBPUQqj1eFUiTWQLz7C')
          .get();
      if (snapshot.exists) {
        setState(() {
          firstName = snapshot.data()?['first name'] ?? 'users';
        });
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
  }

  void scrollToCategory() {
    final categories = [
      'Meats & Fishes',
      'Fresh Vegetables',
      'Fresh Fruits',
      'Snacks',
      'Brooki Bakery'
    ];
    final index = categories.indexOf(selectedCategory);

    if (index != -1) {
      _scrollController.animateTo(
        index * 100.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
              const CategoryScreen(categoryName: 'MeatsFishes')));
    } else if (index == 1) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const FavScreen()));
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

  // getting size of cart
  int sizeofcart() {
    final cartFavoriteProvider =
    Provider.of<CartFavoriteProvider>(context, listen: false);
    return cartFavoriteProvider.cartItems.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hey'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.normal,
        ),
        backgroundColor: bg_dark,
        elevation: 10,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            iconSize: 25,
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SearchPage()));
            },
          ),
          Center(
            child: badges.Badge(
              badgeContent: Text(
                sizeofcart().toString(),
                style: TextStyle(color: Colors.white),
              ),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                iconSize: 25,
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const MyCart()));
                },
              ),
            ),
          ),
          SizedBox(width: 25),
        ],
      ),
      drawer: MyDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: bg_dark,
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shop By Category',
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Container(
            color: Colors.white,
            child: SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  CategoryButton(
                    label: 'MeatsFishes',
                    isSelected: selectedCategory == 'MeatsFishes',
                    onTap: () => setState(() {
                      selectedCategory = 'MeatsFishes';
                    }),
                  ),
                  CategoryButton(
                    label: 'FreshVegetables',
                    isSelected: selectedCategory == 'FreshVegetables',
                    onTap: () => setState(() {
                      selectedCategory = 'FreshVegetables';
                    }),
                  ),
                  CategoryButton(
                    label: 'FreshFruits',
                    isSelected: selectedCategory == 'FreshFruits',
                    onTap: () => setState(() {
                      selectedCategory = 'FreshFruits';
                    }),
                  ),
                  CategoryButton(
                    label: 'Snacks',
                    isSelected: selectedCategory == 'Snacks',
                    onTap: () => setState(() {
                      selectedCategory = 'Snacks';
                    }),
                  ),
                  CategoryButton(
                    label: 'BrookiBakery',
                    isSelected: selectedCategory == 'BrookiBakery',
                    onTap: () => setState(() {
                      selectedCategory = 'BrookiBakery';
                    }),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: CategoryContent(category: selectedCategory),
          ),
        ],
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
    );
  }
}
