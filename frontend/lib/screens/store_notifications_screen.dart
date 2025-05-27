import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/colors.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class StoreNotificationsScreen extends StatefulWidget {
  final String storeId;
  const StoreNotificationsScreen({super.key, required this.storeId});

  @override
  State<StoreNotificationsScreen> createState() =>
      _StoreNotificationsScreenState();
}

class _StoreNotificationsScreenState extends State<StoreNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  late IO.Socket socket;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    setupSocket();
  }

  void setupSocket() {
    socket = IO.io('http://192.168.68.61:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.emit('join_store', widget.storeId);

    socket.on('store_notification', (data) {
      print('📨 Received real-time store notification:\n$data');
      setState(() {
        _notifications.insert(0, Map<String, dynamic>.from(data));
      });
    });
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);

    try {
      final purchaseUrl = Uri.parse(
        'http://192.168.68.61:3000/api/stores/${widget.storeId}/notifications/purchases',
      );
      final ratingUrl = Uri.parse(
        'http://192.168.68.61:3000/api/stores/${widget.storeId}/notifications/ratings',
      );

      final responses = await Future.wait([
        http.get(purchaseUrl),
        http.get(ratingUrl),
      ]);

      final allNotifications = [
        ...jsonDecode(responses[0].body),
        ...jsonDecode(responses[1].body),
      ];

      allNotifications.sort(
        (a, b) => DateTime.parse(
          b['createdAt'],
        ).compareTo(DateTime.parse(a['createdAt'])),
      );

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(allNotifications);
      });
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  String _formatTime(String? iso) {
    try {
      if (iso == null || iso.isEmpty) return '';
      final date = DateTime.parse(iso);
      return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  ImageProvider _getAvatarImage(String? base64Avatar) {
    if (base64Avatar != null &&
        base64Avatar.isNotEmpty &&
        base64Avatar.contains(',')) {
      try {
        return MemoryImage(base64Decode(base64Avatar.split(',').last));
      } catch (_) {}
    }
    return const AssetImage('assets/profile.png');
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
              : _notifications.isEmpty
              ? const Center(child: Text('No notifications yet.'))
              : RefreshIndicator(
                onRefresh: fetchNotifications,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 12),
                  itemCount: _notifications.length,
                  itemBuilder: (_, index) {
                    final n = _notifications[index];
                    final sender = n['senderId'];
                    String? avatar = '';
                    String name = 'Someone';

                    if (sender != null && sender is Map<String, dynamic>) {
                      avatar = sender['avatar']?.toString();
                      name = sender['name']?.toString() ?? 'Someone';
                    }

                    final imageProvider = _getAvatarImage(avatar);

                    final type = n['type'];
                    IconData icon;
                    switch (type) {
                      case 'purchase':
                        icon = Icons.shopping_cart;
                        break;
                      case 'rating':
                        icon = Icons.star;
                        break;
                      default:
                        icon = Icons.notifications;
                    }

                    return ListTile(
                      leading: CircleAvatar(backgroundImage: imageProvider),
                      title: Text(n['message'] ?? 'No message'),
                      subtitle: Text('$name • ${_formatTime(n['createdAt'])}'),
                      trailing: Icon(icon, color: green),
                    );
                  },
                ),
              ),
    );
  }
}
