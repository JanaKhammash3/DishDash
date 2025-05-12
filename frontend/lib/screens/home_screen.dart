// HOME SCREEN (Updated with Dynamic Popular & Random Recipes)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/colors.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/community_screen.dart' as saved;
import 'package:frontend/screens/meal_plan_screen.dart';
import 'package:frontend/screens/recipe_screen.dart';
import 'package:frontend/screens/grocery_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import './category_filters.dart';
import 'package:frontend/screens/recommendations_widget.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> mealTimeRecommendations = [];
  List<dynamic> surveyRecommendations = [];
  String selectedCategory = '';
  String? userId;
  String? avatarUrl;
  List<dynamic> randomRecipes = [];
  List<dynamic> popularRecipes = [];
  Set<String> savedRecipeIds = {};
  String? userName;
  final TextEditingController _searchController = TextEditingController();
  int visibleRecipeCount = 4;
  String searchQuery = '';
  bool showSurveyRecommendations = false;
  List<String> selectedIngredients = [];
  double _averageRating(List? ratings) {
    final r = (ratings ?? []).cast<num>();
    return r.isEmpty ? 0.0 : r.reduce((a, b) => a + b) / r.length;
  }

  final List<Map<String, String>> allIngredients = [
    {'name': 'Egg', 'image': 'assets/ingredients/egg.jpg'},
    {'name': 'Chicken', 'image': 'assets/ingredients/chicken.jpg'},
    {'name': 'Pasta', 'image': 'assets/ingredients/pasta.png'},
    {'name': 'Rice', 'image': 'assets/ingredients/rice.png'},
    {'name': 'Beef', 'image': 'assets/ingredients/meat.png'},
    {'name': 'Broccoli', 'image': 'assets/ingredients/broccoli.jpg'},
    {'name': 'Cheese', 'image': 'assets/ingredients/cheese.png'},
    {'name': 'Salmon', 'image': 'assets/ingredients/salmon.png'},
    {'name': 'Lettuce', 'image': 'assets/ingredients/lettuce.png'},
    {'name': 'Milk', 'image': 'assets/ingredients/milk.jpg'},
    {'name': 'Mushroom', 'image': 'assets/ingredients/mushroom.png'},
    {'name': 'Canned Tomato', 'image': 'assets/ingredients/canned_tomato.png'},
    {'name': 'Onion', 'image': 'assets/ingredients/onion.jpg'},
    {'name': 'Garlic', 'image': 'assets/ingredients/garlic.png'},
    {'name': 'Tomato', 'image': 'assets/ingredients/tomato.png'},
    {'name': 'Pepper', 'image': 'assets/ingredients/pepper.png'},
    {'name': 'Zucchini', 'image': 'assets/ingredients/zucchini.jpg'},
    {'name': 'Spinach', 'image': 'assets/ingredients/spinach.png'},
    {'name': 'Carrot', 'image': 'assets/ingredients/carrot.png'},
    {'name': 'Tofu', 'image': 'assets/ingredients/tofupng.png'},
  ];

  final Map<String, Map<String, bool>> _filters = {
    'Calories': {'< 200': false, '200-400': false, '400+': false},
    'Prep Time': {'< 15 min': false, '< 30 min': false, '30+ min': false},
    'Tags': {'gluten-free': false, 'lactose-free': false, 'spicy': false},
    'Difficulty': {'Easy': false, 'Medium': false, 'Hard': false},
  };

  String customTag = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _showRecipeModal(
    String title,
    String description,
    List<dynamic> ingredients,
    int calories,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "🔥 Calories: $calories kcal",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                "📝 Description:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(description.isNotEmpty ? description : 'No description'),
              const SizedBox(height: 12),
              const Text(
                "🥬 Ingredients:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(ingredients.isNotEmpty ? ingredients.join(', ') : 'N/A'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _applyFilters() {
    final Map<String, String> queryParams = {};

    // ✅ Add selectedCategory to query params
    const dietList = [
      'Vegan',
      'Keto',
      'Low-Carb',
      'Paleo',
      'Vegetarian',
      'None',
    ];
    const mealTimeList = ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'];

    if (selectedCategory.isNotEmpty) {
      if (dietList.contains(selectedCategory)) {
        queryParams['diet'] = selectedCategory;
      } else if (mealTimeList.contains(selectedCategory)) {
        queryParams['mealTime'] = selectedCategory;
      } else {
        queryParams['tag'] = selectedCategory;
      }
    }
    // Calories
    if (_filters['Calories'] != null) {
      final selected =
          _filters['Calories']!.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList();
      if (selected.contains('< 200')) queryParams['maxCalories'] = '199';
      if (selected.contains('200-400')) {
        queryParams['minCalories'] = '200';
        queryParams['maxCalories'] = '400';
      }
      if (selected.contains('400+')) queryParams['minCalories'] = '401';
    }

    // Prep Time
    if (_filters['Prep Time'] != null) {
      final selected =
          _filters['Prep Time']!.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList();

      // Clear any previous values
      queryParams.remove('minPrepTime');
      queryParams.remove('maxPrepTime');

      if (selected.contains('< 15 min')) {
        queryParams['maxPrepTime'] = '14';
      } else if (selected.contains('< 30 min')) {
        queryParams['minPrepTime'] = '15';
        queryParams['maxPrepTime'] = '29';
      } else if (selected.contains('30+ min')) {
        queryParams['minPrepTime'] = '30';
      }
    }
    // Tags
    if (_filters['Tags'] != null) {
      final tagList =
          _filters['Tags']!.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList();
      if (tagList.isNotEmpty) {
        queryParams['tags'] = tagList.join(',');
      }
    }
    if (_filters['Difficulty'] != null) {
      final diff =
          _filters['Difficulty']!.entries
              .firstWhere((e) => e.value, orElse: () => MapEntry('', false))
              .key;
      if (diff.isNotEmpty) queryParams['difficulty'] = diff;
    }

    if (selectedIngredients.isNotEmpty) {
      queryParams['ingredients'] = selectedIngredients.join(',');
    }

    fetchFilteredRecipes(queryParams);
  }

  Future<void> fetchFilteredRecipes(Map<String, String> queryParams) async {
    final uri = Uri.http(
      '192.168.68.60:3000',
      '/api/recipes/filter',
      queryParams,
    );
    print('Applying filters: $uri');

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // 🔥 Sort by average rating (same as fetchPopularRecipes)
      data.sort((a, b) {
        final aRatings = (a['ratings'] as List?)?.cast<num>() ?? [];
        final bRatings = (b['ratings'] as List?)?.cast<num>() ?? [];
        final aAvg =
            aRatings.isNotEmpty
                ? aRatings.reduce((x, y) => x + y) / aRatings.length
                : 0.0;
        final bAvg =
            bRatings.isNotEmpty
                ? bRatings.reduce((x, y) => x + y) / bRatings.length
                : 0.0;
        return bAvg.compareTo(aAvg);
      });

      final updatedRecipes =
          data.map((recipe) {
            final image = recipe['image'];
            final imagePath =
                (image != null && image.isNotEmpty)
                    ? 'http://192.168.68.60:3000/images/$image'
                    : 'assets/placeholder.png';

            return {
              ...recipe,
              'imagePath': imagePath,
              'authorName': recipe['author']?['name'],
              'authorAvatar': recipe['author']?['avatar'],
            };
          }).toList();

      setState(() {
        popularRecipes = updatedRecipes;
        visibleRecipeCount = 4;
      });
    } else {
      print('Error fetching filtered recipes: ${response.statusCode}');
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('userId');
    setState(() {
      userId = id;
    });
    if (userId != null) {
      await fetchUserProfile();
      await fetchRandomRecipes();
      await fetchPopularRecipes();
    }
  }

  Future<void> fetchUserProfile() async {
    final url = Uri.parse('http://192.168.68.60:3000/api/profile/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        avatarUrl = data['avatar'];
        savedRecipeIds = Set<String>.from(data['recipes'] ?? []);
        userName = data['name']; // ✅ Add this
      });
    }
  }

  Future<void> fetchRandomRecipes() async {
    final url = Uri.parse('http://192.168.68.60:3000/api/recipes');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final allRecipes = jsonDecode(response.body);
      allRecipes.shuffle();
      setState(() {
        randomRecipes = allRecipes.take(5).toList();
      });
    }
  }

  Future<void> _saveRecipe(String recipeId) async {
    final url = Uri.parse(
      'http://192.168.68.60:3000/api/users/$userId/saveRecipe',
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

  Future<void> _unsaveRecipe(String recipeId) async {
    final url = Uri.parse(
      'http://192.168.68.60:3000/api/users/$userId/unsaveRecipe',
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

  Future<void> fetchPopularRecipes({String? category}) async {
    String baseUrl = 'http://192.168.68.60:3000/api/recipes/filter';
    Uri url;

    if (category != null && category.isNotEmpty) {
      final encodedCategory = Uri.encodeQueryComponent(category);

      const dietList = [
        'Vegan',
        'Keto',
        'Low-Carb',
        'Paleo',
        'Vegetarian',
        'None',
      ];
      const mealTimeList = ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'];
      List<String> queryParams = [];

      final isDiet = dietList.contains(category);
      final isMealTime = mealTimeList.contains(category);

      if (isDiet) {
        queryParams.add('diet=$encodedCategory');
      } else if (isMealTime) {
        queryParams.add('mealTime=$encodedCategory');
      } else {
        queryParams.add('tag=$encodedCategory');
      }

      url = Uri.parse('$baseUrl?${queryParams.join('&')}');
    } else {
      url = Uri.parse(baseUrl); // no filters
    }

    print('Requesting: $url'); // ✅ Debug print

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final allRecipes = jsonDecode(response.body);

      allRecipes.sort((a, b) {
        final aRatings = (a['ratings'] as List?)?.cast<num>() ?? [];
        final bRatings = (b['ratings'] as List?)?.cast<num>() ?? [];
        final aAvg =
            aRatings.isNotEmpty
                ? aRatings.reduce((x, y) => x + y) / aRatings.length
                : 0.0;
        final bAvg =
            bRatings.isNotEmpty
                ? bRatings.reduce((x, y) => x + y) / bRatings.length
                : 0.0;
        return bAvg.compareTo(aAvg);
      });

      final updatedRecipes =
          allRecipes.map((recipe) {
            final image = recipe['image'];
            final imagePath =
                (image != null && image.isNotEmpty)
                    ? 'http://192.168.68.60:3000/images/$image'
                    : 'assets/placeholder.png';

            return {
              ...recipe,
              'imagePath': imagePath,
              'authorName': recipe['author']?['name'],
              'authorAvatar': recipe['author']?['avatar'],
            };
          }).toList();

      setState(() {
        popularRecipes = updatedRecipes;
        visibleRecipeCount = 4;
      });
    } else {
      print('Error fetching recipes: ${response.statusCode}');
    }
  }

  Widget _buildRecommendationsSection() {
    final currentList =
        showSurveyRecommendations
            ? surveyRecommendations
            : mealTimeRecommendations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton(
              onPressed:
                  () => setState(() => showSurveyRecommendations = false),
              style: TextButton.styleFrom(
                backgroundColor:
                    !showSurveyRecommendations ? maroon : Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Recommendation',
                style: TextStyle(
                  color:
                      !showSurveyRecommendations ? Colors.white : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() => showSurveyRecommendations = true),
              style: TextButton.styleFrom(
                backgroundColor:
                    showSurveyRecommendations ? maroon : Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Based on Your Survey',
                style: TextStyle(
                  color:
                      showSurveyRecommendations ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: currentList.length,
            itemBuilder: (context, index) {
              final recipe = currentList[index];

              final imagePath = recipe['imagePath'] ?? 'assets/placeholder.png';

              return placeCard(
                recipe['title'],
                recipe['author']?['name'] ?? 'Unknown',
                imagePath,
                rating: _averageRating(recipe['ratings']),
                authorName: recipe['author']?['name'],
                authorAvatar: recipe['author']?['avatar'],
                onSave: recipe['onSave'],
                isSaved: recipe['isSaved'] ?? false,
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6F5),
      endDrawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Search by Ingredients',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: maroon,
              ),
            ),
            const SizedBox(height: 16),

            if (selectedIngredients.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        selectedIngredients.map((name) {
                          final imagePath =
                              allIngredients.firstWhere(
                                (ing) => ing['name'] == name,
                                orElse:
                                    () => {'image': 'assets/placeholder.png'},
                              )['image']!;

                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundImage: AssetImage(imagePath),
                                    backgroundColor: Colors.white,
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 70,
                                    child: Text(
                                      name,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                right: -2,
                                top: -2,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedIngredients.remove(name);
                                      _applyFilters();
                                    });
                                  },
                                  child: const CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          selectedIngredients.clear();
                          _applyFilters();
                        });
                      },
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          color: maroon, // ✅ Set the text color
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),

            Wrap(
              spacing: 10,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children:
                  allIngredients.map((ingredient) {
                    final name = ingredient['name']!;
                    final imagePath = ingredient['image']!;
                    final isSelected = selectedIngredients.contains(name);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedIngredients.remove(name);
                          } else {
                            selectedIngredients.add(name);
                          }
                          _applyFilters();
                        });
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            backgroundImage: AssetImage(imagePath),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 60,
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const Text(
              'Filter Recipes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: maroon,
              ),
            ),
            const SizedBox(height: 8),
            for (var category in _filters.entries)
              _buildFilterCategory(category.key, category.value),
          ],
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (userId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ProfileScreen(userId: userId!),
                                ),
                              );
                            }
                          },
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                avatarUrl != null && avatarUrl!.isNotEmpty
                                    ? MemoryImage(
                                      base64Decode(avatarUrl!.split(',').last),
                                    )
                                    : const AssetImage('assets/profile.jpg')
                                        as ImageProvider,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back!',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              userName ?? 'FOODIE FRIEND',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.notifications, color: maroon),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 20),
                    _buildCategoryList(),
                    const SizedBox(height: 12),
                    const Text(
                      'Recommendations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RecommendationsWidget(
                      userId: widget.userId,
                      onUpdate: ({
                        required mealTimeBased,
                        required surveyBased,
                      }) {
                        setState(() {
                          mealTimeRecommendations = mealTimeBased;
                          surveyRecommendations = surveyBased;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildRecommendationsSection(),
                    const SizedBox(height: 20),
                    const Text(
                      'Popular Recipes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPopularRecipes(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFilterCategory(String title, Map<String, bool> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        ...options.entries
            .map(
              (entry) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: maroon,
                value: entry.value,
                title: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black, // ✅ Force visible color
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    // Reset all other options in the same category group to false
                    _filters[title]!.updateAll((key, value) => false);
                    _filters[title]![entry.key] = val!;
                  });

                  _applyFilters();
                },
              ),
            )
            .toList(),
        if (title == 'Tags')
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Add custom tag',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  customTag = value.trim().toLowerCase();
                });
              },
              onSubmitted: (value) {
                if (value.trim().isNotEmpty &&
                    !_filters['Tags']!.containsKey(value.trim())) {
                  setState(() {
                    _filters['Tags']![value.trim()] = true;
                    customTag = '';
                  });
                }
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilterDrawer() {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Search by Ingredients',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: maroon,
            ),
          ),
          const SizedBox(height: 16),

          if (selectedIngredients.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children:
                      selectedIngredients.map((name) {
                        final imagePath =
                            allIngredients.firstWhere(
                              (ing) => ing['name'] == name,
                              orElse: () => {'image': 'assets/placeholder.png'},
                            )['image']!;

                        return Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Column(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: AssetImage(imagePath),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              right: -2,
                              top: -2,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedIngredients.remove(name);
                                    _applyFilters();
                                  });
                                },
                                child: const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        selectedIngredients.clear();
                        _applyFilters();
                      });
                    },
                    child: const Text('Clear all'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),

          const Text('Popular', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children:
                allIngredients.map((ingredient) {
                  final name = ingredient['name']!;
                  final imagePath = ingredient['image']!;
                  final isSelected = selectedIngredients.contains(name);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedIngredients.remove(name);
                        } else {
                          selectedIngredients.add(name);
                        }
                        _applyFilters();
                      });
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white,
                          backgroundImage: AssetImage(imagePath),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 60,
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const Text(
            'Filter Recipes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: maroon,
            ),
          ),
          const SizedBox(height: 8),
          for (var category in _filters.entries)
            _buildFilterCategory(category.key, category.value),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                searchQuery = value.trim().toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search recipes...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.filter_list, color: maroon),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
        ),
      ],
    );
  }

  Widget _buildCategoryList() {
    return CategoryFilters(
      selectedCategory: selectedCategory,
      onCategorySelected: (category) {
        setState(() {
          // Toggle selection: unselect if same category clicked again
          if (selectedCategory == category) {
            selectedCategory = '';
          } else {
            selectedCategory = category;
          }
        });

        _applyFilters(); // Use unified filter logic including category
      },
    );
  }

  Widget _buildPopularRecipes() {
    final filtered =
        popularRecipes.where((recipe) {
          final title = (recipe['title'] ?? '').toString().toLowerCase();
          final diet = (recipe['diet'] ?? '').toString().toLowerCase();
          final mealTime = (recipe['mealTime'] ?? '').toString().toLowerCase();

          final matchesSearch = title.contains(searchQuery);
          final matchesCategory =
              selectedCategory.isEmpty ||
              diet == selectedCategory.toLowerCase() ||
              mealTime == selectedCategory.toLowerCase();

          return matchesSearch && matchesCategory;
        }).toList();

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
          children: List.generate(
            filtered.length > visibleRecipeCount
                ? visibleRecipeCount
                : filtered.length,
            (index) {
              final recipe = filtered[index];
              final rawPath = recipe['image'] ?? '';
              final imagePath =
                  rawPath.startsWith('/images/')
                      ? 'http://192.168.68.60:3000$rawPath'
                      : rawPath;

              final ratings = (recipe['ratings'] as List?)?.cast<num>() ?? [];
              final avgRating =
                  ratings.isNotEmpty
                      ? ratings.reduce((x, y) => x + y) / ratings.length
                      : 0.0;

              final isSaved = savedRecipeIds.contains(recipe['_id']);

              return popularRecipeButton(
                recipe['title'] ?? '',
                imagePath,
                avgRating,
                recipe['_id'],
                isSaved,
                description: recipe['description'] ?? '',
                ingredients: recipe['ingredients'] ?? [],
                calories: recipe['calories'] ?? 0,
                authorName: recipe['author']?['name'],
                authorAvatar: recipe['author']?['avatar'],
                prepTime: recipe['prepTime'] ?? 0,
                difficulty: recipe['difficulty'] ?? 'Easy',
                instructions: recipe['instructions'] ?? '',
              );
            },
          ),
        ),
        if (filtered.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (visibleRecipeCount < filtered.length)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        visibleRecipeCount += 4;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: maroon,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'Show More',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                if (visibleRecipeCount > 4) const SizedBox(width: 10),
                if (visibleRecipeCount > 4)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        visibleRecipeCount = (visibleRecipeCount - 4).clamp(
                          4,
                          filtered.length,
                        );
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'Show Less',
                      style: TextStyle(color: maroon),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 60,
        decoration: BoxDecoration(
          color: maroon,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(25, 0, 0, 0),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            bottomNavItem(Icons.home, 'Home', () {}),
            bottomNavItem(
              LucideIcons.users,
              'Community',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => saved.CommunityScreen(userId: widget.userId),
                ),
              ),
            ),
            bottomNavItem(LucideIcons.calendar, 'Meal Plan', () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MealPlannerScreen(userId: userId!),
                ),
              );
              if (result == 'refresh') {
                await fetchPopularRecipes();
              }
            }),
            bottomNavItem(Icons.shopping_cart, 'Groceries', () {
              if (userId != null && userId!.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroceryScreen(userId: userId!),
                  ),
                );
              } else {
                print('❌ No userId found. Cannot open GroceryScreen.');
              }
            }),

            bottomNavItem(Icons.person, 'Profile', () {
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: userId!),
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget categoryButton(
    String text,
    IconData icon, {
    Color? color,
    Color? bgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor ?? maroon,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color ?? Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget popularRecipeButton(
    String title,
    String imagePath,
    double avgRating,
    String recipeId,
    bool isSaved, {
    String description = '',
    List<dynamic> ingredients = const [],
    int calories = 0,
    String? authorName,
    String? authorAvatar,
    int prepTime = 0,
    String difficulty = 'Easy',
    String instructions = '',
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => RecipeScreen(
                  title: title,
                  imagePath: imagePath,
                  rating: avgRating,
                  ingredients: List<String>.from(
                    ingredients.map((e) => e.toString()),
                  ),
                  description: description,
                  prepTime: prepTime,
                  difficulty: difficulty,
                  instructions: instructions,
                ),
          ),
        );
      },
      child: placeCard(
        title,
        '',
        imagePath,
        rating: avgRating,
        onSave: () {
          if (isSaved) {
            _unsaveRecipe(recipeId);
          } else {
            _saveRecipe(recipeId);
          }
        },
        isSaved: isSaved,
        authorName: authorName,
        authorAvatar: authorAvatar,
      ),
    );
  }

  Widget bottomNavItem(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }

  Widget placeCard(
    String title,
    String subtitle,
    String imagePath, {
    double rating = 0.0,
    VoidCallback? onSave,
    bool isSaved = false,
    String? authorName,
    String? authorAvatar,
  }) {
    final isBase64 = imagePath.startsWith('/9j'); // simple base64 check
    final isNetwork = imagePath.startsWith('http');

    ImageProvider imageProvider;
    if (isBase64) {
      imageProvider = MemoryImage(base64Decode(imagePath));
    } else if (isNetwork) {
      imageProvider = NetworkImage(imagePath);
    } else {
      imageProvider = const AssetImage('assets/placeholder.png');
    }

    return Stack(
      children: [
        Container(
          width: 250,
          height: 300,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[300],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image(
                  image: imageProvider,
                  width: 250,
                  height: 300,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.white,
                    ),
                    onPressed: onSave ?? () {},
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color.fromARGB(153, 0, 0, 0),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (authorName != null && authorAvatar != null)
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundImage: MemoryImage(
                                  base64Decode(authorAvatar),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                authorName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// END HOME SCREEN
