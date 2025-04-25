// PROFILE SCREEN
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/colors.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/community_screen.dart';
import 'package:frontend/screens/grocery_screen.dart';
import 'package:frontend/screens/meal_plan_screen.dart';
import 'package:image/image.dart' as img;

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = '';
  String email = '';
  String? avatarBase64;
  bool isDarkMode = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    final url = Uri.parse(
      'http://192.168.68.59:3000/api/profile/${widget.userId}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          name = data['name'];
          email = data['email'];
          avatarBase64 = data['avatar'];
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to load profile')));
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final rawBytes = await picked.readAsBytes();

      // Decode the image
      final originalImage = img.decodeImage(rawBytes);
      if (originalImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not process image')),
        );
        return;
      }

      // Resize and compress
      final resized = img.copyResize(
        originalImage,
        width: 300,
      ); // Resize to 300px width
      final compressedBytes = img.encodeJpg(
        resized,
        quality: 70,
      ); // JPEG quality 70%

      final base64String = base64Encode(compressedBytes);

      final url = Uri.parse(
        'http://192.168.68.59:3000/api/profile/${widget.userId}/avatar',
      );

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'avatar': base64String}),
      );

      if (response.statusCode == 200) {
        await fetchUserProfile(); // Force refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload avatar')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAvatar = avatarBase64 != null && avatarBase64!.isNotEmpty;
    final avatarImage =
        hasAvatar
            ? MemoryImage(base64Decode(avatarBase64!)) as ImageProvider
            : null;

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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 64,
        height: 64,
        margin: const EdgeInsets.only(top: 10),
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
          onPressed: () {
            // Add Recipe action
          },
          elevation: 6,
          child: Icon(Icons.add, color: maroon, size: 32),
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
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navIcon(Icons.home, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }),
              navIcon(Icons.people, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CommunityScreen()),
                );
              }),
              const SizedBox(width: 40), // space for FAB
              navIcon(Icons.calendar_today, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MealPlannerScreen()),
                );
              }),
              navIcon(Icons.shopping_cart, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GroceryScreen()),
                );
              }),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: avatarImage,
                      child:
                          avatarImage == null
                              ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white70,
                              )
                              : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: _pickAndUploadImage,
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
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildCard(
            Icons.restaurant_menu,
            'My Recipes',
            'Add or manage your custom recipes',
            () {},
          ),
          const SizedBox(height: 10),
          _buildCard(
            Icons.bookmark,
            'Saved Recipes',
            'View your saved dishes and favorites',
            () {},
          ),
          const SizedBox(height: 10),
          _buildCard(
            Icons.fitness_center,
            'Calorie Score',
            'Track your nutritional progress',
            () {},
          ),
          const SizedBox(height: 10),
          _buildCard(
            Icons.group,
            'Following',
            'View users and creators you follow',
            () {},
          ),
          const SizedBox(height: 30),
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
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
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

  Widget navIcon(IconData icon, VoidCallback onTap) {
    return IconButton(icon: Icon(icon, color: Colors.white), onPressed: onTap);
  }

  Widget _buildCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Icon(icon, color: maroon, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
