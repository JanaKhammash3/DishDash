// HOME SCREEN (Updated with Dynamic Popular & Random Recipes)
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/colors.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/community_screen.dart';
import 'package:frontend/screens/meal_plan_screen.dart';
import 'package:frontend/screens/recipe_screen.dart';
import 'package:frontend/screens/grocery_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userId;
  String? avatarUrl;
  List<dynamic> randomRecipes = [];
  List<dynamic> popularRecipes = [];
  List<dynamic> recommendedRecipes = [];
  Set<String> savedRecipeIds = {};
  String? userName;
  final TextEditingController _searchController = TextEditingController();
  int visibleRecipeCount = 4;
  String searchQuery = '';
  final Map<String, Map<String, bool>> _filters = {
    'Calories': {'< 200': false, '200-400': false, '400+': false},
    'Type': {'Vegan': false, 'Desserts': false, 'Meat': false, 'Keto': false},
    'Meal Time': {'Breakfast': false, 'Lunch': false, 'Dinner': false},
    'Quick Meals': {'< 15 min': false, '< 30 min': false},
    'Soups': {'Veg Soup': false, 'Chicken Soup': false},
  };

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

  Future<void> fetchPopularRecipes() async {
    final url = Uri.parse('http://192.168.68.60:3000/api/recipes');
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

        return bAvg.compareTo(aAvg); // ✅ no .toInt() needed
      });

      final updatedRecipes =
          allRecipes.map((recipe) {
            final image = recipe['image'];
            final imagePath =
                (image != null && image.isNotEmpty)
                    ? 'http://192.168.68.60:3000/images/$image'
                    : 'assets/placeholder.png'; // default fallback

            return {
              ...recipe,
              'imagePath': imagePath,
              'authorName': recipe['author']?['name'],
              'authorAvatar': recipe['author']?['avatar'], // ✅ added this field
            };
          }).toList();

      setState(() {
        popularRecipes = updatedRecipes;
        visibleRecipeCount = 4;
      });
    }
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
              'Filter Recipes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: maroon,
              ),
            ),
            const Divider(),
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
                      'Recommendation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildRecommendations(),
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
                onChanged:
                    (val) => setState(() => _filters[title]![entry.key] = val!),
                title: Text(entry.key),
              ),
            )
            .toList(),
      ],
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
        IconButton(
          icon: const Icon(Icons.filter_list, color: maroon),
          onPressed: () => Scaffold.of(context).openEndDrawer(),
        ),
      ],
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          categoryButton('Vegan', LucideIcons.leaf),
          categoryButton('Desserts', LucideIcons.cupSoda),
          categoryButton('Quick Meals', LucideIcons.timer),
          categoryButton('Breakfast', LucideIcons.sun),
          categoryButton('Soups', LucideIcons.utensilsCrossed),
          categoryButton('Community', LucideIcons.users),
          categoryButton(
            'More',
            LucideIcons.moreHorizontal,
            color: Colors.white,
            bgColor: Colors.grey[200],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recommendedRecipes.length,
        itemBuilder: (context, index) {
          final recipe = recommendedRecipes[index];
          return placeCard(
            recipe['title'],
            recipe['author'] ?? 'Unknown',
            recipe['image'] ?? 'assets/placeholder.png',
          );
        },
      ),
    );
  }

  Widget _buildPopularRecipes() {
    final filtered =
        popularRecipes.where((recipe) {
          final title = (recipe['title'] ?? '').toString().toLowerCase();
          return title.contains(searchQuery);
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
                MaterialPageRoute(builder: (_) => const CommunityScreen()),
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
            bottomNavItem(
              Icons.shopping_cart,
              'Groceries',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GroceryScreen()),
              ),
            ),
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
  }) {
    return GestureDetector(
      onTap: () {
        _showRecipeModal(title, description, ingredients, calories);
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
                      Icons.bookmark,
                      color: isSaved ? Colors.black : Colors.white,
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
