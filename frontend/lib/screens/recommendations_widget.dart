import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecommendationsWidget extends StatefulWidget {
  final String userId;
  final void Function({
    required List<dynamic> mealTimeBased,
    required List<dynamic> surveyBased,
  })?
  onUpdate;

  const RecommendationsWidget({super.key, required this.userId, this.onUpdate});

  @override
  State<RecommendationsWidget> createState() => _RecommendationsWidgetState();
}

class _RecommendationsWidgetState extends State<RecommendationsWidget> {
  Set<String> savedRecipeIds = {};

  @override
  void initState() {
    super.initState();
    fetchRecommendations();
    loadSavedRecipes();
  }

  Future<void> loadSavedRecipes() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/profile/${widget.userId}',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      final recipes = userData['recipes'] ?? [];
      setState(() {
        savedRecipeIds = Set<String>.from(recipes.map((r) => r.toString()));
      });
    }
  }

  Future<void> saveRecipe(String recipeId) async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/users/${widget.userId}/saveRecipe',
    );
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'recipeId': recipeId}),
    );
    setState(() => savedRecipeIds.add(recipeId));
  }

  Future<void> unsaveRecipe(String recipeId) async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/users/${widget.userId}/unsaveRecipe',
    );
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'recipeId': recipeId}),
    );
    setState(() => savedRecipeIds.remove(recipeId));
  }

  Future<void> fetchRecommendations() async {
    try {
      final url = Uri.parse(
        'http://192.168.1.4:3000/api/users/${widget.userId}/recommendations',
      );
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final mealTimeRaw = data['mealTimeBased'] as List<dynamic>;
        final surveyRaw = data['surveyBased'] as List<dynamic>;

        List<Map<String, dynamic>> mealTimeBased =
            mealTimeRaw.map<Map<String, dynamic>>((recipe) {
              final ratings = (recipe['ratings'] as List?)?.cast<num>() ?? [];
              final avgRating =
                  ratings.isNotEmpty
                      ? ratings.reduce((a, b) => a + b) / ratings.length
                      : 0.0;
              final rawImage = recipe['image'] ?? '';
              final isBase64 = rawImage.startsWith('/9j');
              final isNetwork = rawImage.startsWith('http');
              final imagePath =
                  isBase64 || isNetwork
                      ? rawImage
                      : rawImage.isNotEmpty
                      ? 'http://192.168.1.4:3000/images/$rawImage'
                      : 'assets/placeholder.png';
              return {
                ...recipe,
                'avgRating': avgRating,
                'imagePath': imagePath,
                'authorName': recipe['author']?['name'],
                'authorAvatar': recipe['author']?['avatar'],
                'isSaved': savedRecipeIds.contains(recipe['_id']),
                'onSave': () async {
                  final id = recipe['_id'];
                  final isAlreadySaved = savedRecipeIds.contains(id);

                  setState(() {
                    if (isAlreadySaved) {
                      savedRecipeIds.remove(id);
                    } else {
                      savedRecipeIds.add(id);
                    }
                  });

                  if (isAlreadySaved) {
                    await unsaveRecipe(id);
                  } else {
                    await saveRecipe(id);
                  }

                  fetchRecommendations();
                },
              };
            }).toList();

        List<Map<String, dynamic>> surveyBased =
            surveyRaw.map<Map<String, dynamic>>((recipe) {
              final ratings = (recipe['ratings'] as List?)?.cast<num>() ?? [];
              final avgRating =
                  ratings.isNotEmpty
                      ? ratings.reduce((a, b) => a + b) / ratings.length
                      : 0.0;
              final rawImage = recipe['image'] ?? '';
              final isBase64 = rawImage.startsWith('/9j');
              final isNetwork = rawImage.startsWith('http');
              final imagePath =
                  isBase64 || isNetwork
                      ? rawImage
                      : rawImage.isNotEmpty
                      ? 'http://192.168.1.4:3000/images/$rawImage'
                      : 'assets/placeholder.png';

              return {
                ...recipe,
                'avgRating': avgRating,
                'imagePath': imagePath,
                'authorName': recipe['author']?['name'],
                'authorAvatar': recipe['author']?['avatar'],
                'isSaved': savedRecipeIds.contains(recipe['_id']),
                'onSave': () {
                  final id = recipe['_id'];
                  if (savedRecipeIds.contains(id)) {
                    unsaveRecipe(id);
                  } else {
                    saveRecipe(id);
                  }
                },
              };
            }).toList();

        if (widget.onUpdate != null) {
          widget.onUpdate!(
            mealTimeBased: mealTimeBased,
            surveyBased: surveyBased,
          );
        }
      } else {
        print('❌ Error fetching recommendations: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ Exception fetching recommendations: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox(); // Still invisible, just feeds data
  }
}
