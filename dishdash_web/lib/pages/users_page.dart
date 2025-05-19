// ADD this import at the top
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const Color maroon = Color(0xFF8B0000);
const Color darkGreen = Color(0xFF304D30);

class UsersPage extends StatefulWidget {
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final String baseUrl = 'http://192.168.1.4:3000';
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  Map<String, dynamic>? selectedUser;
  List<Map<String, dynamic>> userRecipes = [];
  int followerCount = 0;
  String searchQuery = '';
  int privateRecipeCount = 0;
  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    final res = await http.get(Uri.parse('$baseUrl/api/users'));
    if (res.statusCode == 200) {
      final all = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      final userList = all.where((u) => u['role'] != 'admin').toList();
      setState(() {
        users = userList;
        filteredUsers = userList;
      });
    }
  }

  void filterUsers(String query) {
    final lowerQuery = query.toLowerCase();
    final filtered =
        users.where((u) {
          final name = u['name']?.toString().toLowerCase() ?? '';
          final email = u['email']?.toString().toLowerCase() ?? '';
          return name.contains(lowerQuery) || email.contains(lowerQuery);
        }).toList();
    setState(() {
      searchQuery = query;
      filteredUsers = filtered;
    });
  }

  Future<void> fetchUserDetails(String userId) async {
    final profileRes = await http.get(
      Uri.parse('$baseUrl/api/profile/$userId'),
    );
    final countRes = await http.get(
      Uri.parse('$baseUrl/api/users/$userId/followers/count'),
    );
    final recipeRes = await http.get(
      Uri.parse('$baseUrl/api/recipes/admin/all'),
    );
    final allRecipes = List<Map<String, dynamic>>.from(
      json.decode(recipeRes.body),
    );
    final userCreatedRecipes =
        allRecipes.where((r) => r['author']?['_id'] == userId).toList();
    final publicRecipes =
        userCreatedRecipes.where((r) => r['isPublic'] == true).toList();
    final privateCount =
        userCreatedRecipes.where((r) => r['isPublic'] == false).length;

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
        userRecipes = publicRecipes;
        privateRecipeCount = privateCount;
      });
    }
  }

  void _confirmDeleteUser(String userId) async {
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
          filteredUsers.removeWhere((u) => u['_id'] == userId);
          selectedUser = null;
          userRecipes.clear();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User deleted")));
      }
    }
  }

  void _showNotificationModal(BuildContext context) {
    final TextEditingController _messageController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Send Notification"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Enter your message here...",
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: maroon)),
              ),
              ElevatedButton(
                onPressed: () {
                  final message = _messageController.text.trim();
                  // ⚠️ Placeholder for notification logic
                  print('Notification to ${selectedUser?['name']}: $message');
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: darkGreen),
                child: const Text(
                  "Notify",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  ImageProvider<Object>? _getImage(String? data) {
    if (data == null || data.isEmpty) return null;

    if (data.startsWith('http')) return NetworkImage(data);
    try {
      return MemoryImage(base64Decode(data.split(',').last));
    } catch (_) {
      return null;
    }
  }

  void _showUserInfoModal(BuildContext context, int privateCount) {
    final user = selectedUser!;
    final survey = user['survey'] ?? {};

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: _getImage(user['avatar']),
                ),
                const SizedBox(width: 12),
                Text(
                  user['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📧 ${user['email'] ?? ''}'),
                  const SizedBox(height: 8),
                  Text('👥 $followerCount followers'),
                  const Divider(height: 20),

                  if ((survey['preferredTags'] ?? []).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('🧠 Preferred Tags:'),
                    Wrap(
                      spacing: 6,
                      children:
                          List<String>.from(
                            survey['preferredTags'],
                          ).map((e) => Chip(label: Text(e))).toList(),
                    ),
                  ],
                  if ((survey['preferredCuisines'] ?? []).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('🍽️ Cuisines:'),
                    Wrap(
                      spacing: 6,
                      children:
                          List<String>.from(
                            survey['preferredCuisines'],
                          ).map((e) => Chip(label: Text(e))).toList(),
                    ),
                  ],
                  if (survey['diet'] != null) ...[
                    const SizedBox(height: 12),
                    Text('🥗 Diet: ${survey['diet']}'),
                  ],
                  if (survey['bmiStatus'] != null) ...[
                    Text('📊 BMI: ${survey['bmiStatus']}'),
                  ],
                  if (survey['weight'] != null && survey['height'] != null) ...[
                    Text('⚖️ Weight: ${survey['weight']} kg'),
                    Text('📏 Height: ${survey['height']} cm'),
                  ],
                  Text('🔒 Private Recipes: $privateCount'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(color: maroon)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGreen,
      body: Row(
        children: [
          // 🔍 User List + Search
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: filterUsers,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (_, index) {
                      final user = filteredUsers[index];
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 📄 Right Side: Selected User Recipes
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
                                    selectedUser?['email'] ?? '',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    '$followerCount followers',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'User Info',
                                icon: const Icon(Icons.info_outline),
                                color: Colors.white,
                                style: IconButton.styleFrom(
                                  backgroundColor: darkGreen,
                                  shape: const CircleBorder(),
                                ),
                                onPressed: () {
                                  final privateCount =
                                      userRecipes
                                          .where((r) => r['isPublic'] == false)
                                          .length;
                                  _showUserInfoModal(
                                    context,
                                    privateRecipeCount,
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Delete User',
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.white,
                                style: IconButton.styleFrom(
                                  backgroundColor: maroon,
                                  shape: const CircleBorder(),
                                ),
                                onPressed:
                                    () => _confirmDeleteUser(
                                      selectedUser!['_id'],
                                    ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Send Notification',
                                icon: const Icon(
                                  Icons.notifications_active_outlined,
                                ),
                                color: Colors.white,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.orange[700],
                                  shape: const CircleBorder(),
                                ),
                                onPressed:
                                    () => _showNotificationModal(context),
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
                                        child:
                                            (() {
                                              final image = _getImage(
                                                recipe['image'],
                                              );
                                              return image == null
                                                  ? Container(
                                                    width: 120,
                                                    height: 120,
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.image_not_supported,
                                                      size: 40,
                                                    ),
                                                  )
                                                  : Image(
                                                    image: image,
                                                    width: 120,
                                                    height: 120,
                                                    fit: BoxFit.cover,
                                                  );
                                            })(),
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
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
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
