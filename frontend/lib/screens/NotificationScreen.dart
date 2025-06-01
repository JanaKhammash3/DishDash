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

  ImageProvider _resolveAvatar(dynamic avatar) {
    try {
      if (avatar == null) {
        return const AssetImage('assets/profile.png');
      }

      if (avatar is! String) {
        debugPrint(
          '🔴 avatar is not a string: $avatar (${avatar.runtimeType})',
        );
        return const AssetImage('assets/profile.png');
      }

      if (avatar.isEmpty) {
        debugPrint('⚪ avatar is an empty string');
        return const AssetImage('assets/profile.png');
      }

      if (avatar.startsWith('http')) {
        return NetworkImage(avatar);
      }

      final base64Str =
          avatar.startsWith('data:image')
              ? avatar
              : 'data:image/jpeg;base64,$avatar';

      final bytes = base64Decode(base64Str.split(',').last);
      return MemoryImage(bytes);
    } catch (e) {
      debugPrint('❌ Failed to decode avatar: $e');
      return const AssetImage('assets/profile.png');
    }
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

  Widget _buildToggleChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? green : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
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
      case 'purchase':
        return Icons.shopping_cart;
      case 'rating':
        return Icons.star;
      default:
        return Icons.notifications;
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
                child: Column(
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final visibleNotifications = notifications;

                          if (visibleNotifications.isEmpty) {
                            return const Center(
                              child: Text('No notifications for this view.'),
                            );
                          }

                          return ListView.builder(
                            itemCount: visibleNotifications.length,
                            itemBuilder: (context, index) {
                              final n = visibleNotifications[index];
                              final isRead = n['isRead'] ?? false;
                              final type = n['type'] ?? 'Alert';
                              final message = n['message'] ?? '';
                              final timestamp = n['createdAt'] ?? '';
                              final sender = n['senderId'];
                              final avatar =
                                  sender is Map ? sender['avatar'] : null;
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
                                onDismissed:
                                    (_) => deleteNotification(n['_id']),
                                child: ListTile(
                                  tileColor:
                                      isRead
                                          ? Colors.white
                                          : Colors.orange.shade50,
                                  leading: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,

                                        backgroundImage: _resolveAvatar(avatar),
                                      ),
                                      CircleAvatar(
                                        radius: 8,
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          _getIconForType(type),
                                          size: 12,
                                          color: green,
                                        ),
                                      ),
                                    ],
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
                                                n['isRead'] = true;
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
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
