import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/colors.dart';

class ChatsScreen extends StatefulWidget {
  final String userId;
  final String? initialChatUserId;

  const ChatsScreen({super.key, required this.userId, this.initialChatUserId});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final String baseUrl = 'http://192.168.68.61:3000';
  List<dynamic> chatUsers = [];
  late IO.Socket socket;
  String? currentOpenChatUserId;
  List<dynamic> messages = [];
  bool socketInitialized = false;
  final ImagePicker picker = ImagePicker();
  Set<String> onlineUserIds = {}; // ✅ Add this line
  final ScrollController _chatScrollController = ScrollController();
  List<dynamic> followedUsers = [];
  TextEditingController _searchController = TextEditingController();
  List<dynamic> filteredChatUsers = [];

  @override
  void initState() {
    super.initState();
    initSocket();
    fetchChatUsers().then((_) {
      if (widget.initialChatUserId != null) {
        final chatUser = chatUsers.firstWhere(
          (u) => u['_id'] == widget.initialChatUserId,
          orElse: () => null,
        );
        if (chatUser != null) _openChatModal(chatUser);
      }
    });
    fetchFollowingUsers(); // 👈 add this
  }

  void initSocket() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.onConnect((_) {
      socket.emit('join', widget.userId);
    });

    if (!socketInitialized) {
      socket.on('receive_message', (data) {
        if (data['senderId']['_id'] == currentOpenChatUserId) {
          setState(() => messages.add(data));
          markAsRead(currentOpenChatUserId!);
        }
        fetchChatUsers();
      });

      socket.on('userOnlineStatus', (data) {
        final String id = data['userId'];
        final bool isOnline = data['online'];

        setState(() {
          if (isOnline) {
            onlineUserIds.add(id);
          } else {
            onlineUserIds.remove(id);
          }
        });
      });

      socketInitialized = true;
    }
  }

  Future<void> fetchChatUsers() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/chats/users/${widget.userId}'),
    );
    if (res.statusCode == 200) {
      setState(() {
        chatUsers = json.decode(res.body);
        filteredChatUsers = chatUsers; // ← initially show all
      });
    }
  }

  void _filterChats(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredChatUsers = chatUsers;
      } else {
        filteredChatUsers =
            chatUsers.where((user) {
              final name = (user['name'] ?? '').toString().toLowerCase();
              return name.contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  Future<void> fetchFollowingUsers() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/users/${widget.userId}/following'),
    );
    if (res.statusCode == 200) {
      setState(() {
        followedUsers = jsonDecode(res.body);
      });
    }
  }

  Future<void> markAsRead(String senderId) async {
    await http.post(
      Uri.parse('$baseUrl/api/chats/markAsRead'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'senderId': senderId, 'receiverId': widget.userId}),
    );
    fetchChatUsers();
  }

  void _openChatModal(Map<String, dynamic> user) async {
    final recipientId = user['_id'];
    currentOpenChatUserId = recipientId;
    Uint8List? selectedImageBytes;
    final currentUserResponse = await http.get(
      Uri.parse('$baseUrl/api/profile/${widget.userId}'),
    );
    final currentUserData = json.decode(currentUserResponse.body);

    final res = await http.get(
      Uri.parse('$baseUrl/api/chats/${widget.userId}/$recipientId'),
    );
    messages = res.statusCode == 200 ? json.decode(res.body) : [];

    // 👇 Scroll to bottom after messages load
    Future.delayed(Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.jumpTo(
          _chatScrollController.position.maxScrollExtent,
        );
      }
    });

    await markAsRead(recipientId);

    final TextEditingController _controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => StatefulBuilder(
            builder: (context, setModalState) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.85,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (_, scrollController) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                      top: 16,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Chat with ${user['name']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            controller:
                                _chatScrollController, // ✅ use the controller here
                            itemCount: messages.length,
                            itemBuilder: (_, index) {
                              final msg = messages[index];
                              final isMe =
                                  msg['senderId']['_id'] == widget.userId;
                              final time = DateTime.tryParse(
                                msg['timestamp'] ?? '',
                              );
                              final formattedTime =
                                  time != null
                                      ? '${time.hour}:${time.minute.toString().padLeft(2, '0')}'
                                      : '';

                              final DateTime? currentDate = DateTime.tryParse(
                                msg['timestamp'] ?? '',
                              );
                              final DateTime? previousDate =
                                  index > 0
                                      ? DateTime.tryParse(
                                        messages[index - 1]['timestamp'] ?? '',
                                      )
                                      : null;

                              final bool showDate =
                                  index == 0 ||
                                  (currentDate != null &&
                                      previousDate != null &&
                                      (currentDate.year != previousDate.year ||
                                          currentDate.month !=
                                              previousDate.month ||
                                          currentDate.day != previousDate.day));

                              final dateLabel =
                                  time != null
                                      ? '${time.day}/${time.month}/${time.year}'
                                      : '';

                              return Column(
                                children: [
                                  if (showDate)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          dateLabel,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  Align(
                                    alignment:
                                        isMe
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                    child: Row(
                                      mainAxisAlignment:
                                          isMe
                                              ? MainAxisAlignment.end
                                              : MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (!isMe)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 6,
                                            ),
                                            child: CircleAvatar(
                                              radius: 16,
                                              backgroundImage: _getAvatar(
                                                msg['senderId']['avatar'],
                                              ),
                                            ),
                                          ),
                                        Flexible(
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            constraints: BoxConstraints(
                                              maxWidth:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.65, // 👈 max width 75%
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isMe
                                                      ? green.withOpacity(0.9)
                                                      : Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(2, 2),
                                                ),
                                              ],
                                            ),

                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if ((msg['image'] ?? '')
                                                    .isNotEmpty)
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    child: Image.memory(
                                                      base64Decode(
                                                        msg['image'],
                                                      ),
                                                      width: 180,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                if ((msg['message'] ?? '')
                                                    .isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 6,
                                                        ),
                                                    child: Text(
                                                      msg['message'],
                                                      style: TextStyle(
                                                        color:
                                                            isMe
                                                                ? Colors.white
                                                                : Colors
                                                                    .black87,
                                                        fontSize: 14,
                                                      ),
                                                      softWrap: true,
                                                    ),
                                                  ),
                                                const SizedBox(height: 4),
                                                Align(
                                                  alignment:
                                                      Alignment.bottomRight,
                                                  child: Text(
                                                    formattedTime,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          isMe
                                                              ? Colors.white70
                                                              : Colors
                                                                  .grey[600],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (isMe)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 6,
                                            ),
                                            child: CircleAvatar(
                                              radius: 16,
                                              backgroundImage: _getAvatar(
                                                msg['senderId']['avatar'],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        if (selectedImageBytes != null)
                          Stack(
                            alignment: Alignment.topRight,

                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                height: 140,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: MemoryImage(selectedImageBytes!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),

                                onPressed:
                                    () => setModalState(
                                      () => selectedImageBytes = null,
                                    ),
                              ),
                            ],
                          ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.image, color: green),
                              onPressed: () async {
                                final picked = await picker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (picked != null) {
                                  final bytes = await picked.readAsBytes();
                                  setModalState(
                                    () => selectedImageBytes = bytes,
                                  );
                                }
                              },
                            ),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                decoration: const InputDecoration(
                                  hintText: 'Type a message...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final message = _controller.text.trim();
                                final image =
                                    selectedImageBytes != null
                                        ? base64Encode(selectedImageBytes!)
                                        : '';

                                if (message.isEmpty && image.isEmpty) return;

                                final msgData = {
                                  'senderId': widget.userId,
                                  'receiverId': recipientId,
                                  'message': message,
                                  'image': image,
                                };

                                socket.emit('send_message', msgData);

                                setModalState(() {
                                  messages.add({
                                    'senderId': {
                                      '_id': widget.userId,
                                      'name': currentUserData['name'],
                                      'avatar': currentUserData['avatar'],
                                    },
                                    'message': message,
                                    'image': image,
                                    'timestamp':
                                        DateTime.now().toIso8601String(),
                                  });
                                  _controller.clear();
                                  selectedImageBytes = null;
                                });

                                // 👇 Scroll to bottom after UI updates
                                Future.delayed(Duration(milliseconds: 100), () {
                                  if (_chatScrollController.hasClients) {
                                    _chatScrollController.animateTo(
                                      _chatScrollController
                                          .position
                                          .maxScrollExtent,
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                });
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
              );
            },
          ),
    ).then((_) {
      currentOpenChatUserId = null;
      fetchChatUsers();
    });
  }

  ImageProvider _getAvatar(String? avatar) {
    if (avatar != null && avatar.startsWith('http')) {
      return NetworkImage(avatar);
    } else if (avatar != null && avatar.startsWith('/9j')) {
      return MemoryImage(base64Decode(avatar));
    } else {
      return const AssetImage('assets/placeholder.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Chats"),
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      ),

      body: Column(
        children: [
          // 🔰 FOLLOWING AVATARS SECTION
          if (followedUsers.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 12, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Following",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: followedUsers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final user = followedUsers[index];
                  return GestureDetector(
                    onTap: () => _openChatModal(user),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundImage: _getAvatar(user['avatar']),
                          radius: 28,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 60,
                          child: Text(
                            user['name'].split(' ')[0],
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          // 💬 CHAT LIST SECTION
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterChats,
                    decoration: InputDecoration(
                      hintText: 'Search chats...',
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // 💬 Section title under search
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.message, color: green, size: 20),
                      SizedBox(width: 6),
                      Text(
                        "Messages",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child:
                      filteredChatUsers.isEmpty
                          ? const Center(
                            child: Text(
                              'No chats found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                          : ListView.builder(
                            itemCount: filteredChatUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredChatUsers[index];
                              return ListTile(
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage: _getAvatar(
                                        user['avatar'],
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color:
                                              onlineUserIds.contains(
                                                    user['_id'].toString(),
                                                  )
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
                                title: Text(
                                  user['name'] ?? 'User',
                                  style: TextStyle(
                                    fontWeight:
                                        user['unreadCount'] > 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  user['lastMessage']?.isNotEmpty == true
                                      ? user['lastMessage']
                                      : onlineUserIds.contains(
                                        user['_id'].toString(),
                                      )
                                      ? 'Online'
                                      : 'Offline',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight:
                                        user['unreadCount'] > 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (user['lastTimestamp'] != null)
                                      Text(
                                        _formatTime(user['lastTimestamp']),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    if ((user['unreadCount'] ?? 0) > 0)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${user['unreadCount']}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () => _openChatModal(user),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
