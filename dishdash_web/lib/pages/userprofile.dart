import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:image/image.dart' as img;

class WebProfileScreen extends StatefulWidget {
  final String userId;
  const WebProfileScreen({super.key, required this.userId});

  @override
  State<WebProfileScreen> createState() => _WebProfileScreenState();
}

class _WebProfileScreenState extends State<WebProfileScreen> {
  String name = '';
  String email = '';
  String? avatarBase64;
  int followerCount = 0;
  int followingCount = 0;
  int recipeCount = 0;
  LatLng? selectedLocation;
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    fetchRecipeCount();
  }

  void _onEdit() {
    // TODO: Implement edit profile modal
  }

  void _onUpdateSurvey() {
    // TODO: Navigate to update survey screen
  }

  void _onMyChallenges() {
    // TODO: Navigate to my challenges screen
  }
  Future<void> _pickAndUploadImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final rawBytes = await picked.readAsBytes();

      // Decode the image
      final originalImage = img.decodeImage(rawBytes);
      if (originalImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not process image')),
        );
        return;
      }

      // Resize and compress
      final resized = img.copyResize(
        originalImage,
        width: 300,
      ); // Resize to 300px width
      final compressedBytes = img.encodeJpg(
        resized,
        quality: 70,
      ); // JPEG quality 70%

      final base64String = base64Encode(compressedBytes);

      final url = Uri.parse(
        'http://192.168.1.4:3000/api/profile/${widget.userId}/avatar',
      );

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'avatar': base64String}),
      );

      if (response.statusCode == 200) {
        await fetchUserProfile(); // Force refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload avatar')),
        );
      }
    }
  }

  Future<void> fetchRecipeCount() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/recipes/count/${widget.userId}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          recipeCount = data['count'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching recipe count: $e');
    }
  }

  Future<void> fetchUserProfile() async {
    final url = Uri.parse(
      'http://192.168.1.4:3000/api/profile/${widget.userId}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          name = data['name'];
          email = data['email'];
          if (data['location'] != null) {
            selectedLocation = LatLng(
              data['location']['latitude'],
              data['location']['longitude'],
            );
          }
          avatarBase64 = data['avatar'];
          followerCount =
              data['followers'] is List
                  ? data['followers'].length
                  : data['followers'] ?? 0;

          followingCount =
              data['following'] is List
                  ? data['following'].length
                  : data['following'] ?? 0;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to load profile')));
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAvatar = avatarBase64 != null && avatarBase64!.isNotEmpty;
    final avatarImage =
        hasAvatar
            ? MemoryImage(base64Decode(avatarBase64!)) as ImageProvider
            : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Panel: Avatar and Stats
            Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: avatarImage,
                        child:
                            !hasAvatar
                                ? const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Colors.white70,
                                )
                                : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: _pickAndUploadImage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  _buildStatTile('Followers', followerCount, Icons.group),
                  _buildStatTile('Following', followingCount, Icons.group_add),
                  _buildStatTile('Recipes', recipeCount, Icons.restaurant_menu),
                ],
              ),
            ),

            const SizedBox(width: 32),

            // Right Panel: Actions
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings & Actions',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _buildActionBox(
                    icon: Icons.edit,
                    title: 'Edit Profile',
                    description: 'Update your profile details',
                    onTap: _onEdit,
                  ),
                  const SizedBox(height: 16),
                  _buildActionBox(
                    icon: Icons.flag,
                    title: 'My Challenges',
                    description: 'View and submit your challenge progress',
                    onTap: _onMyChallenges,
                  ),
                  const SizedBox(height: 16),
                  _buildActionBox(
                    icon: Icons.assignment,
                    title: 'Update Survey',
                    description: 'Edit your dietary and lifestyle preferences',
                    onTap: _onUpdateSurvey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, int value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: const Color.fromARGB(255, 89, 147, 89),
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBox({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Color.fromARGB(255, 89, 147, 89)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
