import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/colors.dart';
import 'package:frontend/screens/my_recipes_screen.dart';

class AiRecipeFormScreen extends StatefulWidget {
  final String userId;
  const AiRecipeFormScreen({super.key, required this.userId});

  @override
  State<AiRecipeFormScreen> createState() => _AiRecipeFormScreenState();
}

class _AiRecipeFormScreenState extends State<AiRecipeFormScreen> {
  int _step = 0;

  String mealTime = 'Breakfast';
  List<String> preferredIngredients = [];
  List<String> avoidIngredients = [];
  String cuisine = '';
  String diet = 'None';
  List<String> allergies = [];
  int prepTime = 30;
  int calories = 500;
  int servings = 1;

  final _prefCtrl = TextEditingController();
  final _avoidCtrl = TextEditingController();
  final _allergyCtrl = TextEditingController();
  final _cuisineCtrl = TextEditingController();

  bool isLoading = false;
  Map<String, dynamic>? generatedRecipe;

  void _next() => setState(() => _step++);
  void _back() => setState(() => _step--);

  Future<void> _generateRecipe() async {
    setState(() => isLoading = true);

    final res = await http.post(
      Uri.parse('http://192.168.68.60:3000/api/ai/generate-recipe'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mealTime': mealTime,
        'preferredIngredients': preferredIngredients,
        'avoidIngredients': avoidIngredients,
        'cuisine': cuisine,
        'diet': diet,
        'allergies': allergies,
        'prepTime': prepTime,
        'calories': calories,
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

  Future<void> _saveRecipe() async {
    if (generatedRecipe == null) return;

    final response = await http.post(
      Uri.parse(
        'http://192.168.68.60:3000/api/users/${widget.userId}/customRecipe',
      ),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'title': generatedRecipe!['title'],
        'description': generatedRecipe!['description'],
        'ingredients': (generatedRecipe!['ingredients'] as List).join(
          ', ',
        ), // 👈 joined string
        'instructions': (generatedRecipe!['instructions'] as List).join(
          '\n',
        ), // 👈 joined string
        'calories': generatedRecipe!['calories'],
        'image': generatedRecipe!['image'],
        'diet': diet,
        'mealTime': mealTime,
        'prepTime': prepTime,
        'difficulty': 'Easy',
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

  Widget _buildChipsInput(
    String label,
    TextEditingController controller,
    List<String> targetList,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
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
                      onDeleted: () => setState(() => targetList.remove(item)),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _stepTitle(String title, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 40, color: green),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return Column(
          children: [
            _stepTitle("What meal is this for?", Icons.fastfood),
            DropdownButtonFormField<String>(
              value: mealTime,
              items:
                  ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
              onChanged: (v) => setState(() => mealTime = v!),
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            _stepTitle("Preferred Ingredients", Icons.favorite),
            _buildChipsInput(
              "Add ingredients",
              _prefCtrl,
              preferredIngredients,
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            _stepTitle("Ingredients to Avoid", Icons.block),
            _buildChipsInput("Avoid ingredients", _avoidCtrl, avoidIngredients),
          ],
        );
      case 3:
        return Column(
          children: [
            _stepTitle("Preferred Cuisine", Icons.public),
            TextField(
              controller: _cuisineCtrl,
              decoration: const InputDecoration(labelText: 'Cuisine'),
              onChanged: (v) => cuisine = v,
            ),
          ],
        );
      case 4:
        return Column(
          children: [
            _stepTitle("Select a Diet Type", Icons.eco),
            DropdownButtonFormField<String>(
              value: diet,
              items:
                  ['None', 'Vegan', 'Keto', 'Low-Carb', 'Paleo', 'Vegetarian']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
              onChanged: (v) => setState(() => diet = v!),
            ),
          ],
        );
      case 5:
        return Column(
          children: [
            _stepTitle("Allergies", Icons.warning),
            _buildChipsInput("Enter allergies", _allergyCtrl, allergies),
          ],
        );
      case 6:
        return Column(
          children: [
            _stepTitle("Preferred Preparation Time", Icons.timer),
            Slider(
              min: 10,
              max: 120,
              divisions: 22,
              value: prepTime.toDouble(),
              label: "$prepTime min",
              onChanged: (v) => setState(() => prepTime = v.round()),
            ),
          ],
        );
      case 7:
        return Column(
          children: [
            _stepTitle("Calories (approx.)", Icons.local_fire_department),
            Slider(
              min: 100,
              max: 1500,
              divisions: 28,
              value: calories.toDouble(),
              label: "$calories cal",
              onChanged: (v) => setState(() => calories = v.round()),
            ),
          ],
        );
      case 8:
        return Column(
          children: [
            _stepTitle("Number of Servings", Icons.people),
            Slider(
              min: 1,
              max: 10,
              divisions: 9,
              value: servings.toDouble(),
              label: "$servings people",
              onChanged: (v) => setState(() => servings = v.round()),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: green,
        title: const Text(
          'AI Recipe Generator',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            generatedRecipe == null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: _buildStepContent(),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_step > 0)
                          TextButton(
                            onPressed: _back,
                            child: const Text('Back'),
                          ),
                        ElevatedButton(
                          onPressed:
                              isLoading
                                  ? null
                                  : _step == 8
                                  ? _generateRecipe
                                  : _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                          ),
                          child:
                              isLoading
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    _step == 8 ? 'Generate' : 'Next',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                        ),
                      ],
                    ),
                  ],
                )
                : SingleChildScrollView(
                  child: Column(
                    children: [
                      if (generatedRecipe!["image"] != null)
                        Image.memory(
                          base64Decode(generatedRecipe!["image"]),
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      const SizedBox(height: 12),
                      Text(
                        generatedRecipe!["title"] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
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
                        onPressed: _saveRecipe,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          "Save to My Recipes",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: green),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
