import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const Color maroon = Color(0xFF8B0000);
const Color darkGreen = Color(0xFF304D30);

class UsersPage extends StatefulWidget {
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final String baseUrl = 'http://192.168.1.4:3000';
  List<Map<String, dynamic>> users = [];
  Map<String, dynamic>? selectedUser;
  List<Map<String, dynamic>> userRecipes = [];
  int followerCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final res = await http.get(Uri.parse('$baseUrl/api/users'));
    if (res.statusCode == 200) {
      final all = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      setState(() {
        users = all.where((u) => u['role'] != 'admin').toList();
      });
    }
  }

  Future<void> fetchUserDetails(String userId) async {
    final profileRes = await http.get(
      Uri.parse('$baseUrl/api/profile/$userId'),
    );
    final countRes = await http.get(
      Uri.parse('$baseUrl/api/users/$userId/followers/count'),
    );
    final recipeRes = await http.get(Uri.parse('$baseUrl/api/recipes'));

    if (profileRes.statusCode == 200 && recipeRes.statusCode == 200) {
      final profileData = json.decode(profileRes.body);
      final countData =
          countRes.statusCode == 200
              ? json.decode(countRes.body)
              : {'count': 0};
      final recipes = List<Map<String, dynamic>>.from(
        json.decode(recipeRes.body),
      );

      setState(() {
        selectedUser = profileData;
        followerCount = countData['count'] ?? 0;
        userRecipes =
            recipes.where((r) => r['author']?['_id'] == userId).toList();
      });
    }
  }

  Future<void> deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete User"),
            content: const Text("Are you sure you want to delete this user?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: maroon),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final res = await http.delete(Uri.parse('$baseUrl/api/users/$userId'));
      if (res.statusCode == 200) {
        setState(() {
          users.removeWhere((u) => u['_id'] == userId);
          if (selectedUser?['_id'] == userId) selectedUser = null;
          userRecipes.clear();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User deleted")));
      }
    }
  }

  ImageProvider _getImage(String? data) {
    if (data == null || data.isEmpty)
      return const AssetImage('assets/profile.jpg');
    if (data.startsWith('http')) return NetworkImage(data);
    try {
      return MemoryImage(base64Decode(data.split(',').last));
    } catch (_) {
      return const AssetImage('assets/profile.jpg');
    }
  }

  void _showMapModal(BuildContext context, double lat, double lng) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: SizedBox(
              width: 500,
              height: 300,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.dishdash.admin',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showProfileModal(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(selectedUser?['name'] ?? 'Profile Info'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${selectedUser?['email'] ?? ''}'),
                  Text('Followers: $followerCount'),
                  const SizedBox(height: 10),
                  Text('Allergies:'),
                  Wrap(
                    spacing: 6,
                    children:
                        List<String>.from(
                          selectedUser?['allergies'] ?? [],
                        ).map((i) => Chip(label: Text(i))).toList(),
                  ),
                  const SizedBox(height: 10),
                  Text('Grocery List:'),
                  Wrap(
                    spacing: 6,
                    children:
                        List<String>.from(
                          selectedUser?['groceryList'] ?? [],
                        ).map((i) => Chip(label: Text(i))).toList(),
                  ),
                  const SizedBox(height: 10),
                  if (selectedUser?['survey'] != null) ...[
                    Text('Diet: ${selectedUser!['survey']['diet'] ?? 'N/A'}'),
                    Text(
                      'Weight: ${selectedUser!['survey']['weight'] ?? 'N/A'}',
                    ),
                    Text(
                      'Height: ${selectedUser!['survey']['height'] ?? 'N/A'}',
                    ),
                    Wrap(
                      spacing: 6,
                      children:
                          List<String>.from(
                            selectedUser!['survey']['tags'] ?? [],
                          ).map((tag) => Chip(label: Text(tag))).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }

  void _showRecipeDetailsModal(
    BuildContext context,
    Map<String, dynamic> recipe,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(recipe['title'] ?? 'Recipe'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image(
                    image: _getImage(recipe['image']),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 12),
                  Text('Description: ${recipe['description'] ?? 'N/A'}'),
                  Text('Calories: ${recipe['calories'] ?? 'N/A'}'),
                  Text('Meal Time: ${recipe['mealTime'] ?? 'N/A'}'),
                  Text('Difficulty: ${recipe['difficulty'] ?? 'N/A'}'),
                  const SizedBox(height: 10),
                  const Text('Ingredients:'),
                  Wrap(
                    spacing: 6,
                    children:
                        List<String>.from(
                          recipe['ingredients'] ?? [],
                        ).map((i) => Chip(label: Text(i))).toList(),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGreen,
      body: Row(
        children: [
          // Left: User List
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: users.length,
              itemBuilder: (_, index) {
                final user = users[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: _getImage(user['avatar']),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          user['name'] ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                        ),
                        onPressed: () => fetchUserDetails(user['_id']),
                        child: const Text(
                          "Profile",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: maroon,
                        ),
                        onPressed: () => deleteUser(user['_id']),
                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Right: Profile View
          Expanded(
            flex: 3,
            child:
                selectedUser == null
                    ? const Center(
                      child: Text(
                        'Select a user to view profile',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                    : Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundImage: _getImage(
                                  selectedUser?['avatar'],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedUser?['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${selectedUser?['email'] ?? ''}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    '$followerCount followers',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                ),
                                onPressed: () {
                                  final loc = selectedUser!['location'];
                                  _showMapModal(
                                    context,
                                    (loc['lat'] as num).toDouble(),
                                    (loc['lng'] as num).toDouble(),
                                  );
                                },
                                child: const Text("View Location on Map"),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                ),
                                onPressed: () => _showProfileModal(context),
                                child: const Text("Profile Info"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'User Recipes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              itemCount: userRecipes.length,
                              itemBuilder: (_, index) {
                                final recipe = userRecipes[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          bottomLeft: Radius.circular(12),
                                        ),
                                        child: Image(
                                          image: _getImage(recipe['image']),
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                recipe['title'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                recipe['description'] ?? '',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              ElevatedButton(
                                                onPressed:
                                                    () =>
                                                        _showRecipeDetailsModal(
                                                          context,
                                                          recipe,
                                                        ),
                                                child: const Text(
                                                  'View Details',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
