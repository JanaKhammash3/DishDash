import 'package:flutter/material.dart';
import 'package:frontend/colors.dart';

class RecipeDetailedScreen extends StatelessWidget {
  final String title;
  final String imagePath;
  final String description;
  final List<String> ingredients;
  final String prepTime;
  final String difficulty;
  final double rating;

  const RecipeDetailedScreen({
    super.key,
    required this.title,
    required this.imagePath,
    required this.description,
    required this.ingredients,
    required this.prepTime,
    required this.difficulty,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork = imagePath.startsWith('http');
    final imageProvider =
        isNetwork
            ? NetworkImage(imagePath)
            : const AssetImage('assets/placeholder.png') as ImageProvider;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: maroon,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Method & Details",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 🍲 Image
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image(image: imageProvider, height: 200, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),

          // 🧾 Title
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // 📄 Description
          const Text(
            "Description",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            description.isNotEmpty ? description : 'No description provided.',
          ),

          const SizedBox(height: 20),

          // ⏱ Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(prepTime),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(difficulty),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 5),
                  Text(rating.toStringAsFixed(1)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 30),

          // 🥦 Ingredients
          const Text(
            "Ingredients",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            ingredients.isNotEmpty
                ? ingredients.map((e) => "• $e").join("\n")
                : "N/A",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 30),

          // 🧑‍🍳 Method
          const Text(
            "Method",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            "1. Boil water in a large pot.\n"
            "2. Add vegetables and spices to the boiling water.\n"
            "3. Let it simmer on low heat for about 20 minutes.\n"
            "4. Stir occasionally and adjust seasoning to taste.\n"
            "5. Serve hot with rice or your preferred side dish.",
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }
}
