// 📄 Flutter screen: AI Recipe Generator from Available Ingredients
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/colors.dart';
import 'package:frontend/screens/my_recipes_screen.dart';

class AiFromIngredientsScreen extends StatefulWidget {
  final String userId;
  const AiFromIngredientsScreen({super.key, required this.userId});

  @override
  State<AiFromIngredientsScreen> createState() =>
      _AiFromIngredientsScreenState();
}

class _AiFromIngredientsScreenState extends State<AiFromIngredientsScreen> {
  List<String> ingredients = [];
  int servings = 1;
  bool isLoading = false;
  Map<String, dynamic>? generatedRecipe;
  final Set<String> availableIngredients = {};
  @override
  void initState() {
    super.initState();
    _loadAvailableIngredients();
  }

  Future<void> _generateRecipe() async {
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No available ingredients to generate from."),
        ),
      );
      return;
    }
    setState(() => isLoading = true);

    final res = await http.post(
      Uri.parse('http://192.168.68.61:3000/api/ai/generate-from-ingredients'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'availableIngredients': ingredients,
        'servings': servings,
      }),
    );

    setState(() => isLoading = false);

    if (res.statusCode == 200) {
      setState(() => generatedRecipe = jsonDecode(res.body));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to generate recipe.")),
      );
    }
  }

  Future<void> _loadAvailableIngredients() async {
    final url = Uri.parse(
      'http://192.168.68.61:3000/api/users/${widget.userId}/available-ingredients',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final List<String> fetched = List<String>.from(jsonDecode(res.body));
      setState(() {
        ingredients = fetched; // ⬅️ directly assign to ingredients
        availableIngredients.addAll(fetched);
      });
    }
  }

  Future<void> _saveRecipe() async {
    if (generatedRecipe == null) return;

    final response = await http.post(
      Uri.parse(
        'http://192.168.68.61:3000/api/users/${widget.userId}/customRecipe',
      ),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'title': generatedRecipe!['title'],
        'description': generatedRecipe!['description'],
        'ingredients': (generatedRecipe!['ingredients'] as List).join(', '),
        'instructions': (generatedRecipe!['instructions'] as List).join('\n'),

        'image': generatedRecipe!['image'],

        'diet': generatedRecipe!['diet'],
        'prepTime': generatedRecipe!['prepTime'],
        'mealTime': generatedRecipe!['mealTime'],
        'calories': generatedRecipe!['calories'],

        'tags': [],
        'ingredientsAr': [],
        'instructionsAr': '',
        'descriptionAr': '',
        'titleAr': '',
        'isPublic': false,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recipe saved to My Recipes!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MyRecipesScreen(userId: widget.userId),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to save recipe.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: green,
        title: const Text(
          'AI from Ingredients',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (generatedRecipe == null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.kitchen, color: Colors.green, size: 26),
                    SizedBox(width: 8),
                    Text(
                      "Your Available Ingredients",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ingredients.isEmpty
                    ? Column(
                      children: const [
                        Icon(Icons.warning, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("No available ingredients found."),
                      ],
                    )
                    : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children:
                          ingredients
                              .map(
                                (ing) => Chip(
                                  avatar: const Icon(
                                    Icons.eco,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    ing,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: green,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    const Icon(Icons.restaurant_menu, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text("Servings:", style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Slider(
                        min: 1,
                        max: 10,
                        divisions: 9,
                        value: servings.toDouble(),
                        label: "$servings",
                        onChanged: (v) => setState(() => servings = v.round()),
                        activeColor: green,
                        inactiveColor: green.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _generateRecipe,
                  icon:
                      isLoading
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.auto_awesome, color: Colors.white),
                  label: Text(
                    isLoading ? 'Generating...' : 'Generate Recipe',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 20),
                if (generatedRecipe!["image"] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(generatedRecipe!["image"]),
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  generatedRecipe!["title"] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(generatedRecipe!["description"] ?? ''),
                const SizedBox(height: 12),
                const Text(
                  "Ingredients:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...List<String>.from(
                  generatedRecipe!["ingredients"] ?? [],
                ).map((i) => Text('• $i')),
                const SizedBox(height: 12),
                const Text(
                  "Instructions:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...List<String>.from(
                  generatedRecipe!["instructions"] ?? [],
                ).map((i) => Text('• $i')),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _generateRecipe,
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    isLoading
                        ? 'Regenerating...'
                        : 'Didn\'t Like It? Regenerate',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _saveRecipe,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    "Save to My Recipes",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: green),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
