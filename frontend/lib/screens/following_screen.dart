import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/colors.dart';
import 'package:frontend/screens/userprofile-screen.dart';

class FollowingScreen extends StatefulWidget {
  final String userId;
  const FollowingScreen({super.key, required this.userId});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  List<dynamic> followingUsers = [];

  @override
  void initState() {
    super.initState();
    fetchFollowing();
  }

  Future<void> fetchFollowing() async {
    final response = await http.get(
      Uri.parse('http://192.168.68.61:3000/api/profile/${widget.userId}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        followingUsers = data['following'] ?? [];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch following list')),
      );
    }
  }

  ImageProvider _getAvatar(dynamic image) {
    if (image == null || image is! String || image.isEmpty) {
      return const AssetImage('assets/placeholder.png');
    }

    try {
      if (image.startsWith('http')) {
        return NetworkImage(image);
      }
      if (image.startsWith('data:image')) {
        return MemoryImage(base64Decode(image.split(',').last));
      }
      if (image.startsWith('/9j') || image.length > 100) {
        return MemoryImage(base64Decode(image));
      }
      return NetworkImage('http://192.168.68.61:3000/images/$image');
    } catch (e) {
      return const AssetImage('assets/placeholder.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body:
          followingUsers.isEmpty
              ? const Center(child: Text('You are not following anyone.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: followingUsers.length,
                itemBuilder: (_, index) {
                  final user = followingUsers[index];

                  ImageProvider avatarImage;
                  try {
                    avatarImage = _getAvatar(user['avatar']);
                  } catch (e) {
                    avatarImage = const AssetImage('assets/placeholder.png');
                  }

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(backgroundImage: avatarImage),
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
