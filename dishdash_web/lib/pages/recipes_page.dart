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
    {'label': 'Lunch', 'icon': Icons.lunch_dining},
    {'label': 'Dinner', 'icon': Icons.dinner_dining},
    {'label': 'Snack', 'icon': Icons.fastfood},
  ];

  @override
  void initState() {
    super.initState();
    fetchRecipes();
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

              const SizedBox(height: 30),

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
                            const SizedBox(height: 4),
                            Text(
                              '${recipe['calories']} kcal • ${recipe['difficulty'] ?? 'Easy'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
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
