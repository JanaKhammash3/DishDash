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
  final String instructions;

  const RecipeDetailedScreen({
    super.key,
    required this.title,
    required this.imagePath,
    required this.description,
    required this.ingredients,
    required this.prepTime,
    required this.difficulty,
    required this.rating,
    required this.instructions,
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
        backgroundColor: green,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image(image: imageProvider, height: 200, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          const Text(
            "Description",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            description.isNotEmpty ? description : 'No description provided.',
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule),
                  SizedBox(width: 5),
                  Text(prepTime),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.local_fire_department),
                  SizedBox(width: 5),
                  Text(difficulty),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  SizedBox(width: 5),
                  Text(rating.toStringAsFixed(1)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 30),
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
          const Text(
            "Method",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            instructions.isNotEmpty
                ? instructions
                : "No instructions provided.",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
