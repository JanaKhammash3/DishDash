// PROFILE SCREEN
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/colors.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/community_screen.dart';
import 'package:frontend/screens/meal_plan_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
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
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
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
                          child: const CircleAvatar(
                            radius: 24,
                            backgroundImage: AssetImage('assets/profile.jpg'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back!',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              'FOODIE FRIEND',
                              style: TextStyle(fontWeight: FontWeight.bold),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search recipes...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
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
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
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
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Recommendation',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 150,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          placeCard(
                            'BERRY PARFAIT',
                            'By SweetHeaven',
                            'assets/Yogurt-Parfait.jpg',
                          ),
                          placeCard(
                            'VEGAN BURGER',
                            'By GreenEats',
                            'assets/vegan-burger.jpg',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Popular Recipes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        popularRecipeButton('PASTA BAKE', 'assets/pasta.png'),
                        popularRecipeButton(
                          'GARLIC-BUTTER RIB ROAST',
                          'assets/meat.jpg',
                        ),
                        popularRecipeButton('CEASER SALAD', 'assets/salad.jpg'),
                        popularRecipeButton('LASAGNA', 'assets/Lasagna.jpg'),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
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
              bottomNavItem(LucideIcons.users, 'Community', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CommunityScreen()),
                );
              }),
              bottomNavItem(LucideIcons.calendar, 'Meal Plan', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MealPlannerScreen()),
                );
              }),
              bottomNavItem(Icons.shopping_cart, 'Groceries', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GroceryScreen()),
                );
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
      ),
    );
  }

  Widget _buildFilterCategory(String title, Map<String, bool> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        ...options.entries.map((entry) {
          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: maroon,
            value: entry.value,
            onChanged:
                (val) => setState(() => _filters[title]![entry.key] = val!),
            title: Text(entry.key),
          );
        }).toList(),
      ],
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

  Widget placeCard(String title, String subtitle, String imagePath) {
    return Stack(
      children: [
        Container(
          width: 250,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color.fromARGB(153, 0, 0, 0), Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
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
                    const Icon(Icons.person, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Recipe saved!")));
            },
          ),
        ),
      ],
    );
  }

  Widget popularCard(String name, String imagePath) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.bottomLeft,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color.fromARGB(153, 0, 0, 0), Colors.transparent],
              ),
            ),
            child: Text(
              '🍽️ $name',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Recipe saved!")));
            },
          ),
        ),
      ],
    );
  }

  Widget popularRecipeButton(String name, String imagePath) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecipeScreen()),
        );
      },
      child: popularCard(name, imagePath),
    );
  }
}
