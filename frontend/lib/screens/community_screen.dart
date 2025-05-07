import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CommunityScreen extends StatefulWidget {
  final String userId;
  const CommunityScreen({super.key, required this.userId});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<dynamic> posts = [];
  List<String> savedRecipeIds = [];
  String? userId;

  final String baseUrl = 'http://192.168.1.4:3000'; // Adjust for your setup

  @override
  void initState() {
    super.initState();
    loadUserAndData();
  }

  ImageProvider _getImageProvider(String? imageString) {
    if (imageString == null || imageString.isEmpty) {
      return const AssetImage('assets/placeholder.png');
    }

    if (imageString.startsWith('http')) {
      return NetworkImage(imageString);
    }

    try {
      final decoded = base64Decode(imageString.split(',').last);
      return MemoryImage(decoded);
    } catch (_) {
      return const AssetImage('assets/placeholder.png');
    }
  }

  Future<void> fetchUserProfile() async {
    final res = await http.get(Uri.parse('$baseUrl/api/profile/$userId'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        savedRecipeIds = List<String>.from(data['recipes'] ?? []);
      });
    } else {
      print('❌ Failed to fetch profile');
    }
  }

  Future<void> loadUserAndData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    await fetchUserProfile(); // ✅ load saved recipes
    await fetchPosts();
  }

  Future<void> fetchPosts() async {
    final res = await http.get(Uri.parse('$baseUrl/api/recipes'));

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      final userPosts = data.where((r) => r['author'] != null).toList();
      setState(() {
        posts = userPosts;
      });
    } else {
      print('❌ Failed to fetch recipes');
    }
  }

  Future<void> toggleLike(String recipeId, int index) async {
    if (userId == null) {
      print('❌ No userId found for liking');
      return;
    }

    // ✅ FIXED version
    final res = await http.post(
      Uri.parse('$baseUrl/api/recipes/$recipeId/like'), // 👈 no double /recipes
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId}),
    );

    if (res.statusCode == 200) {
      final result = json.decode(res.body);
      setState(() {
        posts[index]['likes'] = result['likes'];
        posts[index]['liked'] = result['liked'];
      });
    } else {
      print('❌ Like failed with status: ${res.statusCode}');
    }
  }

  Future<void> toggleSave(String recipeId) async {
    final isSaved = savedRecipeIds.contains(recipeId);
    final route = isSaved ? '/unsaveRecipe' : '/saveRecipe';
    final res = await http.post(
      Uri.parse('$baseUrl/api/users/$userId$route'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'recipeId': recipeId}),
    );

    if (res.statusCode == 200) {
      setState(() {
        if (isSaved) {
          savedRecipeIds.remove(recipeId);
        } else {
          savedRecipeIds.add(recipeId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSaved ? 'Removed from saved!' : 'Recipe saved!'),
        ),
      );
    } else {
      print('❌ Save/Unsave failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Our Community',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red.shade900,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body:
          posts.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final recipeId = post['_id'];
                  final author = post['author'];
                  final liked =
                      (post['likes'] as List?)?.contains(userId) ?? false;

                  final isSaved = savedRecipeIds.contains(recipeId);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: _getImageProvider(
                              author?['avatar'],
                            ),
                          ),
                          title: Text(
                            author?['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image(
                            image: _getImageProvider(post['image']),
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4,
                          ),
                          child: Text(
                            post['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8,
                          ),
                          child: Text(post['description'] ?? ''),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  liked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: liked ? Colors.red : Colors.grey,
                                ),
                                onPressed: () => toggleLike(recipeId, index),
                              ),
                              Text('${post['likes']?.length ?? 0}'),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_outline,
                                  color: isSaved ? Colors.black : Colors.grey,
                                ),
                                onPressed: () => toggleSave(recipeId),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
