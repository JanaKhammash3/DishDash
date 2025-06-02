// user_profile_modal_content.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserProfileModalContent extends StatefulWidget {
  final String userId;
  final String viewerId;

  const UserProfileModalContent({
    super.key,
    required this.userId,
    required this.viewerId,
  });

  @override
  State<UserProfileModalContent> createState() =>
      _UserProfileModalContentState();
}

class _UserProfileModalContentState extends State<UserProfileModalContent> {
  final String baseUrl = 'http://192.168.68.61:3000';
  Map<String, dynamic>? user;
  List<Map<String, dynamic>> recipes = [];
  int followerCount = 0;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final profileRes = await http.get(
      Uri.parse('$baseUrl/api/profile/${widget.userId}'),
    );
    final followerRes = await http.get(
      Uri.parse('$baseUrl/api/users/${widget.userId}/followers/count'),
    );
    final recipeRes = await http.get(
      Uri.parse('$baseUrl/api/recipes/admin/all'),
    );
    final viewerRes = await http.get(
      Uri.parse('$baseUrl/api/profile/${widget.viewerId}'),
    );

    if (profileRes.statusCode == 200 &&
        recipeRes.statusCode == 200 &&
        viewerRes.statusCode == 200) {
      final allRecipes = List<Map<String, dynamic>>.from(
        json.decode(recipeRes.body),
      );
      final userPosts =
          allRecipes
              .where(
                (r) =>
                    r['author']?['_id'] == widget.userId &&
                    r['isPublic'] == true,
              )
              .toList();

      final viewer = json.decode(viewerRes.body);
      final isFollowed = (viewer['following'] ?? [])
          .map((e) => e is Map ? e['_id'] : e)
          .contains(widget.userId);

      setState(() {
        user = json.decode(profileRes.body);
        recipes = List<Map<String, dynamic>>.from(userPosts);
        followerCount = json.decode(followerRes.body)['count'] ?? 0;
        isFollowing = isFollowed;
      });
    }
  }

  Future<void> toggleFollow() async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/users/toggleFollow'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': widget.viewerId,
        'targetUserId': widget.userId,
      }),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        isFollowing = data['isFollowing'];
        followerCount = data['followers'];
      });
    }
  }

  ImageProvider _getImage(String? base64OrUrl) {
    if (base64OrUrl == null || base64OrUrl.isEmpty) {
      return const AssetImage('assets/placeholder.png');
    }
    if (base64OrUrl.startsWith('http')) {
      return NetworkImage(base64OrUrl);
    }
    try {
      return MemoryImage(base64Decode(base64OrUrl.split(',').last));
    } catch (_) {
      return const AssetImage('assets/placeholder.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      width: 700,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar & Follow Row
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: _getImage(user!['avatar']),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user!['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user!['email'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '$followerCount followers',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isFollowing
                            ? Colors.grey[300]
                            : const Color(0xFF304D30),
                    foregroundColor: isFollowing ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(isFollowing ? 'Followed' : 'Follow'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              "User Recipes",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),

            ...recipes.map(
              (r) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: Image(
                        image: _getImage(r['image']),
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              r['description'] ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }
}
