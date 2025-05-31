import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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
  String selectedDiet = '';
  String selectedMealTime = '';
  final List<Map<String, dynamic>> dietFilters = [
    {'label': 'Vegan', 'icon': Icons.eco},
    {'label': 'Vegetarian', 'icon': Icons.spa},
    {'label': 'Keto', 'icon': Icons.local_fire_department},
    {'label': 'Low-Carb', 'icon': Icons.scale},
  ];

  final List<Map<String, dynamic>> mealTimeFilters = [
    {'label': 'Breakfast', 'icon': Icons.free_breakfast},
    {'label': 'Lunch', 'icon': Icons.lunch_dining},
    {'label': 'Dinner', 'icon': Icons.dinner_dining},
    {'label': 'Snack', 'icon': Icons.fastfood},
  ];
  List<dynamic> topRatedRecipes = [];
  int _currentTopIndex = 0;
  late Timer _topRecipeTimer;
  @override
  void initState() {
    super.initState();
    fetchRecipes();
    _topRecipeTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (topRatedRecipes.isNotEmpty) {
        setState(() {
          _currentTopIndex = (_currentTopIndex + 1) % topRatedRecipes.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _topRecipeTimer.cancel();
    super.dispose();
  }

  void _openAdminCreateModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AdminRecipeCreateModal(
          onRecipeCreated: fetchRecipes, // Refresh grid after adding
        );
      },
    );
  }

  void _showRecipeDetailsModal(Map<String, dynamic> recipe) async {
    final response = await http.get(
      Uri.parse(
        'http://192.168.68.61:3000/api/recipes/${recipe['_id']}/full-details',
      ),
    );

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load recipe details')),
      );
      return;
    }

    final detailed = jsonDecode(response.body);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🔹 Title
                  Text(
                    detailed['title'] ?? 'Recipe Details',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Description
                  if (detailed['description'] != null) ...[
                    const Text(
                      "📝 Description:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(detailed['description']),
                    const SizedBox(height: 16),
                  ],

                  // 🔹 Ingredients
                  const Text(
                    "🍽️ Ingredients:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...List.from(
                    detailed['ingredients'] ?? [],
                  ).map((i) => Text('• $i')),

                  const SizedBox(height: 16),

                  // 🔹 Instructions
                  const Text(
                    "📋 Instructions:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(detailed['instructions'] ?? 'N/A'),

                  const SizedBox(height: 16),

                  // 🔹 Details
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text("Calories: ${detailed['calories']}"),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text("Prep Time: ${detailed['prepTime']} min"),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.restaurant_menu, color: Colors.green),
                      const SizedBox(width: 6),
                      Text("Diet: ${detailed['diet']}"),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text("Meal Time: ${detailed['mealTime']}"),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text("Difficulty: ${detailed['difficulty']}"),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),

                  // 🔹 Author
                  if (detailed['author'] != null) ...[
                    const Text(
                      "👤 Author:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(detailed['author']['name'] ?? 'N/A'),
                    const SizedBox(height: 16),
                  ],

                  // 🔹 Ratings
                  const Text(
                    "⭐ Ratings by users:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...List.from(detailed['ratedBy'] ?? []).map((r) {
                    final user = r['user'];
                    final value = r['value'];
                    return Text("• ${user?['name'] ?? 'Unknown'} rated $value");
                  }),

                  const SizedBox(height: 16),

                  // 🔹 Likes
                  const Text(
                    "👍 Liked by:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...List.from(
                    detailed['likes'] ?? [],
                  ).map((u) => Text("• ${u['name']}")),

                  const SizedBox(height: 16),

                  // 🔹 Comments
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
            );
          },
        );
      },
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
      Uri.parse('http://192.168.68.61:3000/api/recipes/$recipeId'),
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
      Uri.parse('http://192.168.68.61:3000/api/recipes'),
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

        final highestRating =
            data.isNotEmpty ? _averageRating(data.first['ratings']) : 0.0;

        topRatedRecipes =
            data
                .where(
                  (r) =>
                      _averageRating(r['ratings']).toStringAsFixed(1) ==
                      highestRating.toStringAsFixed(1),
                )
                .toList();
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

    final base64Regex = RegExp(r'^data:image/[^;]+;base64,|^/9j|^iVBOR');
    final isBase64 = base64Regex.hasMatch(imageData);
    final isNetwork = imageData.startsWith('http');

    if (isBase64) {
      final base64Str =
          imageData.contains(',') ? imageData.split(',').last : imageData;
      return MemoryImage(base64Decode(base64Str));
    } else if (isNetwork) {
      return NetworkImage(imageData);
    } else {
      return NetworkImage('http://192.168.68.61:3000/images/$imageData');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecipes =
        allRecipes.where((recipe) {
          final matchesDiet =
              selectedDiet.isEmpty ||
              recipe['diet']?.toLowerCase() == selectedDiet.toLowerCase();
          final matchesMeal =
              selectedMealTime.isEmpty ||
              recipe['mealTime']?.toLowerCase() ==
                  selectedMealTime.toLowerCase();
          final title = recipe['title']?.toLowerCase() ?? '';
          return title.contains(searchQuery.toLowerCase()) &&
              matchesDiet &&
              matchesMeal;
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search recipes...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _openAdminCreateModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF304D30), // Dark green
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Create Recipe',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Filters Column (left side)
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sort By Categories',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'By Diet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children:
                                dietFilters.map((filter) {
                                  final isSelected =
                                      selectedDiet == filter['label'];
                                  return FilterButton(
                                    label: filter['label'],
                                    icon: filter['icon'],
                                    selected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        selectedDiet =
                                            isSelected ? '' : filter['label'];
                                      });
                                    },
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'By Meal Time',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children:
                                mealTimeFilters.map((filter) {
                                  final isSelected =
                                      selectedMealTime == filter['label'];
                                  return FilterButton(
                                    label: filter['label'],
                                    icon: filter['icon'],
                                    selected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        selectedMealTime =
                                            isSelected ? '' : filter['label'];
                                      });
                                    },
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 🔸 Top Rated Recipe Card (right side)
                  Flexible(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Top Rated Recipes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (topRatedRecipes.isNotEmpty &&
                            _currentTopIndex < topRatedRecipes.length)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: Container(
                              key: ValueKey(_currentTopIndex),
                              width: 600,
                              height: 250,

                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: getImageProvider(
                                    topRatedRecipes[_currentTopIndex]['image'],
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.65),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  alignment: Alignment.bottomLeft,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        topRatedRecipes[_currentTopIndex]['title'] ??
                                            '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
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
                                              topRatedRecipes[_currentTopIndex]['ratings'],
                                            ).toStringAsFixed(1),
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'No top-rated recipes available.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 📦 Recipe Grid
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children:
                    filteredRecipes.map((recipe) {
                      return Container(
                        width: (MediaQuery.of(context).size.width - 80) / 4.5,

                        height: 230,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: getImageProvider(recipe['image']),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Faded black gradient at the bottom
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipe['title'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'by ${recipe['author']?['name'] ?? 'System'}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _averageRating(
                                            recipe['ratings'],
                                          ).toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.local_fire_department,
                                          size: 14,
                                          color: Colors.redAccent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${recipe['calories']} kcal',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Icon(
                                          Icons.settings,
                                          size: 14,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          recipe['difficulty'] ?? 'Easy',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.info_outline,
                                            color: Colors.white,
                                          ),
                                          tooltip: 'View Details',
                                          onPressed:
                                              () => _showRecipeDetailsModal(
                                                recipe,
                                              ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                          tooltip: 'Delete Recipe',
                                          onPressed:
                                              () =>
                                                  _deleteRecipe(recipe['_id']),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

class FilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const FilterButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFF304D30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF304D30), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF304D30) : Colors.white,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF304D30) : Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminRecipeCreateModal extends StatefulWidget {
  final VoidCallback onRecipeCreated;
  const AdminRecipeCreateModal({super.key, required this.onRecipeCreated});

  @override
  State<AdminRecipeCreateModal> createState() => _AdminRecipeCreateModalState();
}

class _AdminRecipeCreateModalState extends State<AdminRecipeCreateModal> {
  Uint8List? imageBytes;
  String title = '',
      ingredients = '',
      calories = '',
      description = '',
      diet = 'None';
  String mealTime = 'Breakfast',
      prepTime = '',
      instructions = '',
      difficulty = 'Easy';
  List<String> tags = [];
  String tagInput = '';

  Future<void> _analyzeCalories() async {
    final ingrList =
        ingredients
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    if (ingrList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter ingredients first')),
      );
      return;
    }

    setState(() => calories = 'Analyzing...');

    try {
      final res = await http.post(
        Uri.parse('http://192.168.68.61:3000/api/analyze-nutrition'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'ingredients': ingrList}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => calories = data['calories'].toString());
      } else {
        setState(() => calories = '');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to analyze calories')),
        );
      }
    } catch (e) {
      setState(() => calories = '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error analyzing calories')));
    }
  }

  Future<void> _submitRecipe() async {
    if (title.isEmpty || calories.isEmpty) return;

    final body = {
      'title': title,
      'description': description,
      'instructions': instructions,
      'ingredients': ingredients.split(',').map((e) => e.trim()).toList(),
      'calories': int.tryParse(calories) ?? 0,
      'prepTime': int.tryParse(prepTime) ?? 0,
      'diet': diet,
      'mealTime': mealTime,
      'difficulty': difficulty,
      'tags': tags,
      'isPublic': true,
      'image': imageBytes != null ? base64Encode(imageBytes!) : '',
    };

    final res = await http.post(
      Uri.parse('http://192.168.68.61:3000/api/recipes/adminCreate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode == 201) {
      Navigator.pop(context);
      widget.onRecipeCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Recipe created successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to create recipe.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create a Recipe (Admin)'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  setState(() => imageBytes = bytes);
                }
              },
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    imageBytes != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(imageBytes!, fit: BoxFit.cover),
                        )
                        : const Center(child: Text('Tap to upload image')),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (val) => title = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Ingredients'),
              onChanged: (val) => ingredients = val,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Calories'),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text: calories),
                    onChanged: (val) => calories = val,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF304D30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _analyzeCalories,
                  child: const Text(
                    'Analyze',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
              onChanged: (val) => description = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Instructions'),
              maxLines: 2,
              onChanged: (val) => instructions = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Prep Time (min)'),
              keyboardType: TextInputType.number,
              onChanged: (val) => prepTime = val,
            ),
            DropdownButtonFormField(
              value: diet,
              decoration: const InputDecoration(labelText: 'Diet'),
              items:
                  ['None', 'Vegan', 'Keto', 'Low-Carb', 'Vegetarian']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
              onChanged: (val) => setState(() => diet = val!),
            ),
            DropdownButtonFormField(
              value: mealTime,
              decoration: const InputDecoration(labelText: 'Meal Time'),
              items:
                  ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
              onChanged: (val) => setState(() => mealTime = val!),
            ),
            DropdownButtonFormField(
              value: difficulty,
              decoration: const InputDecoration(labelText: 'Difficulty'),
              items:
                  ['Easy', 'Medium', 'Hard']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
              onChanged: (val) => setState(() => difficulty = val!),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                labelText: 'Add Tag',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (tagInput.isNotEmpty && !tags.contains(tagInput)) {
                      setState(() {
                        tags.add(tagInput.trim());
                        tagInput = '';
                      });
                    }
                  },
                ),
              ),
              onChanged: (val) => tagInput = val,
              onSubmitted: (_) {
                if (tagInput.isNotEmpty && !tags.contains(tagInput)) {
                  setState(() {
                    tags.add(tagInput.trim());
                    tagInput = '';
                  });
                }
              },
            ),
            Wrap(
              spacing: 6,
              children:
                  tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => setState(() => tags.remove(tag)),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF304D30),
          ),
          onPressed: _submitRecipe,
          child: const Text('Create', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
