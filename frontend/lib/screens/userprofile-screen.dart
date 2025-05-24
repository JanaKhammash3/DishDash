import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/screens/followers_screen.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

late IO.Socket socket;

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String? userId;
  List<String> savedRecipeIds = [];
  Map<String, dynamic>? user;
  List<dynamic> posts = [];
  bool isFollowing = false;
  int followerCount = 0;
  final String baseUrl = 'http://192.168.1.4:3000';
  List<dynamic> messages = [];
  TextEditingController _chatController = TextEditingController();
  @override
  void initState() {
    super.initState();
    loadUserData();
    initSocket();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');

    if (userId == null) return;

    await Future.wait([
      fetchUser(),
      fetchUserProfile(),
      fetchFollowerCount(),
      fetchIsFollowing(userId!, widget.userId),
      fetchUserPosts(),
    ]);
  }

  Future<void> fetchFollowerCount() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/users/${widget.userId}/followers/count'),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        followerCount = data['count'] ?? 0;
      });
    }
  }

  Future<void> fetchIsFollowing(
    String currentUserId,
    String targetUserId,
  ) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/profile/$currentUserId'),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final List<String> following =
          (data['following'] ?? []).map<String>((id) {
            // Ensure both are strings
            return id is Map ? id['_id'].toString() : id.toString();
          }).toList();

      setState(() {
        isFollowing = following.contains(targetUserId.toString());
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

  Future<void> toggleLike(String recipeId, int index) async {
    if (userId == null) return;
    final res = await http.post(
      Uri.parse('$baseUrl/api/recipes/$recipeId/like'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId}),
    );
    if (res.statusCode == 200) {
      final result = json.decode(res.body);
      setState(() {
        posts[index]['likes'] = result['likes'];
      });
      final post = posts[index];
      if (result['liked'] == true && widget.userId != userId) {
        final post = posts[index];
        await sendNotification(
          recipientId: widget.userId,
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

  void initSocket() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('✅ Socket connected');
      socket.emit('join', userId);
    });
    socket.on('receive_message', (data) {
      print('📥 Received: $data');
      setState(() {
        messages.add(data);
      });
    });

    socket.onDisconnect((_) => print('🔌 Disconnected'));
  }

  bool _isSaving = false;

  Future<void> toggleSave(String recipeId) async {
    if (_isSaving) return;
    _isSaving = true;

    final isSaved = savedRecipeIds.contains(recipeId);
    final route = isSaved ? '/unsaveRecipe' : '/saveRecipe';
    final res = await http.post(
      Uri.parse('$baseUrl/api/users/$userId$route'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'recipeId': recipeId}),
    );

    _isSaving = false;

    if (res.statusCode != 200) {
      print('❌ Failed to toggle save: ${res.body}');
      return;
    }

    print('✅ Toggled save for $recipeId: ${!isSaved}');
    setState(() {
      isSaved ? savedRecipeIds.remove(recipeId) : savedRecipeIds.add(recipeId);
    });
  }

  void openCommentModal(String recipeId) async {
    final TextEditingController _controller = TextEditingController();
    List<dynamic> comments = [];

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
      builder:
          (_) => Padding(
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
                          final commentUserId = c['userId']?['_id'];
                          final createdAt = c['createdAt'];

                          String formattedTime = '';
                          if (createdAt != null) {
                            final date = DateTime.tryParse(createdAt);
                            if (date != null) {
                              formattedTime =
                                  '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                            }
                          }

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
                                  formattedTime,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(c['content']),
                            trailing:
                                commentUserId == userId
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
                                          openCommentModal(recipeId); // refresh
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
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final content = _controller.text.trim();
                      if (content.isEmpty) return;

                      final res = await http.post(
                        Uri.parse('$baseUrl/api/comments/$recipeId'),
                        headers: {'Content-Type': 'application/json'},
                        body: json.encode({
                          'userId': userId,
                          'content': content,
                        }),
                      );

                      if (res.statusCode == 201) {
                        // Notify if not commenting on your own post
                        final post = posts.firstWhere(
                          (p) => p['_id'] == recipeId,
                          orElse: () => null,
                        );
                        if (post != null && widget.userId != userId) {
                          await sendNotification(
                            recipientId: widget.userId,
                            recipientModel: 'User',
                            senderId: userId!,
                            senderModel: 'User',
                            type: 'comment',
                            message:
                                'commented on your recipe "${post['title']}"',
                            relatedId: recipeId,
                          );
                        }

                        Navigator.pop(context);
                        fetchUserPosts(); // Refresh
                      }
                    },
                    child: const Text('Post Comment'),
                  ),
                ],
              ),
            ),
          ),
    );
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

  Future<void> fetchUser() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/profile/${widget.userId}'),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        user = data;
      });
    }
  }

  Future<void> fetchFollowerData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');

    final res = await http.get(Uri.parse('$baseUrl/api/profile/${userId}'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      List following = data['following'] ?? [];

      setState(() {
        isFollowing = following.contains(widget.userId);
      });
    }

    // Count followers (how many follow widget.userId)
    final countRes = await http.get(
      Uri.parse('$baseUrl/api/users/${widget.userId}/followers/count'),
    );
    if (countRes.statusCode == 200) {
      final data = json.decode(countRes.body);
      setState(() {
        followerCount = data['count'];
      });
    }
  }

  bool _isTogglingFollow = false;

  Future<void> toggleFollow() async {
    if (_isTogglingFollow) return;
    _isTogglingFollow = true;

    final res = await http.post(
      Uri.parse('$baseUrl/api/users/toggleFollow'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId, 'targetUserId': widget.userId}),
    );

    _isTogglingFollow = false;
    if (res.statusCode == 200) {
      final result = json.decode(res.body);
      setState(() {
        isFollowing = result['isFollowing'];
        followerCount = result['followers'];
      });

      if (result['isFollowing']) {
        await sendNotification(
          recipientId: widget.userId,
          recipientModel: 'User',
          senderId: userId!,
          senderModel: 'User',
          type: 'follow',
          message: 'started following you',
          relatedId: userId,
        );
      }
    }
  }

  Future<void> fetchUserPosts() async {
    final res = await http.get(Uri.parse('$baseUrl/api/recipes'));
    if (res.statusCode == 200) {
      final List allRecipes = json.decode(res.body);
      final userPosts =
          allRecipes
              .where((r) => r['author']?['_id'] == widget.userId)
              .toList();

      for (final post in userPosts) {
        final commentsRes = await http.get(
          Uri.parse('$baseUrl/api/comments/${post['_id']}'),
        );
        post['commentCount'] =
            commentsRes.statusCode == 200
                ? json.decode(commentsRes.body).length
                : 0;
      }

      setState(() {
        posts = userPosts;
      });
    }
  }

  void openChatModal() async {
    messages.clear();

    final res = await http.get(
      Uri.parse('$baseUrl/api/chats/$userId/${widget.userId}'),
    );
    if (res.statusCode == 200) {
      messages = json.decode(res.body);
    }
    await http.post(
      Uri.parse('$baseUrl/api/chats/markAsRead'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'senderId': widget.userId, // you are reading their messages
        'receiverId': userId, // you are the receiver here
      }),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => StatefulBuilder(
            builder: (context, setModalState) {
              // Prevent duplicate listeners on rebuild
              socket.off('receive_message');
              socket.on('receive_message', (data) {
                setModalState(() {
                  messages.add(data);
                });
              });

              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chat',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 400,
                      child: ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (_, index) {
                          final msg = messages[index];
                          final isMe = msg['senderId']['_id'] == userId;
                          final time = DateTime.tryParse(
                            msg['timestamp'] ?? '',
                          );
                          final formattedTime =
                              time != null
                                  ? '${time.hour}:${time.minute.toString().padLeft(2, '0')}'
                                  : '';

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment:
                                isMe
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                            children: [
                              if (!isMe)
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: _getImageProvider(
                                    msg['senderId']?['avatar'],
                                  ),
                                ),
                              if (!isMe) const SizedBox(width: 8),

                              Flexible(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isMe ? green : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  constraints: const BoxConstraints(
                                    maxWidth: 250,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg['senderId']?['name'] ?? 'User',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isMe
                                                  ? Colors.white
                                                  : Colors.black,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        msg['message'],
                                        style: TextStyle(
                                          color:
                                              isMe
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Text(
                                          formattedTime,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                isMe
                                                    ? Colors.white70
                                                    : Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              if (isMe) const SizedBox(width: 8),
                              if (isMe)
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: _getImageProvider(
                                    msg['senderId']?['avatar'],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final message = _chatController.text.trim();
                            if (message.isEmpty) return;

                            final msgData = {
                              'senderId': userId,
                              'receiverId': widget.userId,
                              'message': message,
                            };

                            socket.emit('send_message', msgData);
                            await sendNotification(
                              recipientId: widget.userId,
                              recipientModel: 'User',
                              senderId: userId!,
                              senderModel: 'User',
                              type: 'message',
                              message: 'sent you a message',
                              relatedId: null,
                            );
                            _chatController
                                .clear(); // just clear, don’t add message manually
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          child: const Text('Send'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        title: const Text('User Profile'),
      ),
      body:
          user == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: _getImageProvider(user?['avatar']),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?['name'] ?? 'User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => FollowersScreen(
                                          userId: widget.userId,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.people_alt_outlined,
                                      size: 16,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$followerCount followers',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (userId != widget.userId)
                        ElevatedButton(
                          onPressed: toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(isFollowing ? 'Followed' : 'Follow'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: openChatModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.chat_bubble_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Chat'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Posts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...posts.map((post) => _buildPostCard(post)).toList(),
                ],
              ),
    );
  }

  Widget _buildPostCard(Map post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: _getImageProvider(user?['avatar']),
            ),
            title: Text(
              user?['name'] ?? 'User',
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
            padding: const EdgeInsets.all(12),
            child: Text(
              post['title'] ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(post['description'] ?? ''),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    (post['likes'] as List?)?.contains(userId) ?? false
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color:
                        (post['likes'] as List?)?.contains(userId) ?? false
                            ? Colors.red
                            : Colors.grey,
                  ),
                  onPressed: () => toggleLike(post['_id'], posts.indexOf(post)),
                ),
                Text('${post['likes']?.length ?? 0}'),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.comment, color: Colors.grey),
                  onPressed: () => openCommentModal(post['_id']),
                ),
                Text('${post['commentCount'] ?? 0}'),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    savedRecipeIds.contains(post['_id'])
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                    color:
                        savedRecipeIds.contains(post['_id'])
                            ? Colors.black
                            : Colors.grey,
                  ),
                  onPressed: () => toggleSave(post['_id']),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
