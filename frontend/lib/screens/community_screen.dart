import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/colors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/screens/userprofile-screen.dart';

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
  String _formatTimestamp(String? isoString) {
    if (isoString == null) return '';
    final date = DateTime.tryParse(isoString);
    if (date == null) return '';
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  final String baseUrl = 'http://192.168.68.60:3000'; // Adjust for your setup

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
                      // ✅ increment commentCount in local post
                      final postIndex = posts.indexWhere(
                        (p) => p['_id'] == recipeId,
                      );
                      if (postIndex != -1) {
                        setState(() {
                          posts[postIndex]['commentCount'] =
                              (posts[postIndex]['commentCount'] ?? 0) + 1;
                        });
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

      // Fetch comment counts for each recipe
      for (final post in userPosts) {
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

      // ✅ Sort by number of likes (descending)
      userPosts.sort(
        (a, b) => (b['likes']?.length ?? 0).compareTo(a['likes']?.length ?? 0),
      );

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
        backgroundColor: green,
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
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  author?['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (author?['_id'] != userId)
                                ElevatedButton(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => UserProfileScreen(
                                              userId: author?['_id'] ?? '',
                                            ),
                                      ),
                                    );
                                    // Refresh posts after returning
                                    await fetchPosts();
                                    await fetchUserProfile();
                                  },

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Profile',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
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

                              const SizedBox(width: 12), // spacing

                              IconButton(
                                icon: const Icon(
                                  Icons.comment,
                                  color: Colors.grey,
                                ),
                                onPressed: () => openCommentModal(recipeId),
                              ),
                              Text(
                                '${post['commentCount'] ?? 0}',
                              ), // ✅ Show comment count
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
