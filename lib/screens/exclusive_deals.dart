import 'package:flutter/material.dart';
import 'package:fyp/screens/category.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  // Function to navigate to CategoryScreen with the selected category
  void _navigateToCategoryScreen(String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryScreen(categoryName: categoryName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Exclusive Deals",
          style: TextStyle(
            color: Colors.black,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false, // Aligns the title to the left
        actions: [
          GestureDetector(
            onTap: () {
              // Navigate to CategoryScreen when "Skip" is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CategoryScreen(categoryName: 'FreshFruits')),
              );
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Center(
                child: Text(
                  "Skip",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // _buildDealCard(
            //   title: "Monthly Bundles",
            //   discount: "25%",
            //   imagePath: "asset/bundle.png",
            //   backgroundColor: const Color(0xFFDFFFE3),
            //   categoryName: "Monthly Bundles",
            // ),
            const SizedBox(height: 20),
            _buildDealCard(
              title: "Fresh Fruits",
              discount: "20%",
              imagePath: "asset/fruits.png",
              backgroundColor: const Color(0xFFE3F6FF),
              categoryName: "FreshFruits",
            ),
            const SizedBox(height: 20),
            _buildDealCard(
              title: "Fresh Vegetables",
              discount: "10%",
              imagePath: "asset/vegitables.png",
              backgroundColor: const Color(0xFFF7E5FF),
              categoryName: "FreshVegetables",
            ),
            const SizedBox(height: 20),
            _buildDealCard(
              title: "Brooki Bakery",
              discount: "5%",
              imagePath: "asset/bakery.png",
              backgroundColor: const Color(0xFFFFD7D7),
              categoryName: "BrookiBakery",
            ),
            const SizedBox(height: 20),
            _buildDealCard(
              title: "Meats & Fishes",
              discount: "2.5%",
              imagePath: "asset/fishnmeat.png",
              backgroundColor: const Color(0xFFFFE0C2),
              categoryName: "MeatsFishes",
            ),
            const SizedBox(height: 20),
            _buildDealCard(
              title: "Snacks",
              discount: "2.5%",
              imagePath: "asset/snacks.png",
              backgroundColor: const Color(0xFFE5E5E5),
              categoryName: "Snacks",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDealCard({
    required String title,
    required String discount,
    required String imagePath,
    required Color backgroundColor,
    required String categoryName,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to CategoryScreen with the correct category name
        _navigateToCategoryScreen(categoryName);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Image.asset(
              imagePath,
              width: 100,
              height: 100,
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Upto $discount Discount",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}