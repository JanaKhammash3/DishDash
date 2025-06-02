import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/colors.dart';
import 'package:http/http.dart' as http;

class StoreNotificationsScreen extends StatefulWidget {
  final String storeId;
  const StoreNotificationsScreen({super.key, required this.storeId});

  @override
  State<StoreNotificationsScreen> createState() =>
      _StoreNotificationsScreenState();
}

class _StoreNotificationsScreenState extends State<StoreNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);

    try {
      final url = Uri.parse(
        'http://192.168.68.61:3000/api/notifications/${widget.storeId}/Store',
      );
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final allNotifications = jsonDecode(res.body);
        allNotifications.sort(
          (a, b) => DateTime.parse(
            b['createdAt'],
          ).compareTo(DateTime.parse(a['createdAt'])),
        );
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(allNotifications);
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> markAsRead(String notificationId, int index) async {
    final res = await http.patch(
      Uri.parse(
        'http://192.168.68.61:3000/api/notifications/read/$notificationId',
      ),
    );
    if (res.statusCode == 200) {
      setState(() {
        _notifications[index]['isRead'] = true;
      });
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final res = await http.delete(
      Uri.parse('http://192.168.68.61:3000/api/notifications/$notificationId'),
    );
    if (res.statusCode == 200) {
      setState(() {
        _notifications.removeWhere((n) => n['_id'] == notificationId);
      });
    }
  }

  ImageProvider _resolveAvatar(String? avatar) {
    if (avatar == null || avatar.isEmpty) {
      return const AssetImage('assets/profile.png');
    }

    if (avatar.startsWith('http')) {
      return NetworkImage(avatar);
    }
    try {
      String base64Str = avatar;
      if (!avatar.startsWith('data:image')) {
        base64Str = 'data:image/jpeg;base64,$avatar';
      }

      final bytes = base64Decode(base64Str.split(',').last);
      return MemoryImage(bytes);
    } catch (e) {
      debugPrint('❌ Failed to decode avatar: $e');
    }

    return const AssetImage('assets/profile.png');
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'purchase':
        return Icons.shopping_cart;
      case 'rating':
        return Icons.star;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final date = DateTime.parse(iso);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Notifications'),
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
                      child:
                          _notifications.isEmpty
                              ? const Center(
                                child: Text('No notifications yet.'),
                              )
                              : ListView.builder(
                                itemCount: _notifications.length,
                                itemBuilder: (context, index) {
                                  final n = _notifications[index];
                                  final isRead = n['isRead'] ?? false;
                                  final type = n['type'] ?? 'notification';
                                  final message = n['message'] ?? '';
                                  final timestamp = n['createdAt'] ?? '';
                                  final sender = n['senderId'];
                                  final name = sender?['name'] ?? 'Someone';
                                  final avatar = sender?['avatar'];

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
                                            backgroundImage: _resolveAvatar(
                                              avatar,
                                            ),
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
                                              text: "$name ",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: message),
                                          ],
                                        ),
                                      ),
                                      subtitle: Text(
                                        _formatTimestamp(timestamp),
                                        style: TextStyle(
                                          color:
                                              isRead
                                                  ? Colors.grey
                                                  : Colors.black54,
                                        ),
                                      ),
                                      trailing:
                                          !isRead
                                              ? IconButton(
                                                icon: const Icon(
                                                  Icons.check_circle,
                                                  color: green,
                                                ),
                                                onPressed: () async {
                                                  await markAsRead(
                                                    n['_id'],
                                                    index,
                                                  );
                                                },
                                              )
                                              : null,
                                    ),
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
