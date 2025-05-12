import 'package:flutter/material.dart';
import 'package:frontend/screens/calory_score_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    loadMealsFromBackend();
  }

  Future<void> markMealAsDoneBackend(
    String planId,
    String date,
    String recipeId,
  ) async {
    final url = Uri.parse('http://192.168.1.4:3000/api/mealplans/mark-done');
    await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'planId': planId, 'date': date, 'recipeId': recipeId}),
    );
  }

  Future<void> fetchSavedRecipes() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/users/${widget.userId}/savedRecipes',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() => savedRecipes = List<Map<String, dynamic>>.from(data));
    }
  }

  Future<void> rateRecipe(String recipeId, int rating) async {
    await http.patch(
      Uri.parse('http://192.168.1.4:3000/api/recipes/rate/$recipeId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'rating': rating}),
    );
  }

  Future<void> saveIngredientsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> allIngredients = [];

    for (var meal in plannedMeals) {
      final ingredients = meal['recipe']?['ingredients'];
      if (ingredients != null && ingredients is List) {
        allIngredients.addAll(List<String>.from(ingredients));
      }
    }

    final uniqueIngredients = allIngredients.toSet().toList();

    await prefs.setStringList('groceryIngredients', uniqueIngredients);
    print('✅ Grocery ingredients saved: $uniqueIngredients');

    // 🔥 Save to backend
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/users/${widget.userId}/grocery-list',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ingredients': uniqueIngredients}),
    );

    if (response.statusCode == 200) {
      print('✅ Grocery ingredients saved to backend');
    } else {
      print('❌ Failed to save grocery list to backend');
    }
  }

  Future<void> loadMealsFromBackend() async {
    final res = await http.get(
      Uri.parse('http://192.168.1.4:3000/api/mealplans/user/${widget.userId}'),
    );

    if (res.statusCode == 200) {
      final plans = jsonDecode(res.body);
      if (plans.isNotEmpty) {
        final plan = plans.last;
        final planId = plan['_id'];
        final days = List<Map<String, dynamic>>.from(plan['days'] ?? []);

        final List<Map<String, dynamic>> loaded = [];

        for (var day in days) {
          final date = DateTime.parse(day['date']);
          final meals = List<Map<String, dynamic>>.from(day['meals']);

          for (var meal in meals) {
            final recipeId = meal['recipe'];
            final done = meal['done'] ?? false;

            // Fetch full recipe details
            final recipeRes = await http.get(
              Uri.parse('http://192.168.1.4:3000/api/recipes/$recipeId'),
            );

            if (recipeRes.statusCode == 200) {
              final recipe = jsonDecode(recipeRes.body);

              loaded.add({
                'planId': planId,
                'date': date,
                'recipe': recipe,
                'done': done,
              });
            }
          }
        }

        setState(() => plannedMeals = loaded);
        await saveMealPlan(); // ✅ Sync SharedPreferences
        await saveIngredientsToPrefs(); // ✅ Sync grocery list
        print('✅ Meal plan loaded and synced from backend.');
      }
    } else {
      print('❌ Failed to load meal plan from backend');
      // Optional fallback:
      await loadMealPlan(); // load from SharedPreferences if backend fails
    }
  }

  Future<void> loadMealPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('mealPlan');

    if (data != null) {
      final decoded = jsonDecode(data);
      setState(() {
        plannedMeals = List<Map<String, dynamic>>.from(
          decoded.map((meal) {
            return {
              ...meal,
              'date': DateTime.parse(meal['date']), // ensure it's DateTime
            };
          }),
        );
      });
      print('✅ Meal plan loaded from SharedPreferences.');
    }
  }

  Future<void> saveMealPlan() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      plannedMeals.map((meal) {
        return {
          ...meal,
          'date':
              (meal['date'] is DateTime)
                  ? meal['date'].toIso8601String()
                  : meal['date'], // fallback if already a string
        };
      }).toList(),
    );

    await prefs.setString('mealPlan', encoded);
    print('✅ Meal plan saved to SharedPreferences.');
  }

  ImageProvider _getImageProvider(dynamic image) {
    if (image == null || image.isEmpty) {
      return const AssetImage('assets/placeholder.png');
    }
    if (image is String && image.startsWith('/9j')) {
      // Base64 image
      return MemoryImage(base64Decode(image));
    }
    if (image is String && image.startsWith('http')) {
      // Network image
      return NetworkImage(image);
    }
    // Fallback to server path
    return NetworkImage('http://192.168.1.4:3000/images/$image');
  }

  void addMealToPlan() {
    if (selectedRecipe != null && selectedDate != null) {
      setState(() {
        plannedMeals.add({
          'date': selectedDate.toString(),
          'recipeId': selectedRecipe!['_id'],
          'title': selectedRecipe!['title'],
          'ingredients': selectedRecipe!['ingredients'] ?? [],
        });
      });

      saveMealPlan(); // ✅ Persist the meal plan
      saveIngredientsToPrefs(); // ✅ Already done
    }
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
                                      'http://192.168.1.4:3000/api/mealplans/user/${widget.userId}',
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
                                          'http://192.168.1.4:3000/api/mealplans',
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
                                          'http://192.168.1.4:3000/api/mealplans/$planId/add-recipe',
                                        ),
                                        headers: {
                                          'Content-Type': 'application/json',
                                        },
                                        body: jsonEncode({
                                          'recipeId': selectedRecipe!['_id'],
                                          'date': formattedDate,
                                          'userId':
                                              widget.userId, // 👈 Add this line
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

                                        await saveMealPlan(); // ✅ Save meal to prefs
                                        await Future.delayed(
                                          Duration(milliseconds: 50),
                                        ); // Wait for setState
                                        await saveIngredientsToPrefs();

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

  Future<void> _showRatingModal(Map<String, dynamic> recipe) async {
    int selectedRating = 0;

    return showDialog(
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
                          if (recipe['rating'] == null ||
                              recipe['rating'] is! List) {
                            recipe['rating'] = [];
                          }
                          recipe['rating'].add(selectedRating);
                          Navigator.pop(context); // Only one pop
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

    saveMealPlan(); // ✅ Persist updated 'done' status
    _showRatingModal(meal['recipe']);
  }

  void _removeMeal(int index) async {
    final meal = plannedMeals[index];
    final planId = meal['planId'];
    final date = meal['date'].toIso8601String().split('T')[0];
    final recipeId = meal['recipe']['_id'];

    final url = Uri.parse(
      'http://192.168.1.4:3000/api/mealplans/$planId/remove-recipe',
    );

    final res = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'date': date, 'recipeId': recipeId}),
    );

    if (res.statusCode == 200) {
      setState(() {
        plannedMeals.removeAt(index);
      });
      await saveMealPlan();
      await saveIngredientsToPrefs();
      print('✅ Meal removed from backend and UI');
    } else {
      print('❌ Failed to remove meal from backend');
    }
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
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(vertical: 10),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🖼️ Large Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image(
                      image: _getImageProvider(recipe['image']),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 🏷️ Title and Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          recipe['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${meal['date'].year}-${meal['date'].month}-${meal['date'].day}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // ⭐ Rating
                  if (recipe['rating'] != null && recipe['rating'].isNotEmpty)
                    Row(
                      children: List.generate(
                        recipe['rating'].last,
                        (i) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // ✅ Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(
                          meal['done']
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: meal['done'] ? Colors.green : Colors.grey,
                        ),
                        onPressed: () async {
                          final bool willBeDone = !meal['done'];
                          final planId = meal['planId'];
                          final date =
                              meal['date'].toIso8601String().split('T')[0];
                          final recipeId = meal['recipe']['_id'];

                          print('➡️ Toggling done: $willBeDone');
                          print('Plan ID: $planId');
                          print('Date: $date');
                          print('Recipe ID: $recipeId');

                          final url = Uri.parse(
                            'http://192.168.1.4:3000/api/mealplans/${willBeDone ? 'mark-done' : 'mark-undone'}',
                          );

                          final response = await http.put(
                            url,
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'planId': planId,
                              'date': date,
                              'recipeId': recipeId,
                            }),
                          );

                          if (response.statusCode == 200) {
                            final updatedMeal = {
                              ...plannedMeals[index],
                              'done': willBeDone,
                            };
                            setState(() {
                              plannedMeals[index] = updatedMeal;
                              plannedMeals = List.from(plannedMeals);
                            });
                            await saveMealPlan();
                            print('✅ Done status updated');

                            // 👇 Show rating modal only if just marked as done
                            if (willBeDone) {
                              await _showRatingModal(
                                meal['recipe'],
                              ); // 🔁 wait for rating to finish

                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => CaloryScoreScreen(
                                        userId: widget.userId,
                                      ),
                                ),
                              );

                              if (result == 'refresh') {
                                setState(() {}); // Trigger UI rebuild
                                await loadMealsFromBackend(); // Reload the meals and sync calories
                              }
                            }
                          } else {
                            print('❌ Failed to update done status in backend');
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: maroon),
                        onPressed: () => _removeMeal(index),
                      ),
                    ],
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
