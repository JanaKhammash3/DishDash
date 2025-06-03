// ✅ NEW HomeScreen (Mimicking RecipesPage, using Survey-Based Recommendations)

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserHomeScreen extends StatefulWidget {
  final String userId;
  const UserHomeScreen({super.key, required this.userId});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  List<dynamic> allRecipes = [];
  List<dynamic> surveyBasedRecipes = [];
  int _currentIndex = 0;
  late Timer _highlightTimer;
  String searchQuery = '';
  String selectedDiet = '';
  String selectedMealTime = '';
  final _searchController = TextEditingController();

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
  String? avatarUrl;
  String? userName;
  Set<String> savedRecipeIds = {};
  List<String> userAllergies = [];
  @override
  void initState() {
    super.initState();
    fetchSurveyRecommendations();
    fetchRecipes();
    fetchUserProfile();
    _highlightTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (surveyBasedRecipes.isNotEmpty) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % surveyBasedRecipes.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _highlightTimer.cancel();
    super.dispose();
  }

  Future<void> fetchUserProfile() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/profile/${widget.userId}',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        avatarUrl = data['avatar'];
        savedRecipeIds = Set<String>.from(data['recipes'] ?? []);
        userName = data['name']; // ✅ Add this
        userAllergies = List<String>.from(data['allergies'] ?? []);
      });
    }
  }

  Future<void> _saveRecipeConfirmed(String recipeId) async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/users/${widget.userId}/saveRecipe',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'recipeId': recipeId}),
    );
    if (response.statusCode == 200) {
      setState(() => savedRecipeIds.add(recipeId));
    }
  }

  bool hasAllergyConflict(List<String> ingredients, List<String> allergies) {
    final lowerIngredients = ingredients.join(',').toLowerCase();
    return allergies.any(
      (allergy) => lowerIngredients.contains(allergy.toLowerCase()),
    );
  }

  Future<void> _unsaveRecipe(String recipeId) async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/users/${widget.userId}/unsaveRecipe',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'recipeId': recipeId}),
    );
    if (response.statusCode == 200) {
      setState(() => savedRecipeIds.remove(recipeId));
    }
  }

  Future<void> fetchSurveyRecommendations() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/users/${widget.userId}/recommendations',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        surveyBasedRecipes = (data['surveyBased'] ?? []);
      });
    }
  }

  Future<void> fetchRecipes() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.4:3000/api/recipes'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      // Sort the data before assigning
      data.sort(
        (a, b) => _averageRating(
          b['ratings'],
        ).compareTo(_averageRating(a['ratings'])),
      );

      // Optional: calculate highest rating if needed later
      final double highestRating =
          data.isNotEmpty ? _averageRating(data.first['ratings']) : 0.0;

      setState(() {
        allRecipes = data;
        // optionally store highestRating in state if needed
      });
    } else {
      // Handle error here
      print('Failed to fetch recipes: ${response.statusCode}');
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
      return NetworkImage('http://192.168.1.4:3000/images/$imageData');
    }
  }

  void _showRecipeDetailsModal(Map<String, dynamic> recipe) {
    final String title = recipe['title'] ?? '';
    final String imagePath = recipe['image'] ?? '';
    final String description =
        recipe['description'] ?? 'No description provided.';
    final List<String> ingredients = List<String>.from(
      recipe['ingredients'] ?? [],
    );
    final String instructions =
        recipe['instructions'] ?? 'No instructions provided.';
    final int prepTime = recipe['prepTime'] ?? 0;
    final String difficulty = recipe['difficulty'] ?? 'Easy';
    final int calories = recipe['calories'] ?? 0;
    final double rating = _averageRating(recipe['ratings']);

    ImageProvider imageProvider;
    try {
      final isLikelyBase64 =
          imagePath.length > 100 &&
          (imagePath.startsWith('/9j') ||
              imagePath.startsWith('iVBOR') ||
              imagePath.contains('base64'));

      if (isLikelyBase64) {
        final base64Str =
            imagePath.contains(',') ? imagePath.split(',').last : imagePath;
        imageProvider = MemoryImage(base64Decode(base64Str));
      } else if (imagePath.startsWith('http')) {
        imageProvider = NetworkImage(imagePath);
      } else {
        imageProvider = NetworkImage(
          'http://192.168.1.4:3000/images/$imagePath',
        );
      }
    } catch (_) {
      imageProvider = const AssetImage('assets/placeholder.png');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
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
                  const SizedBox(height: 16),

                  // 🔹 Image & Title
                  Center(
                    child: CircleAvatar(
                      radius: 70,
                      backgroundImage: imageProvider,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 🔹 Description
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Meta Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 18),
                          const SizedBox(width: 4),
                          Text('$prepTime min'),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, size: 18),
                          const SizedBox(width: 4),
                          Text('$calories kcal'),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.settings, size: 18),
                          const SizedBox(width: 4),
                          Text(difficulty),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(rating.toStringAsFixed(1)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 🔹 Ingredients
                  const Text(
                    "Ingredients",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        ingredients
                            .map(
                              (ing) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  ing,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),

                  const SizedBox(height: 30),

                  // 🔹 Instructions
                  const Text(
                    "Instructions",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    instructions,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
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
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // 🔍 Title & Search
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    /* navigate to profile */
                  },
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        avatarUrl != null && avatarUrl!.isNotEmpty
                            ? MemoryImage(
                              base64Decode(avatarUrl!.split(',').last),
                            )
                            : const AssetImage('assets/profile.png')
                                as ImageProvider,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DishDash',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF304D30),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        children: [
                          const TextSpan(text: 'Welcome back, '),
                          TextSpan(
                            text: userName ?? 'FOODIE FRIEND',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
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
                Flexible(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recommended For You',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (surveyBasedRecipes.isNotEmpty)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            key: ValueKey(_currentIndex),
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
                                  surveyBasedRecipes[_currentIndex]['image'],
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      surveyBasedRecipes[_currentIndex]['title'] ??
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
                                            surveyBasedRecipes[_currentIndex]['ratings'],
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
                            'No recommended recipes available.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 📦 Recipe Grid
              ],
            ),
            const SizedBox(height: 30),
            GridView.count(
              crossAxisCount: 3, // Adjust for your layout
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 285 / 230,
              children:
                  filteredRecipes.map((recipe) {
                    return Container(
                      width: 285, // or 260 or whatever looks good

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
                          // 🔖 Save/Unsave Icon + Allergy Alert
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Column(
                              children: [
                                // Allergy Alert Icon
                                if (hasAllergyConflict(
                                  List<String>.from(
                                    recipe['ingredients'] ?? [],
                                  ),
                                  userAllergies,
                                ))
                                  Tooltip(
                                    message: 'Allergy Alert!',
                                    child: const Icon(
                                      Icons.warning,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                // Save/Unsave Button
                                GestureDetector(
                                  onTap: () {
                                    final recipeId = recipe['_id'];
                                    final hasConflict = hasAllergyConflict(
                                      List<String>.from(
                                        recipe['ingredients'] ?? [],
                                      ),
                                      userAllergies,
                                    );

                                    if (hasConflict &&
                                        !savedRecipeIds.contains(recipeId)) {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (_) => AlertDialog(
                                              title: const Text(
                                                'Allergy Warning',
                                              ),
                                              content: const Text(
                                                'This recipe contains ingredients that match your allergies. Do you want to save it anyway?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _saveRecipeConfirmed(
                                                      recipeId,
                                                    );
                                                  },
                                                  child: const Text(
                                                    'Save Anyway',
                                                  ),
                                                ),
                                              ],
                                            ),
                                      );
                                    } else {
                                      savedRecipeIds.contains(recipeId)
                                          ? _unsaveRecipe(recipeId)
                                          : _saveRecipeConfirmed(recipeId);
                                    }
                                  },
                                  child: Icon(
                                    savedRecipeIds.contains(recipe['_id'])
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color:
                                        savedRecipeIds.contains(recipe['_id'])
                                            ? Colors.white
                                            : Colors.white70,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),

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
                                            () =>
                                                _showRecipeDetailsModal(recipe),
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
