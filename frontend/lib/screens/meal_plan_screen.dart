import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/colors.dart';

class MealPlannerScreen extends StatefulWidget {
  final String userId;
  const MealPlannerScreen({super.key, required this.userId});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  List<Map<String, dynamic>> plannedMeals = [];
  List<Map<String, dynamic>> savedRecipes = [];

  String? selectedRecipeTitle;
  Map<String, dynamic>? selectedRecipe;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchSavedRecipes();
  }

  Future<void> fetchSavedRecipes() async {
    final url = Uri.parse(
      'http://192.168.68.60:3000/api/users/${widget.userId}/savedRecipes',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() => savedRecipes = List<Map<String, dynamic>>.from(data));
    }
  }

  Future<void> rateRecipe(String recipeId, int rating) async {
    await http.patch(
      Uri.parse('http://192.168.68.60:3000/api/recipes/rate/$recipeId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'rating': rating}),
    );
  }

  void _addMeal() async {
    selectedRecipe = null;
    selectedRecipeTitle = null;
    selectedDate = null;

    await showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text("Add Meal"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          return savedRecipes
                              .map((e) => e['title'] as String)
                              .where(
                                (option) => option.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase(),
                                ),
                              )
                              .toList();
                        },
                        onSelected: (String selection) {
                          setStateDialog(() {
                            selectedRecipeTitle = selection;
                            selectedRecipe = savedRecipes.firstWhere(
                              (recipe) => recipe['title'] == selection,
                            );
                          });
                        },
                        fieldViewBuilder: (
                          context,
                          controller,
                          focusNode,
                          onEditingComplete,
                        ) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Search Recipe',
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: maroon,
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 1),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setStateDialog(() => selectedDate = picked);
                          }
                        },
                        label: Text(
                          selectedDate == null
                              ? 'Select Date'
                              : '${selectedDate!.year}-${selectedDate!.month}-${selectedDate!.day}',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: maroon),
                      child: const Text("Add"),
                      onPressed: () {
                        if (selectedRecipe != null && selectedDate != null) {
                          setState(() {
                            plannedMeals.add({
                              'recipe': selectedRecipe!,
                              'date': selectedDate,
                              'done': false,
                            });
                          });
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
          ),
    );
  }

  void _showRatingModal(Map<String, dynamic> recipe) {
    int selectedRating = 0;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text("Rate Recipe"),
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          Icons.star,
                          color:
                              index < selectedRating
                                  ? Colors.amber
                                  : Colors.grey,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: maroon),
                      child: const Text("Rate"),
                      onPressed: () async {
                        if (selectedRating > 0) {
                          await rateRecipe(recipe['_id'], selectedRating);
                          setState(() {
                            if (recipe['rating'] == null ||
                                recipe['rating'] is! List) {
                              recipe['rating'] = [];
                            }
                            recipe['rating'].add(selectedRating);
                          });
                          Navigator.pop(context);
                          Navigator.pop(context, 'refresh');
                        }
                      },
                    ),
                  ],
                ),
          ),
    );
  }

  void _markAsDone(int index) {
    setState(() {
      plannedMeals[index]['done'] = true;
    });
    _showRatingModal(plannedMeals[index]['recipe']);
  }

  void _removeMeal(int index) {
    setState(() {
      plannedMeals.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Meal Planner",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: maroon,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: maroon,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _addMeal,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: plannedMeals.length,
        itemBuilder: (context, index) {
          final meal = plannedMeals[index];
          final recipe = meal['recipe'];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            child: ListTile(
              title: Text(
                recipe['title'],
                style: TextStyle(
                  decoration: meal['done'] ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Planned for: ${meal['date'].year}-${meal['date'].month}-${meal['date'].day}',
                  ),
                  if (recipe['rating'] != null && recipe['rating'].isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: List.generate(
                        recipe['rating'].last,
                        (i) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.check_circle,
                      color: meal['done'] ? Colors.green : Colors.grey,
                    ),
                    onPressed: meal['done'] ? null : () => _markAsDone(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeMeal(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
