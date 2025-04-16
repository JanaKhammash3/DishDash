import 'package:flutter/material.dart';
import 'package:frontend/colors.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
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
                        Text('Welcome back!', style: TextStyle(fontSize: 16)),
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

                // Search Bar
                TextField(
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
                const SizedBox(height: 20),

                // Recipe Categories
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),

                // 2x2 Grid for Popular Recipes
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    popularCard('PASTA BAKE', 'assets/pasta.png'),
                    popularCard('GARLIC-BUTTER RIB ROAST', 'assets/meat.jpg'),
                    popularCard('CEASER SALAD', 'assets/salad.jpg'),
                    popularCard('LASAGNA', 'assets/Lasagna.jpg'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF880808),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(25, 0, 0, 0), // replaces withOpacity(0.1)
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              bottomNavItem(Icons.home, 'Home'),
              bottomNavItem(LucideIcons.users, 'Community'),
              bottomNavItem(LucideIcons.calendar, 'Meal Plan'),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                child: bottomNavItem(Icons.person, 'Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget bottomNavItem(IconData icon, String text) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
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
        color: bgColor ?? const Color(0xFF880808),
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
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color.fromARGB(153, 0, 0, 0), // 0.6 * 255 = 153
                  Colors.transparent,
                ],
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
              // Add to saved logic here
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
                colors: [
                  Color.fromARGB(153, 0, 0, 0), // 0.6 * 255 = 153
                  Colors.transparent,
                ],
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
        const Positioned(
          top: 10,
          right: 10,
          child: Icon(Icons.bookmark_border, color: Colors.white),
        ),
      ],
    );
  }
}
