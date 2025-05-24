import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/colors.dart';
import 'package:frontend/screens/store_items_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/userprofile-screen.dart';
import 'package:lucide_icons/lucide_icons.dart'; // For modern icons (optional)

class CommunityScreen extends StatefulWidget {
  final String userId;
  const CommunityScreen({super.key, required this.userId});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String selectedCategory = 'users'; // default
  List<dynamic> posts = [];
  List<String> joinedChallengeIds = [];
  List<String> savedRecipeIds = [];
  String? userId;

  final String baseUrl = 'http://192.168.1.4:3000'; // Adjust for your setup

  @override
  void initState() {
    super.initState();
    loadUserAndData();
  }

  String _formatTimestamp(String? isoString) {
    if (isoString == null) return '';
    final date = DateTime.tryParse(isoString);
    if (date == null) return '';
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> joinChallenge(String challengeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/challenges/$challengeId/join'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId}),
    );
    if (response.statusCode == 200) {
      setState(() {
        joinedChallengeIds.add(challengeId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You joined the challenge!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to join challenge.')),
      );
    }
  }

  Future<void> sendNotification({
    required String recipientId,
    required String recipientModel,
    required String senderId,
    required String senderModel,
    required String type,
    required String message,
    String? relatedId,
  }) async {
    await http.post(
      Uri.parse('$baseUrl/api/notifications'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'recipientId': recipientId,
        'recipientModel': recipientModel,
        'senderId': senderId,
        'senderModel': senderModel,
        'type': type,
        'message': message,
        'relatedId': relatedId,
      }),
    );
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

  Future<void> loadUserAndData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
    await fetchUserProfile();
    await fetchPosts();
  }

  Future<void> fetchChallenges() async {
    setState(() => posts = []); // Clear any recipe data
    final res = await http.get(Uri.parse('$baseUrl/api/challenges'));
    if (res.statusCode == 200) {
      setState(() {
        posts = json.decode(res.body);
      });
    }
  }

  Future<void> fetchUserProfile() async {
    final res = await http.get(Uri.parse('$baseUrl/api/profile/$userId'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        savedRecipeIds = List<String>.from(data['recipes'] ?? []);
      });
    }
  }

  Future<void> fetchPosts() async {
    setState(() => posts = []);
    final res = await http.get(Uri.parse('$baseUrl/api/recipes'));

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      List filteredPosts;

      if (selectedCategory == 'users') {
        filteredPosts =
            data
                .where(
                  (r) =>
                      r['author'] != null &&
                      r['type'] != 'store' &&
                      r['type'] != 'challenge',
                )
                .toList();
      } else if (selectedCategory == 'stores') {
        filteredPosts = data.where((r) => r['type'] == 'store').toList();
      } else {
        filteredPosts = data.where((r) => r['type'] == 'challenge').toList();
      }

      for (final post in filteredPosts) {
        final commentsRes = await http.get(
          Uri.parse('$baseUrl/api/comments/${post['_id']}'),
        );
        if (commentsRes.statusCode == 200) {
          final comments = json.decode(commentsRes.body);
          post['commentCount'] = comments.length;
        } else {
          post['commentCount'] = 0;
        }
      }

      filteredPosts.sort(
        (a, b) => (b['likes']?.length ?? 0).compareTo(a['likes']?.length ?? 0),
      );

      setState(() {
        posts = filteredPosts;
      });
    }
  }

  Future<void> toggleLike(String recipeId, int index) async {
    if (userId == null) return;
    final post = posts[index];
    final res = await http.post(
      Uri.parse('$baseUrl/api/recipes/$recipeId/like'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId}),
    );

    if (res.statusCode == 200) {
      final result = json.decode(res.body);
      setState(() {
        posts[index]['likes'] = result['likes'];
        posts[index]['liked'] = result['liked'];
      });
      if (result['liked'] == true && post['author']?['_id'] != userId) {
        await sendNotification(
          recipientId: post['author']['_id'],
          recipientModel: 'User',
          senderId: userId!,
          senderModel: 'User',
          type: 'like',
          message: 'liked your recipe "${post['title']}"',
          relatedId: recipeId,
        );
      }
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
        isSaved
            ? savedRecipeIds.remove(recipeId)
            : savedRecipeIds.add(recipeId);
      });
    }
  }

  Widget _buildCategoryButton(String label, String value, IconData icon) {
    final isSelected = selectedCategory == value;
    return ElevatedButton.icon(
      onPressed: () {
        if (value == 'stores') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StoreItemsScreen()),
          );
        } else {
          setState(() => selectedCategory = value);
          if (value == 'users') {
            fetchPosts();
          } else if (value == 'challenges') {
            fetchChallenges();
          }
        }
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? green : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildChallengeJoinCard(Map post, int index) {
    final isJoined = joinedChallengeIds.contains(post['_id']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.flag,
                  color: Colors.deepOrange,
                ), // You can change color
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),
            Text(post['description'] ?? ''),
            const SizedBox(height: 6),
            Text(
              'Type: ${post['type']}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 6),
            Text(
              'From ${post['startDate']?.split('T')[0]} to ${post['endDate']?.split('T')[0]}',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isJoined ? null : () => joinChallenge(post['_id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isJoined ? 'Joined ✅' : 'Join Challenge'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Our Community',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: green,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body:
          posts.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCategoryButton('Users', 'users', Icons.person),
                        _buildCategoryButton('Stores', 'stores', Icons.store),
                        _buildCategoryButton(
                          'Challenges',
                          'challenges',
                          Icons.flag,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final recipeId = post['_id'];
                        final author = post['author'];
                        final liked =
                            (post['likes'] as List?)?.contains(userId) ?? false;
                        final isSaved = savedRecipeIds.contains(recipeId);

                        if (selectedCategory == 'challenges') {
                          return _buildChallengeJoinCard(post, index);
                        } else {
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
                                  title: Text(author?['name'] ?? 'Unknown'),
                                  trailing:
                                      author?['_id'] != userId
                                          ? ElevatedButton(
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => UserProfileScreen(
                                                        userId:
                                                            author?['_id'] ??
                                                            '',
                                                      ),
                                                ),
                                              );
                                              await fetchPosts();
                                              await fetchUserProfile();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: green,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 6,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                            child: const Text(
                                              'Profile',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          )
                                          : null,
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
                                          color:
                                              liked ? Colors.red : Colors.grey,
                                        ),
                                        onPressed:
                                            () => toggleLike(recipeId, index),
                                      ),
                                      Text('${post['likes']?.length ?? 0}'),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.comment,
                                          color: Colors.grey,
                                        ),
                                        onPressed:
                                            () => openCommentModal(recipeId),
                                      ),
                                      Text('${post['commentCount'] ?? 0}'),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(
                                          isSaved
                                              ? Icons.bookmark
                                              : Icons.bookmark_outline,
                                          color:
                                              isSaved
                                                  ? Colors.black
                                                  : Colors.grey,
                                        ),
                                        onPressed: () => toggleSave(recipeId),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  void openCommentModal(String recipeId) async {
    final TextEditingController _controller = TextEditingController();
    List<dynamic> comments = [];

    // Fetch existing comments
    final res = await http.get(Uri.parse('$baseUrl/api/comments/$recipeId'));
    if (res.statusCode == 200) {
      comments = json.decode(res.body);
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                if (comments.isEmpty)
                  const Text('No comments yet.')
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (_, index) {
                        final c = comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: _getImageProvider(
                              c['userId']?['avatar'],
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c['userId']?['name'] ?? 'User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTimestamp(c['createdAt']),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(c['content']),
                          trailing:
                              c['userId']?['_id'] == userId
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final res = await http.delete(
                                        Uri.parse(
                                          '$baseUrl/api/comments/${c['_id']}',
                                        ),
                                        headers: {
                                          'Content-Type': 'application/json',
                                        },
                                        body: json.encode({'userId': userId}),
                                      );

                                      if (res.statusCode == 200) {
                                        Navigator.pop(context);
                                        openCommentModal(
                                          recipeId,
                                        ); // Refresh modal
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Comment deleted'),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Delete failed'),
                                          ),
                                        );
                                      }
                                    },
                                  )
                                  : null,
                        );
                      },
                    ),
                  ),
                const Divider(),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green, // green
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () async {
                    final content = _controller.text.trim();
                    if (content.isEmpty) return;

                    final res = await http.post(
                      Uri.parse('$baseUrl/api/comments/$recipeId'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({'userId': userId, 'content': content}),
                    );

                    if (res.statusCode == 201) {
                      final postIndex = posts.indexWhere(
                        (p) => p['_id'] == recipeId,
                      );
                      if (postIndex != -1) {
                        setState(() {
                          posts[postIndex]['commentCount'] =
                              (posts[postIndex]['commentCount'] ?? 0) + 1;
                        });

                        final post = posts[postIndex];
                        if (post['author']?['_id'] != userId) {
                          await sendNotification(
                            recipientId: post['author']['_id'],
                            recipientModel: 'User',
                            senderId: userId!,
                            senderModel: 'User',
                            type: 'comment',
                            message:
                                'commented on your recipe "${post['title']}"',
                            relatedId: recipeId,
                          );
                        }
                      }

                      Navigator.pop(context);
                      openCommentModal(recipeId); // refresh modal contents
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Comment added')),
                      );
                    }
                  },
                  child: const Text('Post Comment'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
