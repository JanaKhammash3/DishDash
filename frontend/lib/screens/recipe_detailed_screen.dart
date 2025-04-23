import 'package:flutter/material.dart';
import 'package:frontend/colors.dart';

class RecipeDetailedScreen extends StatelessWidget {
  const RecipeDetailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          // 🍲 Recipe Image
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/salad.jpg',
              height: 200,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 16),

          // 🧾 Title
          const Text(
            "Spicy Hot Pot",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          // 📄 Description
          const Text(
            "Description",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Totum mi di externum est.",
          ),

          const SizedBox(height: 20),

          // ⏱ Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.grey),
                  SizedBox(width: 5),
                  Text("25 min"),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.local_fire_department, color: Colors.grey),
                  SizedBox(width: 5),
                  Text("Easy"),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber),
                  SizedBox(width: 5),
                  Text("4.5"),
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
          const Text(
            "• 2 cups chopped vegetables\n"
            "• 1 tbsp olive oil\n"
            "• 1 tsp chili flakes\n"
            "• Salt and pepper to taste\n"
            "• Fresh herbs for garnish",
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
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
