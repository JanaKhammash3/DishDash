import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/colors.dart';
import 'package:frontend/screens/recipe_screen.dart';

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

  Future<void> unsaveRecipe(String recipeId) async {
    final url = Uri.parse(
      'http://192.168.68.60:3000/api/users/${widget.userId}/unsaveRecipe',
    );
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'recipeId': recipeId}),
    );
  }

  Future<void> deleteRecipe(String recipeId) async {
    final url = Uri.parse('http://192.168.68.60:3000/api/recipes/$recipeId');
    await http.delete(url);
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

  double _averageRating(dynamic ratings) {
    if (ratings == null || !(ratings is List) || ratings.isEmpty) return 0.0;
    final List<int> list = List<int>.from(ratings);
    return list.reduce((a, b) => a + b) / list.length;
  }

  void _showRecipeModal(BuildContext context, Map recipe) {
    final dynamic author = recipe['author'];
    final String? authorId = author is Map ? author['_id'] : author?.toString();
    final bool isUserRecipe = authorId == widget.userId;

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close modal
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => RecipeScreen(
                            title: recipe['title'] ?? 'Untitled',
                            imagePath: recipe['image'] ?? '',
                            rating: _averageRating(recipe['rating']),
                            ingredients: List<String>.from(
                              (recipe['ingredients'] as List).map(
                                (e) => e.toString(),
                              ),
                            ),
                            description: recipe['description'] ?? '',
                            prepTime:
                                int.tryParse(
                                  recipe['prepTime']?.toString() ?? '0',
                                ) ??
                                0,
                            difficulty: recipe['difficulty'] ?? 'Easy',
                            instructions: recipe['instructions'] ?? '',
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline, color: Colors.white),
                label: const Text(
                  "Show Recipe Info",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  if (isUserRecipe) {
                    await deleteRecipe(recipe['_id']);
                  } else {
                    await unsaveRecipe(recipe['_id']);
                  }
                  fetchSavedRecipes();
                },
                child: Text(
                  isUserRecipe ? 'Delete Recipe' : 'Unsave Recipe',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: green)),
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
        backgroundColor: green,
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
    final String? image = recipe['image'];
    late ImageProvider imageProvider;

    if (image != null && image.startsWith('http')) {
      imageProvider = NetworkImage(image);
    } else if (image != null &&
        (image.startsWith('/9j') || image.startsWith('iVBOR'))) {
      imageProvider = MemoryImage(base64Decode(image));
    } else if (image != null && image.isNotEmpty) {
      imageProvider = NetworkImage('http://192.168.68.60:3000/images/$image');
    } else {
      imageProvider = const AssetImage('assets/placeholder.png');
    }

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
        leading: CircleAvatar(
          radius: 22,
          backgroundImage: imageProvider,
          backgroundColor: Colors.grey[200],
        ),
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
