import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  List<dynamic> allRecipes = [];
  dynamic topRatedRecipe;
  String searchQuery = '';
  String selectedCategory = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> categories = [
    {'label': 'Vegan', 'icon': Icons.eco},
    {'label': 'Vegetarian', 'icon': Icons.spa},
    {'label': 'Keto', 'icon': Icons.local_fire_department},
    {'label': 'Low-Carb', 'icon': Icons.scale}, // new
    {'label': 'Lunch', 'icon': Icons.lunch_dining},
    {'label': 'Dinner', 'icon': Icons.dinner_dining},
    {'label': 'Breakfast', 'icon': Icons.free_breakfast}, // new
    {'label': 'Snack', 'icon': Icons.fastfood},
  ];

  @override
  void initState() {
    super.initState();
    fetchRecipes();
  }

  void _showRecipeDetailsModal(Map<String, dynamic> recipe) async {
    final response = await http.get(
      Uri.parse(
        'http://192.168.68.60:3000/api/recipes/${recipe['_id']}/full-details',
      ),
    );

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load recipe details')),
      );
      return;
    }

    final detailed = jsonDecode(response.body);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(detailed['title'] ?? 'Recipe Details'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (detailed['description'] != null) ...[
                      const Text(
                        "📝 Description:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(detailed['description']),
                      const SizedBox(height: 10),
                    ],
                    const Text(
                      "🍽️ Ingredients:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...List.from(
                      detailed['ingredients'] ?? [],
                    ).map((i) => Text('• $i')),

                    const SizedBox(height: 10),
                    const Text(
                      "📋 Instructions:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(detailed['instructions'] ?? 'N/A'),

                    const SizedBox(height: 10),
                    Text("🔥 Calories: ${detailed['calories']}"),
                    Text("🕒 Prep Time: ${detailed['prepTime']} min"),
                    Text("🥗 Diet: ${detailed['diet']}"),
                    Text("⏰ Meal Time: ${detailed['mealTime']}"),
                    Text("⚙️ Difficulty: ${detailed['difficulty']}"),

                    if (detailed['author'] != null) ...[
                      const SizedBox(height: 10),
                      const Text(
                        "👤 Author:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(detailed['author']['name'] ?? 'N/A'),
                    ],

                    const SizedBox(height: 10),
                    const Text(
                      "⭐ Ratings by users:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...List.from(detailed['ratedBy'] ?? []).map((r) {
                      final user = r['user'];
                      final value = r['value'];
                      return Text(
                        "• ${user?['name'] ?? 'Unknown'} rated $value",
                      );
                    }),

                    const SizedBox(height: 10),
                    const Text(
                      "👍 Liked by:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...List.from(
                      detailed['likes'] ?? [],
                    ).map((u) => Text("• ${u['name']}")),

                    const SizedBox(height: 10),
                    const Text(
                      "💬 Comments:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...List.from(detailed['comments'] ?? []).map((c) {
                      final user = c['user'];
                      return Text(
                        "• ${user?['name'] ?? 'Unknown'}: ${c['text']}",
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _deleteRecipe(String recipeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Recipe"),
            content: const Text("Are you sure you want to delete this recipe?"),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Delete"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final response = await http.delete(
      Uri.parse('http://192.168.68.60:3000/api/recipes/$recipeId'),
    );

    if (response.statusCode == 200) {
      setState(() {
        allRecipes.removeWhere((r) => r['_id'] == recipeId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete recipe')));
    }
  }

  Future<void> fetchRecipes() async {
    final response = await http.get(
      Uri.parse('http://192.168.68.60:3000/api/recipes'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        allRecipes = data;
        data.sort(
          (a, b) => _averageRating(
            b['ratings'],
          ).compareTo(_averageRating(a['ratings'])),
        );
        topRatedRecipe = data.isNotEmpty ? data.first : null;
      });
    }
  }

  double _averageRating(List? ratings) {
    final r = (ratings ?? []).cast<num>();
    return r.isEmpty ? 0.0 : r.reduce((a, b) => a + b) / r.length;
  }

  ImageProvider<Object> getImageProvider(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return const AssetImage('assets/placeholder.png');
    }

    final base64Regex = RegExp(r'^data:image/[^;]+;base64,|^/9j');
    final isBase64 = base64Regex.hasMatch(imageData);
    final isNetwork = imageData.startsWith('http');

    if (isBase64) {
      final base64Str =
          imageData.contains(',') ? imageData.split(',').last : imageData;
      return MemoryImage(base64Decode(base64Str));
    } else if (isNetwork) {
      return NetworkImage(imageData);
    } else {
      return NetworkImage('http://192.168.68.60:3000/images/$imageData');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecipes =
        allRecipes.where((recipe) {
          final title = recipe['title']?.toLowerCase() ?? '';
          final diet = recipe['diet']?.toLowerCase() ?? '';
          final mealTime = recipe['mealTime']?.toLowerCase() ?? '';
          return title.contains(searchQuery.toLowerCase()) &&
              (selectedCategory.isEmpty ||
                  diet == selectedCategory.toLowerCase() ||
                  mealTime == selectedCategory.toLowerCase());
        }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔍 Title & Search
              Text(
                "DishDash Admin",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text("What recipe are you looking for?"),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search recipes...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 🥇 Top Rated Recipe
              if (topRatedRecipe != null)
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: getImageProvider(topRatedRecipe['image']),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topRatedRecipe['title'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _averageRating(
                                topRatedRecipe['ratings'],
                              ).toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              // 🎨 Category Filters
              const Text(
                'Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (_, index) {
                    final cat = categories[index];
                    final isSelected = selectedCategory == cat['label'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ChoiceChip(
                        label: Row(
                          children: [
                            Icon(cat['icon'], size: 18),
                            const SizedBox(width: 4),
                            Text(cat['label']),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            selectedCategory = isSelected ? '' : cat['label']!;
                          });
                        },
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                        backgroundColor: Colors.grey[300],
                      ),
                    );
                  },
                ),
              ),

              // 📦 Recipe Grid
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children:
                    filteredRecipes.map((recipe) {
                      return Container(
                        width: MediaQuery.of(context).size.width / 2.3,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image(
                                image: getImageProvider(recipe['image']),
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              recipe['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'by ${recipe['author']?['name'] ?? 'System'}',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),

                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  _averageRating(
                                    recipe['ratings'],
                                  ).toStringAsFixed(1),
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${recipe['calories']} kcal • ${recipe['difficulty'] ?? 'Easy'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.info_outline,
                                    color: Colors.blue,
                                  ),
                                  onPressed:
                                      () => _showRecipeDetailsModal(recipe),
                                  tooltip: 'View Details',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteRecipe(recipe['_id']),
                                  tooltip: 'Delete Recipe',
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
