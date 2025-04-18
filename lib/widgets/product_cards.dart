import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/screens/item_details.dart';
import 'package:provider/provider.dart';
import 'package:fyp/screens/cart_fav_provider.dart'; // Import provider
import 'package:fyp/utils/food_menu.dart'; // Make sure to import the Food model

class ProductCard extends StatefulWidget {
  final Food food;
  final bool isHighlighted;

  const ProductCard({
    super.key,
    required this.food,
    this.isHighlighted = false,
  });

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late bool isFavorites;

  @override
  void initState() {
    super.initState();
    final cartFavoriteProvider =
        Provider.of<CartFavoriteProvider>(context, listen: false);
    isFavorites = cartFavoriteProvider.favoriteItems.contains(widget.food);
  }

  Future<void> _updateFavoriteStatus(bool isFavorite) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: widget.food.name)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({'Fav': isFavorite});
      }
    } catch (e) {
      print('Error updating favorite status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartFavoriteProvider = Provider.of<CartFavoriteProvider>(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailsPage(
              title: widget.food.name,
              price: widget.food.price.toString(),
              image: widget.food.imagePath,
              description: widget.food.getDescription('en'),
            ),
          ),
        );
      },
      child: Card(
        elevation: widget.isHighlighted ? 6 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: widget.isHighlighted
            ? BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
        ),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: widget.isHighlighted
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.blue.withOpacity(0.05),
              )
            : null,
          child: Row(
            children: [
              Image.asset(widget.food.imagePath,
                  width: 80, height: 80, fit: BoxFit.cover),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.food.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '\$${widget.food.price}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      widget.food.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.food.isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: () async {
                      setState(() {
                        isFavorites = !isFavorites;
                        if (isFavorites) {
                          widget.food.isFavorite = true;
                          cartFavoriteProvider.addToFavorites(widget.food);
                          // print("Added to fav");
                        } else {
                          widget.food.isFavorite = false;
                          cartFavoriteProvider.removeFromFavorites(widget.food);
                          // print("Removed to fav");
                        }
                      });
                      await _updateFavoriteStatus(isFavorites);
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      cartFavoriteProvider.addToCart(widget.food);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('${widget.food.name} added to cart')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Add to Cart',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
