import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/colors.dart';
import 'package:frontend/screens/userprofile-screen.dart';

class FollowersScreen extends StatefulWidget {
  final String userId;
  const FollowersScreen({super.key, required this.userId});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  List<dynamic> followers = [];

  @override
  void initState() {
    super.initState();
    fetchFollowers();
  }

  Future<void> fetchFollowers() async {
    final url = Uri.parse(
      'http://192.168.68.60:3000/api/users/followers/${widget.userId}',
    );
    final res = await http.get(url);

    if (res.statusCode == 200) {
      setState(() {
        followers = json.decode(res.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch followers')),
      );
    }
  }

  ImageProvider _getAvatar(String? avatar) {
    if (avatar != null && avatar.startsWith('http')) {
      return NetworkImage(avatar);
    } else if (avatar != null && avatar.startsWith('/9j')) {
      return MemoryImage(base64Decode(avatar));
    } else if (avatar != null && avatar.isNotEmpty) {
      return NetworkImage('http://192.168.68.60:3000/images/$avatar');
    } else {
      return const AssetImage('assets/placeholder.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Followers'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body:
          followers.isEmpty
              ? const Center(child: Text('You have no followers yet.'))
              : ListView.builder(
                itemCount: followers.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (_, index) {
                  final user = followers[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: _getAvatar(user['avatar']),
                      ),
                      title: Text(user['name'] ?? 'User'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => UserProfileScreen(userId: user['_id']),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Profile'),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
