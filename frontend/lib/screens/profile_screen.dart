// PROFILE SCREEN
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/colors.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/community_screen.dart' as saved;
import 'package:frontend/screens/grocery_screen.dart';
import 'package:frontend/screens/meal_plan_screen.dart';
import 'package:image/image.dart' as img;
import 'package:frontend/screens/saved_recipes_screen.dart' as saved;
import 'package:frontend/screens/my_recipes_screen.dart';
import 'package:frontend/screens/calory_score_screen.dart' as saved;
import 'package:frontend/screens/following_screen.dart';
import 'package:frontend/screens/followers_screen.dart';
import 'package:frontend/screens/update_survey_screen.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
  late IO.Socket socket;
  bool isDarkMode = true;
  int followerCount = 0;
  int followingCount = 0;
  String? currentUserId;
  int likesCount = 0;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadCurrentUserId();
    fetchUserProfile();
    connectSocket();
    fetchUserLikes(); // <-- add this
  }

  Future<void> loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString('userId');
    });
  }

  Future<void> fetchUserLikes() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/posts/likes-count/${widget.userId}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          likesCount = data['totalLikes'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching likes: $e');
    }
  }

  Future<void> fetchUserProfile() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/profile/${widget.userId}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          name = data['name'];
          email = data['email'];
          avatarBase64 = data['avatar'];
          followerCount =
              data['followers'] is List
                  ? data['followers'].length
                  : data['followers'] ?? 0;

          followingCount =
              data['following'] is List
                  ? data['following'].length
                  : data['following'] ?? 0;
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

  void connectSocket() {
    socket = IO.io('http://192.168.1.4:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('✅ Socket connected from ProfileScreen');
      socket.emit('join', widget.userId); // 👈 JOIN socket
    });

    socket.onDisconnect((_) {
      print('🔌 Socket disconnected from ProfileScreen');
    });
  }

  void _showScrapeRecipeModal() {
    final TextEditingController urlController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text("Import Pinterest Recipe"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      hintText: "Enter Pinterest recipe link",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green, // your app's green
                          foregroundColor: Colors.white, // icon + label color
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final url = urlController.text.trim();
                          if (url.isEmpty) return;

                          setModalState(() => isLoading = true);

                          final response = await http.post(
                            Uri.parse(
                              'http://192.168.1.4:3000/api/users/${widget.userId}/scrape-pin',
                            ),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({'url': url}),
                          );

                          setModalState(() => isLoading = false);

                          if (response.statusCode == 201) {
                            Navigator.pop(context); // close modal
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        MyRecipesScreen(userId: widget.userId),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Failed to scrape recipe. Try again.",
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.cloud_download),
                        label: const Text("Scrape Recipe"),
                      ),
                ],
              ),
            );
          },
        );
      },
    );
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
        'http://192.168.1.4:3000/api/profile/${widget.userId}/avatar',
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
    try {
      // Notify the backend that this user is going offline
      if (socket.connected) {
        socket.emit('userOffline', widget.userId);
        socket.disconnect();
      }
    } catch (e) {
      debugPrint('Socket error on logout: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _followStatButton(String label, int count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatButton(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _statBox(IconData icon, String label, int value) {
    return Column(
      children: [
        Icon(icon, color: green),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
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
        backgroundColor: green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            final userId = prefs.getString('userId');
            if (userId != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen(userId: userId)),
              );
            }
          },
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, 20),
            child: SizedBox(
              width: 64,
              height: 64,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                shape: const CircleBorder(),
                elevation: 6,
                onPressed: () {
                  _showScrapeRecipeModal();
                },

                child: Image.asset(
                  'assets/Pinterest.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 23),
          const Text(
            'Import Recipe',
            style: TextStyle(fontSize: 12, color: Colors.white),
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 60,
          decoration: BoxDecoration(
            color: green,
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
              navIcon(Icons.home, 'Home', () async {
                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getString('userId');
                if (userId != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(userId: userId),
                    ),
                  );
                }
              }),
              navIcon(Icons.people, 'Community', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => saved.CommunityScreen(userId: widget.userId),
                  ),
                );
              }),
              const SizedBox(width: 40), // space for center FAB
              navIcon(Icons.calendar_today, 'Meal Plan', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MealPlannerScreen(userId: widget.userId),
                  ),
                );
              }),
              navIcon(Icons.shopping_cart, 'Groceries', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroceryScreen(userId: widget.userId),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Header + Avatar + Info + Stats
          Column(
            children: [
              const SizedBox(height: 24),

              // Avatar with green border and edit icon at bottom right
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: green,
                        width: 3,
                      ), // ✅ green border
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          avatarBase64 != null
                              ? MemoryImage(base64Decode(avatarBase64!))
                              : null,
                      backgroundColor: Colors.grey.shade300,
                      child:
                          avatarBase64 == null
                              ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white70,
                              )
                              : null,
                    ),
                  ),

                  // ✅ Edit icon overlaid
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Icon(Icons.edit, size: 18, color: green),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Name and email
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),

              const SizedBox(height: 16),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // FOLLOWING with ripple
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => FollowingScreen(userId: widget.userId),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8,
                        ),
                        child: _statBox(
                          Icons.group_add,
                          'Following',
                          followingCount,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // FOLLOWERS with ripple
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => FollowersScreen(userId: widget.userId),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8,
                        ),
                        child: _statBox(
                          Icons.group,
                          'Followers',
                          followerCount,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // LIKES (no ripple for now)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8,
                    ),
                    child: _statBox(Icons.favorite, 'Likes', likesCount),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Follow button
              if (currentUserId != widget.userId)
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: toggle follow/unfollow
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text(
                    'Follow',
                    style: TextStyle(color: Colors.white),
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),

          // Now your recipe cards etc. below:
          // Now your recipe cards etc. below:
          _buildCard(
            Icons.restaurant_menu,
            'My Recipes',
            'Add or manage your custom recipes',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyRecipesScreen(userId: widget.userId),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildCard(
            Icons.bookmark,
            'Saved Recipes',
            'View your saved dishes and favorites',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => saved.SavedRecipesScreen(userId: widget.userId),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildCard(
            Icons.fitness_center,
            'Calorie Score',
            'Track your nutritional progress',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => saved.CaloryScoreScreen(userId: widget.userId),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildCard(
            Icons.assignment,
            'Update Your Survey',
            'Change dietary and lifestyle preferences',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UpdateSurveyScreen(userId: widget.userId),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: CupertinoColors.activeOrange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _logout,
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

  Widget navIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
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
        leading: Icon(icon, color: green, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
