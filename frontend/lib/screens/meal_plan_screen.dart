import 'package:flutter/material.dart';
import 'package:frontend/colors.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  List<Map<String, dynamic>> plannedMeals = [];

  final TextEditingController _recipeController = TextEditingController();
  DateTime? selectedDate;

  void _addMeal() async {
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Add Meal"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _recipeController,
                  decoration: const InputDecoration(labelText: 'Recipe Name'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  style: ElevatedButton.styleFrom(backgroundColor: maroon),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
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
                  if (_recipeController.text.isNotEmpty &&
                      selectedDate != null) {
                    setState(() {
                      plannedMeals.add({
                        'recipe': _recipeController.text,
                        'date': selectedDate,
                        'done': false,
                      });
                    });
                    _recipeController.clear();
                    selectedDate = null;
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
    );
  }

  void _markAsDone(int index) {
    setState(() {
      plannedMeals[index]['done'] = true;
    });

    // TODO: update calories in profile
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
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 3,
            child: ListTile(
              title: Text(
                meal['recipe'],
                style: TextStyle(
                  decoration: meal['done'] ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Planned for: ${meal['date'].year}-${meal['date'].month}-${meal['date'].day}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.check_circle,
                      color: meal['done'] ? Colors.green : Colors.grey,
                    ),
                    onPressed: () => _markAsDone(index),
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
