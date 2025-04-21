import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/colors.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: maroon,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),

      // ✅ FAB centered and styled
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 6,
        onPressed: () {
          // Navigate to Add Recipe screen
        },
        child: Icon(Icons.add, size: 30, color: maroon),
      ),

      // ✅ Bottom Navigation Bar rounded + clean
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6,
          color: maroon,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.people, color: Colors.white),
                  onPressed: () {
                    // Navigate to Community
                  },
                ),
                const SizedBox(width: 40), // Spacer for FAB
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  onPressed: () {
                    // Navigate to Meal Plan
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  onPressed: () {
                    // Navigate to Groceries
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      // ✅ Body with bottom padding to reveal Logout button
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          const SizedBox(height: 20),

          // 👤 Profile Info
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          _profileImage != null
                              ? FileImage(_profileImage!)
                              : const AssetImage('assets/profile.jpg')
                                  as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: maroon,
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Emily Patterson',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                const Text(
                  'hello@reallygreatsite.com',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 🍽️ My Recipes
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.restaurant_menu, color: Colors.black87),
              title: const Text('My Recipes'),
              subtitle: const Text('Add or manage your custom recipes'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to custom recipes screen
              },
            ),
          ),
          const SizedBox(height: 10),

          // 🥗 Calorie Score
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.fitness_center, color: Colors.black87),
              title: const Text('Calorie Score'),
              subtitle: const Text(
                'View your nutritional tracking and progress',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to calorie score screen
              },
            ),
          ),
          const SizedBox(height: 10),

          // 👥 Following
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.group, color: Colors.black87),
              title: const Text('Following'),
              subtitle: const Text('View users and creators you follow'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navigate to following list screen
              },
            ),
          ),

          const SizedBox(height: 30),

          // 🔓 Logout
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: maroon,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
