import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/colors.dart';

class SavedRecipesScreen extends StatefulWidget {
  final String userId;

  const SavedRecipesScreen({super.key, required this.userId});

  @override
  State<SavedRecipesScreen> createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  List<dynamic> savedRecipes = [];

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
      setState(() => savedRecipes = data);
    }
  }

  void _showRecipeModal(BuildContext context, Map recipe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe['title'] ?? 'Recipe',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: maroon,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("📝 ", style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      recipe['description'] ?? 'No description.',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("🥦 ", style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      (recipe['ingredients'] as List<dynamic>?)?.join(', ') ??
                          'No ingredients.',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("🔥 ", style: TextStyle(fontSize: 18)),
                  Text(
                    '${recipe['calories'] ?? 'N/A'} kcal',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: maroon,
        title: const Text(
          'Saved Recipes',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: savedRecipes.length,
        itemBuilder: (context, index) {
          final recipe = savedRecipes[index];
          return _buildRecipeCard(recipe);
        },
      ),
    );
  }

  Widget _buildRecipeCard(Map recipe) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        leading: const Icon(Icons.bookmark, color: maroon, size: 28),
        title: Text(
          recipe['title'] ?? 'Untitled',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () => _showRecipeModal(context, recipe),
      ),
    );
  }
}
