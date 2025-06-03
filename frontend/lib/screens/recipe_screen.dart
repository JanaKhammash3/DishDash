import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:frontend/colors.dart';
import 'package:frontend/screens/recipe_detailed_screen.dart';

class RecipeScreen extends StatefulWidget {
  final String title;
  final String imagePath;
  final double rating;
  final List<String> ingredients;
  final String description;
  final int prepTime;
  final String difficulty;
  final String instructions;

  const RecipeScreen({
    super.key,
    required this.title,
    required this.imagePath,
    required this.rating,
    required this.ingredients,
    required this.description,
    required this.prepTime,
    required this.difficulty,
    required this.instructions,
  });

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  bool isSaved = false;
  late double rating;

  @override
  void initState() {
    super.initState();
    rating = widget.rating;
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider _getImageProvider(String? image) {
      if (image != null && image.startsWith('http')) {
        return NetworkImage(image);
      } else if (image != null &&
          (image.startsWith('/9j') || image.startsWith('iVBOR'))) {
        try {
          return MemoryImage(base64Decode(image));
        } catch (e) {
          debugPrint('❌ Base64 decode failed: $e');
          return const AssetImage('assets/placeholder.png');
        }
      } else if (image != null && image.isNotEmpty) {
        return NetworkImage('http://192.168.68.61:3000/images/$image');
      } else {
        return const AssetImage('assets/placeholder.png');
      }
    }

    final String? image = widget.imagePath;
    final ImageProvider imageProvider = _getImageProvider(image);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Recipe Detail",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => isSaved = !isSaved);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => RecipeDetailedScreen(
                        title: widget.title,
                        imagePath: widget.imagePath,
                        description: widget.description,
                        ingredients: widget.ingredients,
                        prepTime: '${widget.prepTime} min',
                        difficulty: widget.difficulty,
                        rating: rating,
                        instructions: widget.instructions,
                      ),
                ),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
              shadowColor: Colors.black26,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(radius: 70, backgroundImage: imageProvider),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RatingBar.builder(
                      initialRating: rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 28,
                      unratedColor: Colors.grey[300],
                      itemBuilder:
                          (context, _) =>
                              const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (newRating) {
                        setState(() => rating = newRating);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.description.isNotEmpty
                          ? widget.description
                          : 'No description provided.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.circle, size: 6, color: Colors.grey),
                        SizedBox(width: 4),
                        Icon(Icons.circle, size: 6, color: Colors.grey),
                        SizedBox(width: 4),
                        Icon(Icons.circle, size: 6, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Ingredients",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.ingredients.map(_ingredientTextBox).toList(),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _ingredientTextBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }
}
