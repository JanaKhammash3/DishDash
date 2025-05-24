import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/colors.dart';

class ChatsScreen extends StatefulWidget {
  final String userId;
  const ChatsScreen({super.key, required this.userId});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final String baseUrl = 'http://192.168.68.60:3000';
  List<dynamic> chatUsers = [];
  late IO.Socket socket;
  String? currentOpenChatUserId;
  List<dynamic> messages = [];
  bool socketInitialized = false;

  @override
  void initState() {
    super.initState();
    initSocket();
    fetchChatUsers();
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

    final res = await http.get(
      Uri.parse('$baseUrl/api/chats/${widget.userId}/$recipientId'),
    );
    messages = res.statusCode == 200 ? json.decode(res.body) : [];

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
                    Text(
                      'Chat with ${user['name']}',
                      style: const TextStyle(
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
                          final isMe = msg['senderId']['_id'] == widget.userId;
                          final time = DateTime.tryParse(
                            msg['timestamp'] ?? '',
                          );
                          final formattedTime =
                              time != null
                                  ? '${time.hour}:${time.minute.toString().padLeft(2, '0')}'
                                  : '';

                          return Row(
                            mainAxisAlignment:
                                isMe
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                            children: [
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg['senderId']['name'],
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
                            if (message.isEmpty) return;

                            final msgData = {
                              'senderId': widget.userId,
                              'receiverId': recipientId,
                              'message': message,
                            };

                            socket.emit('send_message', msgData);
                            setModalState(
                              () => messages.add({
                                'senderId': {
                                  '_id': widget.userId,
                                  'name': 'You',
                                },
                                'message': message,
                                'timestamp': DateTime.now().toIso8601String(),
                              }),
                            );
                            _controller.clear();
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
      ),
      body:
          chatUsers.isEmpty
              ? const Center(
                child: Text(
                  'No chats yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
              : ListView.builder(
                itemCount: chatUsers.length,
                itemBuilder: (context, index) {
                  final user = chatUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: _getAvatar(user['avatar']),
                    ),
                    title: Text(
                      user['name'] ?? 'User',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight:
                            user['unreadCount'] > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      user['lastMessage'] ?? '',
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
    );
  }
}

String _formatTime(String timestamp) {
  try {
    final dt = DateTime.parse(timestamp).toLocal();
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return '';
  }
}
