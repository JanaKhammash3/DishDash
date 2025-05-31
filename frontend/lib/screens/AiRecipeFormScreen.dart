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
      Uri.parse('http://192.168.68.61:3000/api/ai/generate-recipe'),
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
        'http://192.168.68.61:3000/api/users/${widget.userId}/customRecipe',
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Enter value...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    targetList.add(controller.text.trim());
                    controller.clear();
                  });
                }
              },
              child: const Icon(Icons.add, size: 18, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children:
              targetList
                  .map(
                    (item) => Chip(
                      label: Text(item),
                      deleteIcon: const Icon(Icons.close),
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
        CircleAvatar(
          radius: 32,
          backgroundColor: green.withOpacity(0.1),
          child: Icon(icon, size: 30, color: green),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          "Step ${_step + 1} of 9",
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _stepTitle("Select a Cuisine", Icons.public),
            const SizedBox(height: 8),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children:
                    [
                      'Italian',
                      'Asian',
                      'Mexican',
                      'Indian',
                      'French',
                      'Mediterranean',
                      'Middle Eastern',
                      'American',
                      'Thai',
                      'Chinese',
                    ].map((c) {
                      final isSelected = cuisine == c;
                      return GestureDetector(
                        onTap: () => setState(() => cuisine = c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? green : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: green.withOpacity(0.3),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            if (cuisine.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: green, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "Selected: $cuisine",
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.redAccent),
                        onPressed: () => setState(() => cuisine = ''),
                        tooltip: 'Clear selection',
                      ),
                    ],
                  ),
                ),
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
              activeColor: green,
              inactiveColor: green.withOpacity(0.3),
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
              activeColor: green,
              inactiveColor: green.withOpacity(0.3),
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
              activeColor: green,
              inactiveColor: green.withOpacity(0.3),
              onChanged: (v) => setState(() => servings = v.round()),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildNavigationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_step > 0)
          OutlinedButton.icon(
            onPressed: _back,
            icon: const Icon(Icons.arrow_back, color: green),
            label: const Text('Back', style: TextStyle(color: green)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: green)),
          ),
        ElevatedButton.icon(
          onPressed:
              isLoading
                  ? null
                  : _step == 8
                  ? _generateRecipe
                  : _next,
          icon: Icon(
            _step == 8 ? Icons.flash_on : Icons.arrow_forward,
            color: Colors.white,
          ),
          label: Text(
            _step == 8 ? 'Generate' : 'Next',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(backgroundColor: green),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      child: Column(
        children: [
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
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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

          // 🔁 Regenerate Button
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
                    : const Icon(
                      Icons.sentiment_dissatisfied,
                      color: Colors.white,
                    ),
            label: Text(
              isLoading ? 'Regenerating...' : 'Didn\'t Like It? Regenerate',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ Save Button
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
    );
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
        child: Column(
          children: [
            if (generatedRecipe == null) ...[
              // 🔁 Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 9,
                  color: green,
                  backgroundColor: Colors.grey[300],
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child:
                  generatedRecipe == null
                      ? Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (
                            Widget child,
                            Animation<double> animation,
                          ) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1.0, 0.0), // from right
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: SingleChildScrollView(
                            key: ValueKey(_step), // ✅ Unique key per step
                            child: _buildStepContent(),
                          ),
                        ),
                      )
                      : _buildResultView(),
            ),
            if (generatedRecipe == null)
              _buildNavigationControls(), // ⬇️ defined below
          ],
        ),
      ),
    );
  }
}
