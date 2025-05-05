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

  Future<void> markMealAsDoneBackend(
    String planId,
    String date,
    String recipeId,
  ) async {
    final url = Uri.parse('http://192.168.68.60:3000/api/mealplans/mark-done');
    await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'planId': planId, 'date': date, 'recipeId': recipeId}),
    );
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

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setStateDialog) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    left: 20,
                    right: 20,
                    top: 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Add Meal",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

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
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topCenter,
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width -
                                      40, // match modal width
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    color: maroon,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(
                                          option,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        onTap: () => onSelected(option),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: maroon,
                            minimumSize: const Size.fromHeight(48),
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
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              child: const Text("Cancel"),
                              onPressed: () => Navigator.pop(context),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: maroon,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "Add",
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: () async {
                                if (selectedRecipe != null &&
                                    selectedDate != null) {
                                  print(
                                    '✅ Add button pressed. Recipe and date selected.',
                                  );

                                  final planResponse = await http.get(
                                    Uri.parse(
                                      'http://192.168.68.60:3000/api/mealplans/user/${widget.userId}',
                                    ),
                                  );

                                  print(
                                    '📥 Plan response status: ${planResponse.statusCode}',
                                  );
                                  if (planResponse.statusCode == 200) {
                                    final plans = jsonDecode(planResponse.body);
                                    var plan =
                                        plans.isNotEmpty ? plans.last : null;

                                    if (plan == null) {
                                      // 👇 Create a new meal plan if none exists
                                      final createResponse = await http.post(
                                        Uri.parse(
                                          'http://192.168.68.60:3000/api/mealplans',
                                        ),
                                        headers: {
                                          'Content-Type': 'application/json',
                                        },
                                        body: jsonEncode({
                                          'userId': widget.userId,
                                          'weekStartDate': DateTime.now()
                                              .toIso8601String()
                                              .substring(0, 10), // optional
                                        }),
                                      );

                                      if (createResponse.statusCode == 201) {
                                        final createdPlan = jsonDecode(
                                          createResponse.body,
                                        );
                                        plan = createdPlan;
                                        print(
                                          '🆕 Meal plan created with ID: ${plan['_id']}',
                                        );
                                      } else {
                                        print(
                                          '❌ Failed to create new meal plan',
                                        );
                                        return;
                                      }
                                    }

                                    if (plan != null) {
                                      final planId = plan['_id'];
                                      final formattedDate =
                                          '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';

                                      final addResponse = await http.put(
                                        Uri.parse(
                                          'http://192.168.68.60:3000/api/mealplans/$planId/add-recipe',
                                        ),
                                        headers: {
                                          'Content-Type': 'application/json',
                                        },
                                        body: jsonEncode({
                                          'recipeId': selectedRecipe!['_id'],
                                          'date': formattedDate,
                                        }),
                                      );

                                      print(
                                        '📤 Add recipe response: ${addResponse.statusCode}',
                                      );
                                      print(
                                        '📤 Response body: ${addResponse.body}',
                                      );

                                      if (addResponse.statusCode == 200) {
                                        setState(() {
                                          plannedMeals.add({
                                            'planId': planId,
                                            'date': selectedDate,
                                            'recipe': selectedRecipe!,
                                            'done': false,
                                          });
                                        });
                                        Navigator.pop(context);
                                      } else {
                                        print('❌ Failed to add recipe to plan');
                                      }
                                    } else {
                                      print('⚠️ No meal plan found for user.');
                                    }
                                  } else {
                                    print('❌ Failed to fetch user meal plans');
                                  }
                                } else {
                                  print('⚠️ Missing recipe or date');
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                      child: const Text(
                        "Rate",
                        style: TextStyle(color: Colors.white),
                      ),
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

    final meal = plannedMeals[index];
    final planId = meal['planId'];
    final date =
        "${meal['date'].year}-${meal['date'].month.toString().padLeft(2, '0')}-${meal['date'].day.toString().padLeft(2, '0')}";
    final recipeId = meal['recipe']['_id'];

    markMealAsDoneBackend(planId, date, recipeId);

    _showRatingModal(meal['recipe']);
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
