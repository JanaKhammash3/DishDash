import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/screens/ChatsScreen.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/colors.dart';

class NotificationScreen extends StatefulWidget {
  final String userId;
  const NotificationScreen({super.key, required this.userId});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);
    final res = await http.get(
      Uri.parse('http://192.168.1.4:3000/api/notifications/${widget.userId}'),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        notifications = data;
        isLoading = false;
      });
    } else {
      print('❌ Failed to fetch notifications');
      setState(() => isLoading = false);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await http.patch(
      Uri.parse(
        'http://192.168.1.4:3000/api/notifications/read/$notificationId',
      ),
    );
  }

  Future<void> deleteNotification(String notificationId) async {
    final res = await http.delete(
      Uri.parse('http://192.168.1.4:3000/api/notifications/$notificationId'),
    );
    if (res.statusCode == 200) {
      setState(() {
        notifications.removeWhere((n) => n['_id'] == notificationId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: fetchNotifications,
                child:
                    notifications.isEmpty
                        ? const Center(child: Text('No notifications'))
                        : ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final n =
                                notifications[index]; // 👈 This is the correct variable
                            final isRead = n['isRead'] ?? false;
                            final type = n['type'] ?? 'Alert';
                            final message = n['message'] ?? '';
                            final timestamp = n['createdAt'] ?? '';

                            return Dismissible(
                              key: Key(n['_id']),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (_) => deleteNotification(n['_id']),
                              child: ListTile(
                                tileColor:
                                    isRead
                                        ? Colors.white
                                        : Colors.orange.shade50,
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundImage:
                                      n['senderId']?['avatar'] != null
                                          ? MemoryImage(
                                            base64Decode(
                                              n['senderId']['avatar'],
                                            ),
                                          )
                                          : const AssetImage(
                                                'assets/profile.png',
                                              )
                                              as ImageProvider,
                                ),
                                title: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            "${n['senderId']?['name'] ?? ' '} ",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(text: message),
                                    ],
                                  ),
                                ),
                                subtitle: Text(_formatTimestamp(timestamp)),
                                trailing:
                                    !isRead
                                        ? IconButton(
                                          icon: const Icon(
                                            Icons.check_circle,
                                            color: green,
                                          ),
                                          onPressed: () async {
                                            await markAsRead(n['_id']);
                                            setState(() {
                                              notifications[index] = {
                                                ...notifications[index],
                                                'isRead': true,
                                              };
                                            });
                                          },
                                        )
                                        : null,
                                onTap: () {
                                  if (type == 'message') {
                                    Navigator.pushNamed(
                                      context,
                                      '/chats',
                                      arguments: {
                                        'userId': widget.userId,
                                        'initialChatUserId':
                                            n['senderId']['_id'],
                                      },
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
              ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'follow':
        return Icons.person_add;
      case 'message':
        return Icons.chat;
      case 'challenge':
        return Icons.flag;
      case 'Alerts':
        return Icons.notifications_active;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
