// ADD this import at the top
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
  late IO.Socket socket;
  Set<String> onlineUsers = {};

  @override
  void initState() {
    super.initState();
    fetchUsers();
    initSocket(); // 👈 CALL IT HERE
  }

  void initSocket() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'query': {'userId': 'admin'}, // optional, since you're using join
    });

    socket.on('connect', (_) {
      print('✅ Connected to socket');

      // 🔥 Emit JOIN after socket connects
      socket.emit(
        'join',
        'admin',
      ); // Replace 'admin' with actual userId if dynamic
    });

    socket.on('userOnlineStatus', (data) {
      print('📡 Status Update: $data');
      setState(() {
        if (data['online']) {
          onlineUsers.add(data['userId']);
        } else {
          onlineUsers.remove(data['userId']);
        }
      });
    });
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

  void _showGlobalNotificationModal(BuildContext context) {
    final TextEditingController _messageController = TextEditingController();
    final TextEditingController _searchController = TextEditingController();
    List<Map<String, dynamic>> filtered = List.from(users);
    String? selectedUserId;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void filter(String query) {
              final lower = query.toLowerCase();
              setModalState(() {
                filtered =
                    users
                        .where(
                          (u) =>
                              (u['name'] ?? '').toLowerCase().contains(lower) ||
                              (u['email'] ?? '').toLowerCase().contains(lower),
                        )
                        .toList();
              });
            }

            return AlertDialog(
              title: const Text("Send Notification"),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: "Enter your message...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Icon(Icons.group, color: darkGreen),
                        SizedBox(width: 8),
                        Text("Choose a recipient or send to all"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: "Search user...",
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: filter,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, index) {
                          final user = filtered[index];
                          final isSelected = selectedUserId == user['_id'];
                          return ListTile(
                            title: Text(user['name'] ?? ''),
                            subtitle: Text(user['email'] ?? ''),
                            leading: CircleAvatar(
                              backgroundImage: _getImage(user['avatar']),
                            ),
                            trailing:
                                isSelected
                                    ? const Icon(
                                      Icons.check_circle,
                                      color: darkGreen,
                                    )
                                    : null,
                            selected: isSelected,
                            selectedTileColor: Colors.green[50],
                            onTap: () {
                              setModalState(() {
                                selectedUserId =
                                    selectedUserId == user['_id']
                                        ? null
                                        : user['_id'];
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: maroon)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final message = _messageController.text.trim();
                    if (message.isEmpty) return;

                    Navigator.pop(context); // close first

                    if (selectedUserId != null) {
                      // Send to selected user only
                      await http.post(
                        Uri.parse('$baseUrl/api/notifications'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'recipientId': selectedUserId,
                          'recipientModel': 'User',
                          'senderModel': 'Admin',
                          'senderId': '6823bb9b57548e1f37f72cc3',
                          'type': 'Alerts',
                          'message': message,
                        }),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✅ Notification sent")),
                      );
                    } else {
                      // Send to all users
                      for (var user in users) {
                        await http.post(
                          Uri.parse('$baseUrl/api/notifications'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'recipientId': user['_id'],
                            'recipientModel': 'User',
                            'senderModel': 'Admin',
                            'senderId': '6823bb9b57548e1f37f72cc3',
                            'type': 'Alerts',
                            'message': message,
                          }),
                        );
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✅ Sent to all users")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: darkGreen),
                  child: const Text(
                    "Send",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
                onPressed: () async {
                  final message = _messageController.text.trim();
                  if (message.isEmpty) return;

                  final recipientId = selectedUser?['_id'];
                  if (recipientId == null) return;

                  final notification = {
                    'recipientId': recipientId,
                    'recipientModel': 'User',
                    'senderModel': 'Admin',
                    'senderId': '6823bb9b57548e1f37f72cc3',
                    'type': 'Alerts',
                    'message': message,
                  };

                  final res = await http.post(
                    Uri.parse('$baseUrl/api/notifications'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode(notification),
                  );

                  Navigator.pop(context); // close the dialog

                  if (res.statusCode == 200 || res.statusCode == 201) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("✅ Notification sent")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("❌ Failed to send notification"),
                      ),
                    );
                  }
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
      backgroundColor: CupertinoColors.lightBackgroundGray,
      body: Row(
        children: [
          // 🔍 User List + Search
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
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
                      const SizedBox(width: 10),
                      IconButton(
                        tooltip: 'Send Notification',
                        icon: const Icon(Icons.notifications_active_outlined),
                        onPressed: () => _showGlobalNotificationModal(context),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          padding: const EdgeInsets.all(12),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
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
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: _getImage(user['avatar']),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color:
                                          onlineUsers.contains(user['_id'])
                                              ? Colors.green
                                              : Colors.grey,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                    ? AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.person_outline,
                              size: 72,
                              color: darkGreen,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No User Selected',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: darkGreen,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please select a user from the left panel\nto view their profile and recipes.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
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
