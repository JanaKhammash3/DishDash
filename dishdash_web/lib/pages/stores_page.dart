import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    const baseUrl = 'http://192.168.1.4:3000'; // your backend
    final res = await http.get(Uri.parse('$baseUrl/api/users'));

    if (res.statusCode == 200) {
      setState(() {
        users = jsonDecode(res.body);
      });
    } else {
      print('❌ Failed to load users');
    }
  }

  ImageProvider getAvatarImage(String? avatar) {
    if (avatar == null || avatar.isEmpty) {
      return const AssetImage('assets/default_avatar.png');
    }
    if (avatar.startsWith('http')) {
      return NetworkImage(avatar);
    }
    if (avatar.startsWith('/9j')) {
      return MemoryImage(base64Decode(avatar));
    }
    return NetworkImage('http://192.168.1.4:3000/images/$avatar');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
        backgroundColor: const Color(0xFF304D30),
      ),
      backgroundColor: Colors.grey[100],
      body:
          users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (_, index) {
                  final user = users[index];
                  final name = user['name'] ?? 'Unknown';
                  final email = user['email'] ?? 'N/A';
                  final avatar = user['avatar'];
                  final int followerCount =
                      (user['followers'] as List?)?.length ?? 0;
                  final int recipeCount =
                      (user['recipes'] as List?)?.length ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: getAvatarImage(avatar),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text('Followers: $followerCount'),
                                      backgroundColor: Colors.green[100],
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text('Recipes: $recipeCount'),
                                      backgroundColor: Colors.orange[100],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Optional: confirm delete
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
