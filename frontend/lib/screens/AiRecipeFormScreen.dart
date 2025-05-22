import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/screens/my_recipes_screen.dart';

class AiRecipeFormScreen extends StatefulWidget {
  final String userId;
  const AiRecipeFormScreen({super.key, required this.userId});

  @override
  State<AiRecipeFormScreen> createState() => _AiRecipeFormScreenState();
}

class _AiRecipeFormScreenState extends State<AiRecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String mealTime = 'Breakfast';
  String cuisine = '';
  String diet = '';
  List<String> preferredIngredients = [];
  List<String> avoidIngredients = [];
  List<String> allergies = [];
  int prepTime = 30;
  int calories = 500;

  final TextEditingController _prefCtrl = TextEditingController();
  final TextEditingController _avoidCtrl = TextEditingController();
  final TextEditingController _allergyCtrl = TextEditingController();

  bool isLoading = false;
  Map<String, dynamic>? generatedRecipe;
  Future<void> _saveRecipeToMyRecipes() async {
    if (generatedRecipe == null) return;

    final response = await http.post(
      Uri.parse(
        'http://192.168.68.60:3000/api/users/${widget.userId}/custom-recipes',
      ),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "title": generatedRecipe!['title'],
        "description": generatedRecipe!['description'],
        "ingredients": generatedRecipe!['ingredients'],
        "instructions": generatedRecipe!['instructions'],
        "calories": generatedRecipe!['calories'],
        "mealTime": mealTime,
        "diet": diet,
        "cuisine": cuisine,
        "isPublic": true, // or false if private
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recipe saved to My Recipes")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to save recipe")));
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyRecipesScreen(userId: widget.userId),
      ),
    );
  }

  Future<void> _generateRecipe() async {
    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse('http://192.168.68.60:3000/api/ai/generate-recipe'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "mealTime": mealTime,
        "preferredIngredients": preferredIngredients,
        "avoidIngredients": avoidIngredients,
        "cuisine": cuisine,
        "diet": diet,
        "allergies": allergies,
        "prepTime": prepTime,
        "calories": calories,
      }),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      setState(() {
        generatedRecipe = json.decode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to generate recipe")),
      );
    }
  }

  Widget _buildChipsInput(
    String label,
    TextEditingController controller,
    List<String> targetList,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Row(
          children: [
            Expanded(child: TextField(controller: controller)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    targetList.add(controller.text.trim());
                    controller.clear();
                  });
                }
              },
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children:
              targetList
                  .map(
                    (item) => Chip(
                      label: Text(item),
                      onDeleted: () {
                        setState(() => targetList.remove(item));
                      },
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Recipe Generator")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: mealTime,
                items:
                    ['Breakfast', 'Lunch', 'Dinner', 'Snack']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) => setState(() => mealTime = v!),
                decoration: const InputDecoration(labelText: "Meal Time"),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Cuisine"),
                onChanged: (val) => cuisine = val,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Diet Type"),
                onChanged: (val) => diet = val,
              ),
              _buildChipsInput(
                "Preferred Ingredients",
                _prefCtrl,
                preferredIngredients,
              ),
              _buildChipsInput(
                "Ingredients to Avoid",
                _avoidCtrl,
                avoidIngredients,
              ),
              _buildChipsInput("Allergies", _allergyCtrl, allergies),
              const SizedBox(height: 10),
              Text("Prep Time (minutes): $prepTime"),
              Slider(
                min: 10,
                max: 60,
                value: prepTime.toDouble(),
                onChanged: (v) => setState(() => prepTime = v.round()),
              ),
              const SizedBox(height: 10),
              Text("Max Calories: $calories"),
              Slider(
                min: 100,
                max: 1000,
                value: calories.toDouble(),
                onChanged: (v) => setState(() => calories = v.round()),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : _generateRecipe,
                child:
                    isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Generate Recipe"),
              ),
              const SizedBox(height: 20),
              if (generatedRecipe != null) ...[
                Text(
                  generatedRecipe!['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(generatedRecipe!['description'] ?? ''),
                const SizedBox(height: 10),
                Text(
                  "Ingredients:",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...List<String>.from(
                  generatedRecipe!['ingredients'] ?? [],
                ).map((i) => Text("• $i")),
                const SizedBox(height: 10),
                Text(
                  "Instructions:",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...List<String>.from(
                  generatedRecipe!['instructions'] ?? [],
                ).map((s) => Text("• $s")),
                const SizedBox(height: 10),
                Text("Calories: ${generatedRecipe!['calories']}"),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _saveRecipeToMyRecipes,
                  icon: const Icon(Icons.save),
                  label: const Text("Save to My Recipes"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
